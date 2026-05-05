# Code Quality

## Linting and Formatting

Based on [this blog post](https://jasonzurita.com/linting-and-formatting-swift-part-2/).

**Tools:**
- **SwiftFormat** — auto-formats code style
- **SwiftLint** — catches code quality issues

```bash
brew install swiftformat swiftlint
```

**Locally:** SwiftFormat runs automatically when you run the test suite (`Cmd+U`) via a build phase on the `White NoiseTests` target. This keeps formatting out of your normal build cycle and preserves undo history during development.

**CI:** Both tools run on every pull request via GitHub Actions (`.github/workflows/ci.yml`). SwiftFormat runs in lint mode (no changes, just fails if anything is unformatted). SwiftLint runs and fails on any violation.

**Manually:**
```bash
swiftformat .           # format all files
swiftformat . --lint    # check without making changes
swiftlint lint --strict # lint all files
swiftlint lint --fix    # autofix issues
```

**Configuration:** `.swiftformat` and `.swiftlint.yml`.

---

## Testing

Tests live in `White NoiseTests/White_NoiseTests.swift` and cover `MainViewModel`.

### Running tests

```bash
xcodebuild -scheme "White NoiseTests" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=latest" \
  -configuration Debug \
  test | xcpretty
```

**CI:** Tests run on every push and pull request via `.github/workflows/tests.yml`
