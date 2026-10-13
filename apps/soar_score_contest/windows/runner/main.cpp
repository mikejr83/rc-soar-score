#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <sddl.h>
#include <string>
#include <vector>
#include <thread>

#include "flutter_window.h"
#include "utils.h"

// Reader-writer lock the auth0_flutter plugin shares for PLUGIN_STARTUP_URL.
#include "../flutter/ephemeral/.plugin_symlinks/auth0_flutter/windows/plugin_startup_url_lock.h"

// Sign-in with Auth0 returns to the app through the custom URL scheme
// com.soarscore.contest://callback, which Windows hands to a new process as
// argv[1]. The code below is adapted from auth0_flutter's example runner:
// the first instance owns a mutex and a current-user-only named pipe, and a
// second launch forwards its callback URI there and exits. The mutex and pipe
// names carry the scheme so they cannot collide with another app's.
const wchar_t* kSingleInstanceMutex = L"Local\\com.soarscore.contest_auth0_singleton";
const wchar_t* kRedirectPipeName    = L"\\\\.\\pipe\\com.soarscore.contest_auth0_pipe";

// Only URLs beginning with this prefix are accepted from the pipe.
// Must match Auth0Config.windowsScheme in lib/auth/auth_config.dart.
const wchar_t* kCallbackPrefix = L"com.soarscore.contest://callback";

// Builds a SECURITY_DESCRIPTOR that grants pipe read/write access only to the
// current user's SID, preventing other users or processes from connecting.
// Returns NULL on failure. Caller must LocalFree() the returned pointer.
static PSECURITY_DESCRIPTOR BuildCurrentUserSD() {
  HANDLE hToken = NULL;
  if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken))
    return NULL;

  // Query required buffer size, then fetch the token user info.
  DWORD cbTokenUser = 0;
  GetTokenInformation(hToken, TokenUser, NULL, 0, &cbTokenUser);
  if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
    CloseHandle(hToken);
    return NULL;
  }

  std::vector<BYTE> buf(cbTokenUser);
  auto* pTokenUser = reinterpret_cast<PTOKEN_USER>(buf.data());
  if (!GetTokenInformation(hToken, TokenUser, pTokenUser, cbTokenUser, &cbTokenUser)) {
    CloseHandle(hToken);
    return NULL;
  }
  CloseHandle(hToken);

  // Convert the SID to a string so we can embed it in an SDDL expression.
  LPWSTR pszSid = NULL;
  if (!ConvertSidToStringSidW(pTokenUser->User.Sid, &pszSid))
    return NULL;

  // D:(A;;GRGW;;;S-1-5-…) — grant generic read+write to current user only.
  std::wstring sddl = L"D:(A;;GRGW;;;";
  sddl += pszSid;
  sddl += L")";
  LocalFree(pszSid);

  PSECURITY_DESCRIPTOR pSD = NULL;
  ConvertStringSecurityDescriptorToSecurityDescriptorW(
      sddl.c_str(), SDDL_REVISION_1, &pSD, NULL);
  return pSD;  // caller must LocalFree()
}

