import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var framework: ProfessionalFramework
    @EnvironmentObject private var purchaseManager: PurchaseManager

    private let modules = ["Rendering", "CAD", "Media", "Game", "Scientific", "Data"]

    var body: some View {
        NavigationStack {
            List(modules, id: \.self) { module in
                NavigationLink(value: module) {
                    HStack(spacing: 12) {
                        Image(systemName: iconFor(module))
                            .foregroundStyle(.accent)
                        Text(module)
                        Spacer()
                        if framework.isInitialized {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        } else {
                            ProgressView().scaleEffect(0.8)
                        }
                        if requiresPro(module), !purchaseManager.hasProEntitlement {
                            Text("PRO").font(.caption2).bold().padding(.horizontal, 6).padding(.vertical, 2).background(Color.orange.opacity(0.15)).clipShape(Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
            .navigationTitle("Professional Framework")
            .navigationDestination(for: String.self) { module in
                moduleView(for: module)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        PaywallView()
                    } label: {
                        Label("Upgrade", systemImage: purchaseManager.hasProEntitlement ? "checkmark.seal" : "crown")
                    }
                }
            }
        }
    }

    private func moduleView(for module: String) -> some View {
        if requiresPro(module) && !purchaseManager.hasProEntitlement {
            return AnyView(PaywallView(highlightedModule: module))
        }
        switch module {
        case "Rendering": return AnyView(Text("Rendering Module").padding())
        case "CAD": return AnyView(Text("CAD Module").padding())
        case "Media": return AnyView(Text("Media Module").padding())
        case "Game": return AnyView(Text("Game Module").padding())
        case "Scientific": return AnyView(Text("Scientific Module").padding())
        case "Data": return AnyView(Text("Data Module").padding())
        default: return AnyView(Text("Unknown Module"))
        }
    }

    private func requiresPro(_ module: String) -> Bool {
        // Gate heavier modules for Pro to balance free vs paid value
        return module == "Rendering" || module == "Game" || module == "Media"
    }

    private func iconFor(_ module: String) -> String {
        switch module {
        case "Rendering": return "sparkles"
        case "CAD": return "square.on.square.dashed"
        case "Media": return "camera.filters"
        case "Game": return "gamecontroller"
        case "Scientific": return "function"
        case "Data": return "internaldrive"
        default: return "cube"
        }
    }
}

