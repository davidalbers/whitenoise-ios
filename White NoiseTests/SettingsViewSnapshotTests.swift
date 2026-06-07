import SnapshotTesting
import SwiftUI
@testable import White_Noise
import XCTest

@MainActor
final class SettingsViewSnapshotTests: XCTestCase {
    private func makeView() -> some View {
        SettingsView(dismissAction: {})
            .environment(ThemeColors())
    }

    private func assertView(
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let vc = UIHostingController(rootView: makeView())
        assertSnapshot(
            of: vc,
            as: .image(on: .iPhone13Pro),
            record: false,
            file: file,
            testName: testName,
            line: line
        )
    }

    func testSettingsView() {
        assertView()
    }

    // MARK: - Subview helper

    private func assertSubview(
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

    // MARK: - ThemeCard

    func testThemeCard() {
        let themes: [Themer.Theme] = [.auto, .dark, .light]
        assertSubview(
            ThemeCard(themes: themes, selected: .auto, onSelect: { _ in }).padding(16),
            height: 220
        )
    }

    // MARK: - WidgetThemeCard

    func testWidgetThemeCard_mirroringApp() {
        let themes: [Themer.Theme] = [.auto, .dark, .light]
        assertSubview(
            WidgetThemeCard(themes: themes, widgetMirrorsApp: true, widgetTheme: .auto,
                            onMirrorAppChanged: { _ in }, onThemeChanged: { _ in }).padding(16),
            height: 100
        )
    }

    func testWidgetThemeCard_ownTheme() {
        let themes: [Themer.Theme] = [.auto, .dark, .light]
        assertSubview(
            WidgetThemeCard(themes: themes, widgetMirrorsApp: false, widgetTheme: .dark,
                            onMirrorAppChanged: { _ in }, onThemeChanged: { _ in }).padding(16),
            height: 280
        )
    }
}