// Forward URI to first instance (pipe client).
// Waits up to 2 seconds for the pipe server to become available — the first
// instance's detached thread may not have called CreateNamedPipeW yet.
void ForwardToFirstInstance(const wchar_t* uri) {
  // Wait for the pipe to exist (handles the race between the first instance's
  // StartPipeServer thread and this second-instance launch).
  if (!WaitNamedPipeW(kRedirectPipeName, 2000)) {
    return;  // pipe never appeared — nothing we can do
  }

  HANDLE hPipe = CreateFileW(
      kRedirectPipeName, GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);

  // Retry once on PIPE_BUSY (another client just connected).
  if (hPipe == INVALID_HANDLE_VALUE && GetLastError() == ERROR_PIPE_BUSY) {
    if (WaitNamedPipeW(kRedirectPipeName, 2000)) {
      hPipe = CreateFileW(
          kRedirectPipeName, GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
    }
  }

  if (hPipe != INVALID_HANDLE_VALUE) {
    DWORD written = 0;
    DWORD len = static_cast<DWORD>((wcslen(uri) + 1) * sizeof(wchar_t));
    if (!WriteFile(hPipe, uri, len, &written, NULL) || written != len) {
      // Partial or failed write — the first instance won't get a valid URI.
      // Nothing actionable here; the login will time out.
    }
    CloseHandle(hPipe);
  }
}

// Bring first instance window to foreground
void BringExistingWindowToFront() {
  HWND hwnd = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", NULL);
  if (hwnd) {
    ShowWindow(hwnd, SW_RESTORE);
    SetForegroundWindow(hwnd);
  }
}

// Pipe server (runs in first instance)
void StartPipeServer() {
  std::thread([] {
    while (true) {
      // Restrict the pipe to the current user only.
      // A NULL security descriptor would allow any process on the system to
      // connect, which would let an attacker inject an arbitrary startup URL.
      PSECURITY_DESCRIPTOR pSD = BuildCurrentUserSD();
      if (!pSD) {
        // Cannot create a restricted descriptor; refuse to expose an
        // unrestricted pipe rather than fall back to the default DACL.
        return;
      }

      SECURITY_ATTRIBUTES sa = {};
      sa.nLength              = sizeof(sa);
      sa.lpSecurityDescriptor = pSD;
      sa.bInheritHandle       = FALSE;

      // FILE_FLAG_FIRST_PIPE_INSTANCE causes this call to fail if a pipe with
      // this name already exists, preventing an attacker from squatting the
      // name before the app starts and having later client connections
      // round-robin onto their instance instead of ours.
      HANDLE hPipe = CreateNamedPipeW(
          kRedirectPipeName,
          PIPE_ACCESS_INBOUND | FILE_FLAG_FIRST_PIPE_INSTANCE,
          PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
          1, 0, 0, 0, &sa);

      // Security descriptor is no longer needed once the pipe is created.
      LocalFree(pSD);

      if (hPipe == INVALID_HANDLE_VALUE) {
        // ERROR_ACCESS_DENIED here means a pipe instance with this name
        // already existed (e.g. squatted before this app started, or a
        // stale instance from another process) — refuse to run the
        // redirect-forwarding thread rather than risk operating alongside
        // an attacker-controlled instance.
        return;
      }

      // ConnectNamedPipe returns FALSE with ERROR_PIPE_CONNECTED when a
      // client connected between CreateNamedPipeW and this call — that is
      // a valid connection, not an error.
      BOOL connected = ConnectNamedPipe(hPipe, NULL);
      if (connected || GetLastError() == ERROR_PIPE_CONNECTED) {
        wchar_t buffer[2048];
        DWORD read = 0;
        // Reserve one wchar_t for the null terminator so buffer[read/sizeof(wchar_t)]
        // is always within bounds (fixes the off-by-one overflow).
        BOOL readOk = ReadFile(hPipe, buffer, sizeof(buffer) - sizeof(wchar_t), &read, NULL);

        if (!readOk && GetLastError() == ERROR_MORE_DATA) {
          // Message exceeds buffer — reject it rather than processing a truncated URL.
          // Auth0 callback URLs are typically short; an oversized message is suspicious.
        } else if (readOk) {
          buffer[read / sizeof(wchar_t)] = L'\0';

          // Only accept URLs that begin with the expected com.soarscore.contest:// prefix.
          // This is a defence-in-depth guard: even if an attacker managed to
          // connect to the pipe despite the restricted DACL, they cannot
          // overwrite PLUGIN_STARTUP_URL with an arbitrary string.
          size_t prefixLen = wcslen(kCallbackPrefix);
          if (wcslen(buffer) >= prefixLen &&
              wcsncmp(buffer, kCallbackPrefix, prefixLen) == 0) {
            // Synchronize with polling threads (oauth_helpers.cpp) to prevent TOCTOU race.
            // Acquire write lock (exclusive access) so polling threads are blocked while
            // we write to PLUGIN_STARTUP_URL. Polling threads acquire read locks, which
            // allows multiple readers to proceed simultaneously, but blocks when writer holds
            // the lock (true reader-writer lock semantics).
            auth0_flutter::WriteLockGuard writeLock(auth0_flutter::GetPluginUrlRwLock());
            if (writeLock.IsValid()) {
              SetEnvironmentVariableW(L"PLUGIN_STARTUP_URL", buffer);
            }
            // WriteLockGuard destructor releases the write lock automatically
            BringExistingWindowToFront();
          }
        }
      }
      DisconnectNamedPipe(hPipe);
      CloseHandle(hPipe);
    }
  }).detach();
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // The protocol-scheme URI, if Windows launched this process for a callback.
  std::wstring startupUri;
  int argc = 0;
  LPWSTR *argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv && argc > 1) {
    startupUri = argv[1];
  }
  if (argv) {
    ::LocalFree(argv);
  }

  // Single instance: a second launch (usually the callback) hands its URI to
  // the running window and exits.
  HANDLE hMutex = ::CreateMutexW(NULL, TRUE, kSingleInstanceMutex);
  if (hMutex && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    BringExistingWindowToFront();
    if (!startupUri.empty()) {
      ForwardToFirstInstance(startupUri.c_str());
    }
    ::CloseHandle(hMutex);
    return 0;
  }

  // First instance: accept a startup URI only if it is our callback.
  size_t prefixLen = wcslen(kCallbackPrefix);
  bool isOurCallback = startupUri.size() >= prefixLen &&
                       startupUri.compare(0, prefixLen, kCallbackPrefix) == 0;
  ::SetEnvironmentVariableW(L"PLUGIN_STARTUP_URL",
                            isOurCallback ? startupUri.c_str() : L"");
  StartPipeServer();

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  window.SetRememberPlacement(true);
  if (!window.Create(L"RC Soar Score", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
