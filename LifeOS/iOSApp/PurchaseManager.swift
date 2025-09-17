import Foundation
import Combine
import SwiftUI

#if canImport(StoreKit)
import StoreKit
#endif

#if canImport(CryptoKit)
import CryptoKit
#endif

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var hasProEntitlement: Bool = false
    @Published var priceString: String?
    @Published var isPurchasing: Bool = false

    private let productIdentifiers = ["com.lifeos.pro.unlock"]
    private var proProduct: Any?
    private var updatesTask: Task<Void, Never>?

    private init() {}

    deinit { updatesTask?.cancel() }

    func start() async {
        await fetchProducts()
        await refreshEntitlements()
        updatesTask = listenForTransactions()
    }

    func purchasePro() async {
        #if canImport(StoreKit)
        guard let product = proProduct as? Product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .unverified:
                    await refreshEntitlements()
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    await validateWithBackend()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase error: \(error)")
        }
        #endif
    }

    func restorePurchases() async {
        #if canImport(StoreKit)
        do { try await AppStore.sync() } catch { print("Restore error: \(error)") }
        await refreshEntitlements()
        await validateWithBackend()
        #endif
    }

    // MARK: - Private

    private func fetchProducts() async {
        #if canImport(StoreKit)
        do {
            let products = try await Product.products(for: productIdentifiers)
            if let pro = products.first {
                proProduct = pro
                priceString = pro.displayPrice
            }
        } catch {
            print("Product fetch error: \(error)")
        }
        #endif
    }

    private func refreshEntitlements() async {
        #if canImport(StoreKit)
        var has = false
        do {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                if productIdentifiers.contains(transaction.productID) {
                    has = true
                }
            }
        }
        hasProEntitlement = has
        #endif
    }

    private func listenForTransactions() -> Task<Void, Never> {
        #if canImport(StoreKit)
        return Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
        #else
        return Task { }
        #endif
    }

    private func validateWithBackend() async {
        guard let receiptData = readReceiptData() else { return }
        let payload: [String: Any] = [
            "receipt": receiptData.base64EncodedString(),
            "bundleId": Bundle.main.bundleIdentifier ?? "",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        do {
            let body = try JSONSerialization.data(withJSONObject: payload)
            let url = URL(string: backendURLString())!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if let signature = makeHMACSignature(for: body) {
                request.addValue(signature, forHTTPHeaderField: "X-Signature")
            }
            request.httpBody = body
            let _ = try await URLSession.shared.data(for: request)
        } catch {
            print("Backend validation error: \(error)")
        }
    }

    private func readReceiptData() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else { return nil }
        return try? Data(contentsOf: url)
    }

    private func backendURLString() -> String { "https://your-api.example.com/v1/validate/apple" }

    private func makeHMACSignature(for data: Data) -> String? {
        #if canImport(CryptoKit)
        guard let keyString = Bundle.main.object(forInfoDictionaryKey: "RECEIPT_HMAC_KEY") as? String,
              let keyData = keyString.data(using: .utf8) else { return nil }
        let symmetricKey = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(signature).map { String(format: "%02hhx", $0) }.joined()
        #else
        return nil
        #endif
    }
}

