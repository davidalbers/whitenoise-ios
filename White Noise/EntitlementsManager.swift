import StoreKit

let premiumProductID = "com.dalbers.WhiteNoise.premium"

@MainActor
@Observable
final class EntitlementsManager {
    var hasPremium = false
    var trialStartDate: Date?

    var isInTrial: Bool {
        trialStartDate.map { Date().timeIntervalSince($0) < 30 * 86400 } ?? false
    }

    var trialExpired: Bool {
        trialStartDate != nil && !isInTrial
    }

    var hasPremiumAccess: Bool {
        hasPremium || isInTrial
    }

    var daysRemainingInTrial: Int? {
        guard let start = trialStartDate, isInTrial else { return nil }
        let elapsed = Date().timeIntervalSince(start)
        return max(0, 30 - Int(elapsed / 86400))
    }

    private let settings: SettingsSource

    init(settings: SettingsSource = SettingsSource()) {
        self.settings = settings
        trialStartDate = settings.trialStartDate()
        Task { await checkCurrentEntitlements() }
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case let .verified(transaction) = result,
                   transaction.productID == premiumProductID
                {
                    hasPremium = true
                    await transaction.finish()
                }
            }
        }
    }

    func startTrial() {
        guard !isInTrial else { return }
        let now = Date()
        settings.setTrialStartDate(now)
        trialStartDate = now
    }

    func checkCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result,
               transaction.productID == premiumProductID
            {
                hasPremium = true
                return
            }
        }
    }
}
