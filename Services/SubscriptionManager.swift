import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let weeklyProductID = "com.sebastiandoyle.steadily.weekly"
    static let annualProductID = "com.sebastiandoyle.steadily.annual"

    static let allProductIDs: Set<String> = [
        weeklyProductID,
        annualProductID
    ]

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var weeklyProduct: Product? {
        products.first { $0.id == Self.weeklyProductID }
    }

    var annualProduct: Product? {
        products.first { $0.id == Self.annualProductID }
    }

    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }

        // Listen for transaction updates
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await updatePurchasedProducts()
                }
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            products = try await Product.products(for: Self.allProductIDs)
            // Sort: annual first (higher price), then weekly
            products.sort { $0.price > $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }

        isLoading = false
    }

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await updatePurchasedProducts()
                return true
            }
            return false
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    // Helper for formatting prices
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    func savingsPercentage(for product: Product) -> Int? {
        guard product.id == Self.annualProductID,
              let weekly = weeklyProduct else { return nil }

        // Weekly is $4.99, so yearly at weekly rate = 4.99 * 52 = ~$260
        // Annual is $29.99, so savings = (1 - 29.99/259.48) * 100 = ~88%
        let yearlyAtWeeklyRate = weekly.price * 52
        let savings = (1 - (product.price / yearlyAtWeeklyRate)) * 100
        return NSDecimalNumber(decimal: savings).intValue
    }

    // Check if user is eligible for introductory offer (trial)
    func isEligibleForIntroOffer(for product: Product) async -> Bool {
        await product.subscription?.isEligibleForIntroOffer ?? false
    }

    func trialDays(for product: Product) -> Int? {
        guard let subscription = product.subscription,
              let introOffer = subscription.introductoryOffer,
              introOffer.paymentMode == .freeTrial else {
            return nil
        }

        switch introOffer.period.unit {
        case .day:
            return introOffer.period.value
        case .week:
            return introOffer.period.value * 7
        default:
            return nil
        }
    }
}
