#include "window_title_channel.h"

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <string>
#include <variant>

namespace {

// Converts a UTF-8 string from Dart to the UTF-16 the Win32 API expects.
std::wstring Utf16FromUtf8(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
                                   static_cast<int>(utf8.size()), nullptr, 0);
  if (length <= 0) {
    return std::wstring();
  }
  std::wstring utf16(length, L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
                      static_cast<int>(utf8.size()), utf16.data(), length);
  return utf16;
}

}  // namespace

WindowTitleChannel::WindowTitleChannel(flutter::BinaryMessenger* messenger,
                                       HWND window)
    : window_(window),
      channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, kChannelName,
          &flutter::StandardMethodCodec::GetInstance())) {
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != "setTitle") {
          result->NotImplemented();
          return;
        }
        const auto* title = std::get_if<std::string>(call.arguments());
        if (title == nullptr) {
          result->Error("bad-arguments", "setTitle expects a String title.");
          return;
        }
        SetWindowText(window_, Utf16FromUtf8(*title).c_str());
        result->Success();
      });
}

bool WindowTitleChannel::RequestClose(std::function<void(bool allow)> on_answer) {
  if (close_pending_) {
    return false;
  }
  close_pending_ = true;
  auto finish = [this, on_answer](bool allow) {
    close_pending_ = false;
    on_answer(allow);
  };
  channel_->InvokeMethod(
      "confirmClose", nullptr,
      std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
          [finish](const flutter::EncodableValue* value) {
            const bool* allow = value ? std::get_if<bool>(value) : nullptr;
            finish(allow == nullptr || *allow);
          },
          [finish](const std::string&, const std::string&,
                   const flutter::EncodableValue*) { finish(true); },
          [finish]() { finish(true); }));
  return true;
}
