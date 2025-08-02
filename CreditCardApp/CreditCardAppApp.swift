import SwiftUI
import CoreData

@main
struct CreditCardAppApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(ServiceContainer.shared)
        }
    }
}

// MARK: - Service Container for Dependency Injection
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    lazy var recommendationEngine: RecommendationEngine = {
        RecommendationEngine()
    }()
    
    lazy var dataManager: DataManager = {
        DataManager(persistenceController: persistenceController)
    }()
    
    lazy var nlpProcessor: NLPProcessor = {
        NLPProcessor()
    }()
    
    private let persistenceController: PersistenceController
    
    private init() {
        self.persistenceController = PersistenceController.shared
    }
}

// MARK: - Core Data Persistence Controller
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CreditCardApp")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
} 