/// Centralized configuration for fluent-asserts.
/// Contains all configurable constants and settings.
module fluentasserts.core.config;

import std.process : environment;

/// Output format for assertion failure messages.
enum OutputFormat {
  verbose,
  compact,
  tap
}

/// Compile-time check for whether assertions are enabled.
///
/// By default, assertions are enabled in debug builds and disabled in release builds.
/// This allows using fluent-asserts as a replacement for D's built-in assert
/// while maintaining the same release-build behavior.
///
/// Build configurations:
/// - Debug build (default): assertions enabled
/// - Release build (`-release` or `dub build -b release`): assertions disabled (no-op)
/// - Force disable: add version `D_Disable_FluentAsserts` to disable even in debug
/// - Force enable in release: add version `FluentAssertsDebug` to enable in release builds
///
/// Example dub.sdl configuration to force enable in release:
/// ---
/// versions "FluentAssertsDebug"
/// ---
///
/// Example dub.sdl configuration to always disable:
/// ---
/// versions "D_Disable_FluentAsserts"
/// ---
version (D_Disable_FluentAsserts) {
  enum fluentAssertsEnabled = false;
} else version (release) {
  version (FluentAssertsDebug) {
    enum fluentAssertsEnabled = true;
  } else {
    enum fluentAssertsEnabled = false;
  }
} else {
  enum fluentAssertsEnabled = true;
}

/// Singleton configuration struct for fluent-asserts.
/// Provides centralized access to all configurable settings.
struct FluentAssertsConfig {
  /// Buffer and array size settings.
  struct BufferSizes {
    /// Default size for FixedArray and FixedAppender.
    enum defaultFixedArraySize = 512;

    /// Default size for FixedStringArray.
    enum defaultStringArraySize = 32;

    /// Buffer size for diff output.
    enum diffBufferSize = 4096;

    /// Maximum message segments in assertion result.
    enum maxMessageSegments = 32;

    /// Buffer size for expected/actual value formatting.
    enum expectedActualBufferSize = 512;

    /// Maximum operation names that can be chained.
    enum maxOperationNames = 8;
  }

  /// Display and formatting options.
  struct Display {
    /// Maximum length for values displayed in assertion messages.
    /// Longer values are truncated.
    enum maxMessageValueLength = 80;

    /// Width for line number padding in diff output.
    enum defaultLineNumberWidth = 5;

    /// Number of context lines shown around diff changes.
    enum contextLines = 2;
  }

  /// Numeric conversion settings.
  struct NumericConversion {
    /// Maximum decimal places for floating point conversion.
    enum floatingPointDecimals = 6;

    /// Buffer size for integer digit conversion (enough for ulong max).
    enum digitConversionBufferSize = 20;

    /// Bytes per kilobyte for memory formatting.
    enum bytesPerKilobyte = 1024;
  }

  /// Shorthand access to buffer sizes.
  alias buffers = BufferSizes;

  /// Shorthand access to display options.
  alias display = Display;

  /// Shorthand access to numeric conversion settings.
  alias numeric = NumericConversion;

  /// Output format settings.
  struct Output {
    private static OutputFormat _format = OutputFormat.verbose;
    private static bool _initialized = false;

    static OutputFormat format() @safe nothrow {
      if (!_initialized) {
        _initialized = true;
        try {
          if (environment.get("CLAUDECODE") == "1") {
            _format = OutputFormat.compact;
          }
        } catch (Exception) {
        }
      }
      return _format;
    }

    static void setFormat(OutputFormat fmt) @safe nothrow {
      _format = fmt;
      _initialized = true;
    }
  }

  alias output = Output;
}

/// Global configuration instance.
alias config = FluentAssertsConfig;
