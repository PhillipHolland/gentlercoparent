import StoreKit
import Foundation

// Extension to provide a human-readable string for Product.SubscriptionPeriod.Unit
extension Product.SubscriptionPeriod.Unit {
    var stringRepresentation: String {
        switch self {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        @unknown default:
            return "unknown"
        }
    }
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let monthProductID = "com.gentlercoparent.month"
    static let yearProductID = "com.gentlercoparent.year"
    static let allProductIDs: Set<String> = [monthProductID, yearProductID]
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var purchaseError: String?
    @Published var isLoadingProducts = false
    @Published var isPurchasing = false

    private var updatesTask: Task<Void, Never>?

    init() {
        print("💳 Initializing SubscriptionManager")
        print("💳 StoreKit can make payments: \(StoreKit.AppStore.canMakePayments)")
        
        // Start listening for transaction updates (single listener for the app)
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handleTransactionUpdate(update)
            }
        }
        
        Task {
            await loadProducts()
            await checkForExistingTransactions()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // Load available products
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        
        print("💳 Loading products from App Store...")
        do {
            let requestedProductIDs = Array(Self.allProductIDs)
            let products = try await Product.products(for: requestedProductIDs)
            print("💳 Successfully loaded \(products.count) products")
            
            // Stable order: annual first
            self.products = products.sorted { a, b in
                if a.id == Self.yearProductID { return true }
                if b.id == Self.yearProductID { return false }
                return a.id < b.id
            }
            
            if products.isEmpty {
                purchaseError = StoreKit.AppStore.canMakePayments
                    ? "Subscription products aren’t available yet. Check your network and try again."
                    : "Purchases are disabled on this device (Screen Time / restrictions)."
            } else {
                // Keep product-load errors from blocking a later restore message incorrectly
                if purchaseError?.contains("products") == true || purchaseError?.contains("No subscription") == true {
                    purchaseError = nil
                }
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            purchaseError = "Couldn’t load subscriptions: \(error.localizedDescription)"
        }
    }

    // Check for existing transactions at launch
    private func checkForExistingTransactions() async {
        for await result in Transaction.currentEntitlements {
            await handleTransactionUpdate(result)
        }
    }

    // Handle transaction updates from Transaction.updates
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            print("💳 Processing verified transaction: \(transaction.productID)")
            print("💳 Transaction ID: \(transaction.id)")
            print("💳 Purchase date: \(transaction.purchaseDate)")
            print("💳 Revocation date: \(transaction.revocationDate?.description ?? "None")")
            print("💳 Expiration date: \(transaction.expirationDate?.description ?? "None")")
            
            // Check if the transaction is active (not revoked and not expired)
            let isActive = transaction.revocationDate == nil && (transaction.expirationDate == nil || transaction.expirationDate! > Date())
            print("💳 Transaction is active: \(isActive)")
            
            if isActive {
                _ = await MainActor.run {
                    self.purchasedProductIDs.insert(transaction.productID)
                    self.purchaseError = nil
                    print("💳 Added active subscription: \(transaction.productID)")
                }
            } else {
                _ = await MainActor.run {
                    self.purchasedProductIDs.remove(transaction.productID)
                    print("💳 Removed inactive subscription: \(transaction.productID)")
                }
            }
            
            // Finish the transaction to remove it from the queue
            await transaction.finish()
            print("💳 Transaction finished: \(transaction.id)")
        case .unverified(let transaction, let error):
            print("❌ Unverified transaction: \(transaction.productID)")
            print("❌ Verification error: \(error.localizedDescription)")
            // Skip unverified transactions
            return
        }
    }

    /// Convenience: purchase by product id after ensuring products are loaded.
    func purchase(productID: String) async {
        if products.isEmpty {
            await loadProducts()
        }
        guard let product = products.first(where: { $0.id == productID }) else {
            purchaseError = "That plan isn’t available right now. Pull to refresh or try again."
            return
        }
        await purchase(product)
    }
    
    // Initiate a purchase with enhanced logging and error handling
    func purchase(_ product: Product) async {
        print("🛒 Starting purchase for: \(product.id)")
        
        guard StoreKit.AppStore.canMakePayments else {
            purchaseError = "Purchases are disabled on this device."
            return
        }
        
        purchaseError = nil
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                print("✅ Purchase successful for: \(product.id)")
                await handleTransactionUpdate(verification)
                // Re-scan entitlements so UI is consistent after purchase
                await checkForExistingTransactions()
                purchaseError = nil
            case .userCancelled:
                purchaseError = nil // quiet cancel — not an error banner
            case .pending:
                purchaseError = "Purchase is pending approval (Ask to Buy). You’ll get access once approved."
            @unknown default:
                purchaseError = "Unknown purchase result. Please try again."
            }
        } catch StoreKitError.userCancelled {
            purchaseError = nil
        } catch StoreKitError.networkError {
            purchaseError = "Network error. Check your connection and try again."
        } catch StoreKitError.systemError {
            purchaseError = "System error. Please try again later."
        } catch StoreKitError.notAvailableInStorefront {
            purchaseError = "This subscription isn’t available in your region."
        } catch StoreKitError.notEntitled {
            purchaseError = "You’re not authorized to make purchases on this Apple ID."
        } catch {
            print("💥 Purchase failed: \(error)")
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
    }
    
    // Helper to detect testing environment
    private func isTestFlightOrDebug() -> Bool {
        #if DEBUG
        return true
        #else
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return true
        }
        return false
        #endif
    }

    // Restore purchases with enhanced logging
    func restorePurchases() async {
        print("🔄 Starting purchase restoration...")
        
        do {
            try await AppStore.sync()
            print("✅ AppStore.sync() completed successfully")
            await checkForExistingTransactions()
            print("✅ Purchase restoration completed")
            
            await MainActor.run {
                if self.purchasedProductIDs.isEmpty {
                    self.purchaseError = "No previous purchases found to restore."
                } else {
                    self.purchaseError = nil
                    print("✅ Restored \(self.purchasedProductIDs.count) active subscription(s)")
                }
            }
        } catch {
            print("❌ Purchase restoration failed: \(error)")
            await MainActor.run {
                self.purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
            }
        }
    }

    // Get subscription info for a product
    func subscriptionInfo(for productID: String) -> (price: String, trialPeriod: String)? {
        guard let product = products.first(where: { $0.id == productID }) else { return nil }
        let price = product.displayPrice
        if let subscription = product.subscription,
           let introductoryOffer = subscription.introductoryOffer {
            let period = introductoryOffer.period
            let trialPeriod = "\(period.value) \(period.unit.stringRepresentation)\(period.value > 1 ? "s" : "")"
            return (price: price, trialPeriod: trialPeriod)
        }
        return (price: price, trialPeriod: "no trial")
    }
    
    // Clear any stuck transactions (useful for TestFlight debugging)
    func clearStuckTransactions() async {
        print("🧹 Clearing any stuck transactions...")
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                print("🧹 Finishing transaction: \(transaction.productID)")
                await transaction.finish()
            case .unverified(let transaction, let error):
                print("🧹 Finishing unverified transaction: \(transaction.productID), error: \(error)")
                await transaction.finish()
            }
        }
        
        print("✅ Finished clearing transactions")
    }
    
    // Enhanced subscription status check
    func hasActiveSubscription() -> Bool {
        let isActive = !purchasedProductIDs.isEmpty
        print("📱 Active subscription status: \(isActive)")
        print("📱 Active products: \(purchasedProductIDs)")
        return isActive
    }
    
    // TestFlight debugging: Force complete a stuck purchase
    func forceCompleteStuckPurchase(productID: String) async {
        print("🔧 Force completing stuck purchase for: \(productID)")
        
        // Check if there are any pending transactions for this product
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == productID {
                    print("🔧 Found transaction for \(productID), processing...")
                    await handleTransactionUpdate(result)
                    return
                }
            case .unverified(let transaction, let error):
                if transaction.productID == productID {
                    print("🔧 Found unverified transaction for \(productID): \(error)")
                    // Still try to process it
                    await handleTransactionUpdate(result)
                    return
                }
            }
        }
        
        print("🔧 No pending transactions found for \(productID)")
        
        // In TestFlight, sometimes we need to manually add the subscription
        if isTestFlightOrDebug() {
            print("🔧 TestFlight: Manually adding subscription as active")
            await MainActor.run {
                self.purchasedProductIDs.insert(productID)
                self.purchaseError = nil
            }
        }
    }
}
