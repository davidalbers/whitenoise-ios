import Foundation
@available(iOS 12.0, *)
class IntentParser {
    private var intent: PlayIntent

    init(intent: PlayIntent) {
        self.intent = intent
    }
    
    public func playForIntentIfNeeded() -> Bool {
        return intent.color != nil
    }
    
    public func getMinutesFromIntent() -> Double? {
        if let minutes = intent.minutes {
            return Double(truncating: minutes) * 60.0
        }
        return nil
    }
    
    public func getWavesEnabledFromIntent() -> Bool {
        return intent.noiseModification?.contains("wavy") ?? false
        
    }
    
    public func getFadingEnabledFromIntent() -> Bool {
        return intent.noiseModification?.contains("fading") ?? false
    }
    
}
