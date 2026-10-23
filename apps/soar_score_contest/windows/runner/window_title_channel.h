#ifndef RUNNER_WINDOW_TITLE_CHANNEL_H_
#define RUNNER_WINDOW_TITLE_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <functional>
#include <memory>

// Lets Dart set the top-level window's title bar text. Stable Flutter does not
// apply titles to Windows desktop windows itself.
//
// Channel `soar_score/window`:
//  - `setTitle` (Dart to runner) with a String argument.
//  - `confirmClose` (runner to Dart) answers a bool: whether the window may
//    close, so Dart can warn about unsaved edits first.
class WindowTitleChannel {
 public:
  static constexpr const char kChannelName[] = "soar_score/window";

  WindowTitleChannel(flutter::BinaryMessenger* messenger, HWND window);

  // Asks Dart whether the window may close and reports the answer to
  // |on_answer|. Dart that cannot answer (no handler, an error) allows the
  // close so the window is never stuck open. Returns false without asking when
  // an earlier request is still waiting for its answer.
  bool RequestClose(std::function<void(bool allow)> on_answer);

 private:
  HWND window_;
  bool close_pending_ = false;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_WINDOW_TITLE_CHANNEL_H_
