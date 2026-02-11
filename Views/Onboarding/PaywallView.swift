import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var animatePulse = false

    var onComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.gradientBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // Header with animated icon
                        headerSection

                        // Benefits list
                        benefitsSection

                        // Product cards
                        productCardsSection

                        // Trial info
                        trialInfoSection

                        // CTA button
                        purchaseButton

                        // Restore & terms
                        footerSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onComplete?()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .onAppear {
            // Pre-select annual (best value)
            selectedProduct = subscriptionManager.annualProduct ?? subscriptionManager.weeklyProduct
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 15) {
            // Animated leaf icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            Text("Unlock Your Potential")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Progress without pressure")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BenefitRow(emoji: "♾️", text: "Unlimited habits", subtext: "Track everything that matters")
            BenefitRow(emoji: "📊", text: "Detailed insights", subtext: "See your progress over time")
            BenefitRow(emoji: "🔄", text: "Flexible streaks", subtext: "Streaks that bend, not break")
            BenefitRow(emoji: "🎨", text: "Beautiful themes", subtext: "Make it yours with 12+ themes")
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }

    private var productCardsSection: some View {
        VStack(spacing: 12) {
            // Annual (Best Value) - show first
            if let annual = subscriptionManager.annualProduct {
                ProductCard(
                    product: annual,
                    isSelected: selectedProduct?.id == annual.id,
                    isBestValue: true,
                    savings: subscriptionManager.savingsPercentage(for: annual),
                    trialDays: subscriptionManager.trialDays(for: annual)
                ) {
                    selectedProduct = annual
                }
            }

            // Weekly
            if let weekly = subscriptionManager.weeklyProduct {
                ProductCard(
                    product: weekly,
                    isSelected: selectedProduct?.id == weekly.id,
                    isBestValue: false,
                    savings: nil,
                    trialDays: subscriptionManager.trialDays(for: weekly)
                ) {
                    selectedProduct = weekly
                }
            }
        }
    }

    private var trialInfoSection: some View {
        Group {
            if let product = selectedProduct,
               let trialDays = subscriptionManager.trialDays(for: product) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(AppColors.mutedGold)
                    Text("\(trialDays)-day free trial. Cancel anytime.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }

    private var purchaseButton: some View {
        Button(action: {
            Task {
                await purchase()
            }
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(buttonText)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [AppColors.sageGreen, AppColors.deepForest],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: AppColors.sageGreen.opacity(0.4), radius: 10)
            .scaleEffect(animatePulse ? 1.02 : 1.0)
        }
        .disabled(selectedProduct == nil || isPurchasing)
    }

    private var buttonText: String {
        guard let product = selectedProduct else { return "Select a Plan" }
        if let trialDays = subscriptionManager.trialDays(for: product) {
            return "Start My Free \(trialDays == 7 ? "Week" : "\(trialDays) Days")"
        }
        return "Start Premium"
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                Task {
                    await subscriptionManager.restorePurchases()
                    if subscriptionManager.isPremium {
                        onComplete?()
                        dismiss()
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 15) {
                Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Text("•")
                Link("Privacy", destination: URL(string: "https://sebastiandoyle.github.io/steadily-privacy/privacy-policy.html")!)
            }
            .font(.caption2)
            .foregroundColor(.white.opacity(0.5))
        }
    }

    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true

        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                onComplete?()
                dismiss()
            }
        } catch {
            print("Purchase error: \(error)")
        }

        isPurchasing = false
    }
}

struct BenefitRow: View {
    let emoji: String
    let text: String
    let subtext: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(subtext)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let savings: Int?
    let trialDays: Int?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(isSelected ? .white : .white.opacity(0.9))

                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColors.sageGreen)
                                .cornerRadius(10)
                        }
                    }

                    if let savings = savings {
                        Text("Save \(savings)%")
                            .font(.caption)
                            .foregroundColor(AppColors.mutedGold)
                    }

                    if let trialDays = trialDays {
                        Text("\(trialDays)-day free trial")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? AppColors.sageGreen.opacity(0.5) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
