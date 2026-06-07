# Snapshot Testing

We use [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) (v1.19.2) by Point-Free. Tests live in the `White NoiseTests`. Each test renders a `UIHostingController` and diffs a PNG stored in `__Snapshots__/`. The snapshots folder should be committed to git so CI can compare against them.

To add a new test, use the existing `assertView` or `assertMainView` helpers in the relevant file and pass `record: true` for the first run to generate the reference image — then set it back to `false`. For `MainView` tests that involve a specific theme, set both `vm.theme` and `vm.colorScheme` in the configure block, and the helper will set `overrideUserInterfaceStyle` on the hosting controller to ensure colors resolve correctly before the snapshot is taken (SwiftUI's `preferredColorScheme` modifier applies too late in the render pass to affect the snapshot).

To re-record a snapshot after an intentional UI change, set `record: true` on the specific `assertSnapshot` call (or on the shared helper temporarily), run the test once, then revert. To re-record all snapshots at once you can set the `RECORD_SNAPSHOTS=true` environment variable in the test scheme.
