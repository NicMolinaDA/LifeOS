import Foundation
import Combine

#if canImport(Metal)
import Metal
#endif

// MARK: - Core Architecture

protocol FrameworkModule {
    var moduleId: String { get }
    func initialize() async throws
    func cleanup()
    var isReady: Bool { get }
}

@MainActor
final class ProfessionalFramework: ObservableObject {
    static let shared = ProfessionalFramework()

    @Published var isInitialized = false
    @Published var activeModules: [String: FrameworkModule] = [:]

    let renderingEngine: RenderingEngine
    let computationEngine: ComputationEngine
    let cadEngine: CADEngine
    let mediaProcessor: MediaProcessor
    let gameEngine: GameEngine
    let scientificCompute: ScientificComputeEngine
    let dataManager: DataManager

    private init() {
        renderingEngine = RenderingEngine()
        computationEngine = ComputationEngine()
        cadEngine = CADEngine()
        mediaProcessor = MediaProcessor()
        gameEngine = GameEngine()
        scientificCompute = ScientificComputeEngine()
        dataManager = DataManager()
    }

    func initializeFramework() async {
        guard isInitialized == false else { return }
        do {
            try await renderingEngine.initialize()
            try await computationEngine.initialize()
            try await cadEngine.initialize()
            try await mediaProcessor.initialize()
            try await gameEngine.initialize()
            try await scientificCompute.initialize()
            try await dataManager.initialize()

            activeModules[renderingEngine.moduleId] = renderingEngine
            activeModules[computationEngine.moduleId] = computationEngine
            activeModules[cadEngine.moduleId] = cadEngine
            activeModules[mediaProcessor.moduleId] = mediaProcessor
            activeModules[gameEngine.moduleId] = gameEngine
            activeModules[scientificCompute.moduleId] = scientificCompute
            activeModules[dataManager.moduleId] = dataManager

            isInitialized = true
        } catch {
            print("Framework initialization failed: \(error)")
        }
    }
}

// MARK: - Errors

enum FrameworkError: Error {
    case metalNotSupported
    case initializationFailed
    case moduleNotReady
}

enum CADError: Error {
    case noActiveDocument
    case invalidOperation
    case geometryError
}

