#ifndef RUNNER_WINDOW_PLACEMENT_H_
#define RUNNER_WINDOW_PLACEMENT_H_

#include <windows.h>

#include <optional>

// Persists the top-level window's placement (normal bounds and whether it was
// maximized) per user in the registry, so the next launch reopens the window
// the way it was closed. Windows does not do this for desktop applications.

// Loads the placement saved by |SaveWindowPlacement|. Returns no value when
// nothing is saved, the saved data is unreadable, or the saved bounds are no
// longer on any connected monitor.
std::optional<WINDOWPLACEMENT> LoadWindowPlacement();

// Saves |window|'s current placement. A minimized window is saved as the state
// it would restore to (maximized or normal), never as minimized.
void SaveWindowPlacement(HWND window);

#endif  // RUNNER_WINDOW_PLACEMENT_H_
