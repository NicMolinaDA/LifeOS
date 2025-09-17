import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    var highlightedModule: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
                .padding(.top, 24)

            Text("Unlock LifeOS Pro")
                .font(.title2).bold()

            if let module = highlightedModule {
                Text("Access required to use \(module)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Advanced Rendering, Media, and Game engines", systemImage: "sparkles")
                Label("Priority performance and pro computation", systemImage: "speedometer")
                Label("Local-first data with optional sync", systemImage: "lock.shield")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await purchaseManager.purchasePro() }
            } label: {
                HStack { Text("Go Pro") ; Text(purchaseManager.priceString ?? "$4.99").opacity(0.8) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(purchaseManager.isPurchasing)

            Button("Restore Purchases") { Task { await purchaseManager.restorePurchases() } }
                .buttonStyle(.bordered)
                .padding(.bottom, 24)

            Spacer()
        }
        .padding()
        .navigationTitle("Pro Upgrade")
    }
}

