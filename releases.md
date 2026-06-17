# Releases

## v2.4.2

  - Drop dependency on `mapping` gem.

## v2.4.0

  - Fix option parsing and validation: required options are now detected correctly and raise `Samovar::MissingValueError` when missing.
  - Fix flag value parsing: flags that expect a value no longer consume a following flag as their value (e.g. `--config <path>` will not consume `--verbose`).
  - Usage improvements: required options are marked as `(required)` in usage output.

## v2.3.0

  - Add support for `--[no]-thing` explicit boolean flags, allowing users to explicitly enable or disable boolean options.

## v2.2.0

  - Add support for explicit output: commands can now specify an output stream (e.g. `STDOUT`, `STDERR`, or custom IO objects) via the `output:` parameter in `Command.call`.

## v2.1.4

  - `Command#to_s` now returns the class name by default, improving debugging and introspection.
