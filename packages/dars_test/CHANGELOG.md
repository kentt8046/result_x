## 0.2.0

- Initial release of `dars_test` package
- `isOk` and `isErr` matchers for Result type testing
  - Basic variant check: `isOk`, `isErr`
  - Value matching: `isOk(42)`, `isErr('error')`
  - Matcher support: `isOk(greaterThan(0))`, `isErr(contains('fail'))`
  - Type-safe checks: `isOk<int>()`, `isErr<String>()`
- Detailed mismatch descriptions for debugging
