# Linting and Formatting

Based on [this blog post](https://jasonzurita.com/linting-and-formatting-swift-part-2/).

## Tools

- **SwiftFormat** — auto-formats code style
- **SwiftLint** — catches code quality issues

Install via Homebrew:
```bash
brew install swiftformat swiftlint
```

## How it works

**Locally:** SwiftFormat runs automatically when you run the test suite (`Cmd+U`) via a build phase on the `White NoiseTests` target. This keeps formatting out of your normal build cycle and preserves undo history during development.

**CI:** Both tools run on every pull request via GitHub Actions (`.github/workflows/ci.yml`). SwiftFormat runs in lint mode (no changes, just fails if anything is unformatted). SwiftLint runs and fails on any violation.

## Running manually

```bash
swiftformat .           # format all files
swiftformat . --lint    # check without making changes
swiftlint lint --strict # lint all files
```

## Configuration

- `.swiftformat` — SwiftFormat rules 
- `.swiftlint.yml` — SwiftLint rules

