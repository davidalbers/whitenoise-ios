import SnapshotTesting
import SwiftUI
import UIKit
@testable import White_Noise
import XCTest

final class CustomTimerSheetSnapshotTests: XCTestCase {
    private func assertView(
        _ view: some View,
        width: CGFloat = 390,
        height: CGFloat,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let vc = UIHostingController(rootView: view.environment(ThemeColors()))
        assertSnapshot(
            of: vc,
            as: .image(on: ViewImageConfig(size: CGSize(width: width, height: height))),
            record: false,
            file: file,
            testName: testName,
            line: line
        )
    }

    // MARK: - DurationPicker

    func testDurationPicker_zeroDuration() {
        assertView(DurationPicker(duration: .constant(0)).frame(height: 200), height: 200)
    }

    func testDurationPicker_withDuration() {
        assertView(DurationPicker(duration: .constant(2 * 3600 + 45 * 60)).frame(height: 200), height: 200)
    }

    func testDurationPicker_disabled() {
        assertView(DurationPicker(duration: .constant(3600), isEnabled: false).frame(height: 200), height: 200)
    }

    // MARK: - CustomTimerSheet

    func testCustomTimerSheet_zeroDuration() {
        assertView(
            CustomTimerSheet(duration: .constant(0), onSet: {}, onCancel: {}),
            height: 440
        )
    }

    func testCustomTimerSheet_withDuration() {
        assertView(
            CustomTimerSheet(duration: .constant(TimeInterval(1 * 3600 + 30 * 60)), onSet: {}, onCancel: {}),
            height: 440
        )
    }
}
