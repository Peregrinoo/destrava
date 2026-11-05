import SwiftData
import SwiftUI

@main
struct destravaApp: App {
    @State private var store = EditalStore(servico: Ambiente.servico())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .tint(Paleta.destaque)
        }
        .modelContainer(for: MarcaChecklist.self)
    }
}

enum Ambiente {
    static let urlBase = URL(string: "http://localhost:3000")!

    static func servico() -> any EditalService {
        HTTPEditalService(cliente: APIClient(urlBase: urlBase))
    }
}
