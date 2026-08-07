import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Gentler_Coparent")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit to the same container as entitlements / GCPCloudKit
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                let options = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: GCPCloudKit.containerIdentifier
                )
                storeDescription.cloudKitContainerOptions = options
            }
        }
        
        container.loadPersistentStores { _, loadError in
            if let loadError = loadError as NSError? {
                print("CoreData CloudKit error: \(loadError), \(loadError.userInfo)")
            } else {
                print("CloudKit container loaded successfully")
            }
        }
        
        // Configure the view context
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Listen for remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            print("Remote changes detected from CloudKit")
        }
    }
}
