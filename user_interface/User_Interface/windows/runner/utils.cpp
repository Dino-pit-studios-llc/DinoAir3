#include "utils.h"

#include <cstdio>
#include <flutter_windows.h>
#include <io.h>
// #include <limits>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

// Safety helper for bounded length computation to avoid buffer over-read
// (CWE-126). Returns the number of wide characters up to 'max' or until a null
// terminator. If 's' is nullptr, returns 0. This avoids relying on wcslen for
// potentially non-terminated inputs.
static size_t safe_wcsnlen(const wchar_t *s, size_t max) {
  if (s == nullptr)
    return 0;
  size_t i = 0;
  for (; i < max && s[i] != L'\0'; ++i) {
  }
  return i;
}

// Upper bound for scanning UTF-16 input. Prevents unbounded reads when the
// input is not properly null-terminated. 1,048,576 wide chars (~2 MB) is a
// generous cap for command-line args/strings while still preventing over-read.
static constexpr size_t kMaxUtf16Scan = 1U << 20;

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t **argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t *utf16_string) {
  if (utf16_string == nullptr) {
    return {};
  }

  // Bounded length computation to prevent over-read on non-terminated buffers.
  // If no terminator is found within kMaxUtf16Scan, treat input as invalid.
  const size_t wlen = safe_wcsnlen(utf16_string, kMaxUtf16Scan);
  if (wlen == 0) {
    return {};
  }
  if (wlen == kMaxUtf16Scan) {
    // No null-terminator encountered within bound; avoid reading past end.
    return {};
  }
  // Guard against size_t -> int overflow for Windows API.
  if (wlen > static_cast<size_t>(std::numeric_limits<int>::max())) {
    return {};
  }
  const int input_length = static_cast<int>(wlen);

  // First pass: get number of UTF-8 bytes required (excluding null terminator
  // because we pass explicit length, not -1). This avoids depending on a null
  // terminator and keeps the operation bounded.
  int target_length =
      ::WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
                            input_length, nullptr, 0, nullptr, nullptr);

  std::string utf8_string;
  if (target_length <= 0 ||
      static_cast<size_t>(target_length) > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(static_cast<size_t>(target_length));

  // Second pass: perform the actual conversion into the sized buffer.
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string, input_length,
      utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return {};
  }
  return utf8_string;
}
