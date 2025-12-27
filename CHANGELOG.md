## 0.2.0

### dars

#### Breaking Changes

- **BREAKING**: `Result` factory and `Result.async` now require callback to return `Result<T, E>` instead of `T`
  - Before: `Result(($) { return value; }, ...)`
  - After: `Result(($) { return Ok(value); }, ...)`
  - This allows returning `Ok` or `Err` explicitly from within the callback

## 0.1.0

### dars

- Initial release with core Result type functionality
- `Result<T, E>` sealed class (`Ok`, `Err`)
- Early return `$` syntax (sync and async)
- Nullable extension and Future extensions
