import Foundation
import Intents

@available(iOS 12.0, *)
class ShortcutCreator {
    private let compoundIntentKey = "dalbers.compound_interaction"

    public func resetShortcutsWithNewIntent(intent: PlayIntent) {
        INInteraction.delete(with: compoundIntentKey)
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.groupIdentifier = compoundIntentKey
        interaction.donate()
    }
}
