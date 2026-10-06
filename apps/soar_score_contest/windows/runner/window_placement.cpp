#include "window_placement.h"

namespace {

// Per-user key for the window placement, under the company and product names
// from Runner.rc.
constexpr const wchar_t kPlacementRegKey[] =
    L"Software\\Laminar Stack\\RC Soar Score";
constexpr const wchar_t kPlacementRegValue[] = L"WindowPlacement";

}  // namespace

std::optional<WINDOWPLACEMENT> LoadWindowPlacement() {
  WINDOWPLACEMENT placement{};
  DWORD size = sizeof(placement);
  LSTATUS result =
      RegGetValue(HKEY_CURRENT_USER, kPlacementRegKey, kPlacementRegValue,
                  RRF_RT_REG_BINARY, nullptr, &placement, &size);
  if (result != ERROR_SUCCESS || size != sizeof(placement) ||
      placement.length != sizeof(placement)) {
    return std::nullopt;
  }

  // The monitor the window was on may have been unplugged or rearranged since;
  // fall back to the default placement rather than open off screen.
  if (MonitorFromRect(&placement.rcNormalPosition, MONITOR_DEFAULTTONULL) ==
      nullptr) {
    return std::nullopt;
  }

  if (placement.showCmd != SW_SHOWMAXIMIZED) {
    placement.showCmd = SW_SHOWNORMAL;
  }
  return placement;
}

void SaveWindowPlacement(HWND window) {
  WINDOWPLACEMENT placement{};
  placement.length = sizeof(placement);
  if (!GetWindowPlacement(window, &placement)) {
    return;
  }

  if (placement.showCmd == SW_SHOWMINIMIZED) {
    placement.showCmd = (placement.flags & WPF_RESTORETOMAXIMIZED)
                            ? SW_SHOWMAXIMIZED
                            : SW_SHOWNORMAL;
  } else if (placement.showCmd != SW_SHOWMAXIMIZED) {
    placement.showCmd = SW_SHOWNORMAL;
  }

  HKEY key;
  if (RegCreateKeyEx(HKEY_CURRENT_USER, kPlacementRegKey, 0, nullptr,
                     REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &key,
                     nullptr) != ERROR_SUCCESS) {
    return;
  }
  RegSetValueEx(key, kPlacementRegValue, 0, REG_BINARY,
                reinterpret_cast<const BYTE*>(&placement), sizeof(placement));
  RegCloseKey(key);
}
