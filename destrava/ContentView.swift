import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Editais", systemImage: "doc.text") {
                InicioView()
            }
            Tab("Prazos", systemImage: "calendar") {
                PrazosView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(EditalStore(servico: Ambiente.servico()))
        .modelContainer(for: MarcaChecklist.self, inMemory: true)
}
