import SwiftData
import SwiftUI

struct InicioView: View {
    @Environment(EditalStore.self) private var store
    @State private var caminho: [String] = []
    @State private var enviando = false

    var body: some View {
        NavigationStack(path: $caminho) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.ptBR)).primeiraMaiuscula)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    if let proximo = store.proximoPrazo {
                        CartaoPrazo(data: proximo.data, rotulo: "Próximo prazo", descricao: proximo.edital.titulo) {
                            Button("Ver edital") { caminho.append(proximo.edital.id) }
                                .buttonStyle(BotaoSobreDestaque())
                        }
                    }

                    lista
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Paleta.fundo)
            .navigationTitle("Destrava")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Destravar edital", systemImage: "plus") { enviando = true }
                }
            }
            .navigationDestination(for: String.self) { id in
                EditalView(id: id)
            }
            .sheet(isPresented: $enviando) {
                EnviarView { edital in caminho.append(edital.id) }
            }
            .task { await store.carregar() }
            .refreshable { await store.carregar() }
        }
    }

    @ViewBuilder
    private var lista: some View {
        switch store.estado {
        case .ocioso, .carregando:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)

        case .falhou(let erro):
            ContentUnavailableView {
                Label("Não deu para carregar", systemImage: "wifi.exclamationmark")
            } description: {
                Text(erro)
            } actions: {
                Button("Tentar de novo") { Task { await store.carregar() } }
                    .buttonStyle(.borderedProminent)
            }

        case .carregado(let editais) where editais.isEmpty:
            ContentUnavailableView(
                "Nenhum edital ainda",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Toque em + para destravar o seu primeiro edital.")
            )

        case .carregado(let editais):
            VStack(alignment: .leading, spacing: 12) {
                Text("Seus editais")
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                ForEach(editais) { edital in
                    NavigationLink(value: edital.id) {
                        LinhaEdital(edital: edital)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct LinhaEdital: View {
    let edital: Edital

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: edital.status == .processando ? "hourglass" : edital.tipo.icone)
                .font(.title3)
                .frame(width: 44, height: 44)
                .foregroundStyle(Paleta.destaque)
                .background(Paleta.destaqueSuave, in: .rect(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(edital.titulo)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(subtitulo)
                    .font(.footnote)
                    .foregroundStyle(edital.status == .processando ? AnyShapeStyle(Paleta.destaque) : AnyShapeStyle(.secondary))
            }

            Spacer(minLength: 8)

            if edital.status == .processando {
                ProgressView()
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .cartao()
    }

    private var subtitulo: String {
        switch edital.status {
        case .processando:
            return "Destravando…"
        case .falhou:
            return "Não conseguimos ler este PDF"
        case .pronto:
            var partes = [edital.conteudo?.documento.orgao, edital.tipo.rotulo].compactMap { $0 }
            if edital.conteudo?.exigeAcao == false { partes.append("só informa") }
            return partes.joined(separator: " · ")
        }
    }
}

#Preview {
    InicioView()
        .environment(EditalStore(servico: Ambiente.servico()))
        .modelContainer(for: MarcaChecklist.self, inMemory: true)
}
