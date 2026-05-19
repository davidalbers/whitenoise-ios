import StoreKit

@MainActor
@Observable
final class PurchaseManager {
    var isPurchasing = false
    var purchaseError: String?

    private let entitlements: EntitlementsManager

    init(entitlements: EntitlementsManager) {
        self.entitlements = entitlements
    }

    func purchase() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let products = try await Product.products(for: [premiumProductID])
            guard let product = products.first else {
                purchaseError = "Product unavailable. Please try again later."
                return
            }
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    entitlements.hasPremium = true
                    await transaction.finish()
                case let .unverified(_, error):
                    purchaseError = error.localizedDescription
                }
            case .pending:
                break
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await entitlements.checkCurrentEntitlements()
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
