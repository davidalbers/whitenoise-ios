import Foundation
@available(iOS 12.0, *)
class IntentParser {
    private var intent: PlayIntent

    init(intent: PlayIntent) {
        self.intent = intent
    }
    
    public func playForIntentIfNeeded() -> Bool {
        return intent.color != Colors.unknown
    }
    
    public func getMinutesFromIntent() -> Double? {
        if let minutes = intent.minutes {
            return Double(truncating: minutes) * 60.0
        }
        return nil
    }
    
    public func getWavesEnabledFromIntent() -> Bool {
        return intent.noiseModification == Modification.both || intent.noiseModification == Modification.wavy
        
    }
    
    public func getFadingEnabledFromIntent() -> Bool {
        return intent.noiseModification == Modification.both || intent.noiseModification == Modification.fading
    }
    
    public func mapColor() -> MainPresenter.NoiseColors {
        switch intent.color {
        case .pink:
            return MainPresenter.NoiseColors.Pink
        case .brown:
            return MainPresenter.NoiseColors.Brown
        default:
            return MainPresenter.NoiseColors.White
        }
    }
}
