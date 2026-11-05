import SwiftData
import SwiftUI

struct PrazosView: View {
    @Environment(EditalStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                if store.proximasDatas.isEmpty {
                    ContentUnavailableView(
                        "Nenhum prazo pela frente",
                        systemImage: "calendar.badge.checkmark",
                        description: Text("Quando você destravar um edital, as datas importantes aparecem aqui.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(store.proximasDatas) { item in
                        NavigationLink(value: item.editalId) {
                            LinhaPrazo(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Prazos")
            .navigationDestination(for: String.self) { id in
                EditalView(id: id)
            }
            .task { await store.carregar() }
            .refreshable { await store.carregar() }
        }
    }
}

private struct LinhaPrazo: View {
    let item: DataAgendada

    private var dias: Int { Date.now.dias(ate: item.data) }

    private var quando: String {
        switch dias {
        case 0: "Hoje"
        case 1: "Amanhã"
        default: "em \(dias) dias"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(item.data.formatted(.dateTime.day().locale(.ptBR)))
                    .font(.title2.weight(.heavy))
                Text(item.data.formatted(.dateTime.month(.abbreviated).locale(.ptBR)).uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Paleta.destaque)
            }
            .frame(width: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.evento)
                    .font(.headline)
                Text(item.editalTitulo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(quando)
                .font(.footnote.weight(.bold))
                .foregroundStyle(dias <= 3 ? AnyShapeStyle(Paleta.erro) : AnyShapeStyle(.secondary))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PrazosView()
        .environment(EditalStore(servico: Ambiente.servico()))
        .modelContainer(for: MarcaChecklist.self, inMemory: true)
}
