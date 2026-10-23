#ifndef RUNNER_WINDOW_TITLE_CHANNEL_H_
#define RUNNER_WINDOW_TITLE_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

// Lets Dart set the top-level window's title bar text. Stable Flutter does not
// apply titles to Windows desktop windows itself.
//
// Channel `soar_score/window`, method `setTitle` with a String argument.
class WindowTitleChannel {
 public:
  static constexpr const char kChannelName[] = "soar_score/window";

  WindowTitleChannel(flutter::BinaryMessenger* messenger, HWND window);

 private:
  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_WINDOW_TITLE_CHANNEL_H_
