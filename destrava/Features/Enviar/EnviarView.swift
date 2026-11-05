import SwiftUI
import UniformTypeIdentifiers

struct EnviarView: View {
    let aoEnviar: (Edital) -> Void

    @Environment(EditalStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var arquivo: URL?
    @State private var link = ""
    @State private var escolhendoArquivo = false
    @State private var enviando = false
    @State private var erro: String?

    private var linkValido: URL? {
        let texto = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: texto),
              let esquema = url.scheme?.lowercased(), ["http", "https"].contains(esquema),
              url.host() != nil
        else { return nil }
        return url
    }

    private var podeEnviar: Bool { (arquivo != nil || linkValido != nil) && !enviando }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manda o edital,\na gente destrava.")
                            .font(.largeTitle.weight(.heavy))
                        Text("Você recebe o que importa: se pode participar, os prazos, os documentos e as regras que podem te eliminar.")
                            .foregroundStyle(.secondary)
                    }

                    Button { escolhendoArquivo = true } label: { seletorDeArquivo }
                        .buttonStyle(.plain)

                    HStack(spacing: 12) {
                        Rectangle().fill(.separator).frame(height: 1)
                        Text("ou").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        Rectangle().fill(.separator).frame(height: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Link do edital")
                            .font(.subheadline.weight(.semibold))
                        TextField("https://…/edital.pdf", text: $link)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .background(Paleta.neutro, in: .rect(cornerRadius: 16, style: .continuous))
                    }

                    Label("Nada é inventado: cada informação mostra o trecho e a página do PDF de onde saiu.",
                          systemImage: "checkmark.shield")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let erro {
                        Label(erro, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(Paleta.erro)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await enviar() }
                } label: {
                    HStack(spacing: 8) {
                        if enviando {
                            ProgressView()
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text("Destravar")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(!podeEnviar)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .navigationTitle("Novo edital")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .fileImporter(isPresented: $escolhendoArquivo, allowedContentTypes: [.pdf]) { resultado in
                switch resultado {
                case .success(let url):
                    arquivo = copiarParaTemporario(url)
                case .failure:
                    erro = "Não foi possível abrir esse arquivo."
                }
            }
        }
    }

    private var seletorDeArquivo: some View {
        VStack(spacing: 10) {
            Image(systemName: arquivo == nil ? "doc.badge.plus" : "doc.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Paleta.destaque, in: .rect(cornerRadius: 18, style: .continuous))
            Text(arquivo?.lastPathComponent ?? "Escolher PDF")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(arquivo == nil ? "do app Arquivos, iCloud ou Downloads" : "Toque para trocar")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(Paleta.destaqueSuave.opacity(0.6), in: .rect(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Paleta.destaque.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
        }
        .contentShape(.rect)
    }

    private func copiarParaTemporario(_ url: URL) -> URL? {
        let acessou = url.startAccessingSecurityScopedResource()
        defer { if acessou { url.stopAccessingSecurityScopedResource() } }

        let destino = URL.temporaryDirectory.appending(path: url.lastPathComponent)
        try? FileManager.default.removeItem(at: destino)
        do {
            try FileManager.default.copyItem(at: url, to: destino)
            erro = nil
            return destino
        } catch {
            erro = "Não foi possível ler esse PDF."
            return nil
        }
    }

    private func enviar() async {
        enviando = true
        erro = nil
        defer { enviando = false }

        do {
            let edital: Edital
            if let arquivo {
                edital = try await store.enviar(pdf: arquivo)
            } else if let url = linkValido {
                edital = try await store.enviar(link: url)
            } else {
                return
            }
            dismiss()
            aoEnviar(edital)
        } catch {
            self.erro = mensagem(de: error)
        }
    }
}

#Preview {
    EnviarView { _ in }
        .environment(EditalStore(servico: Ambiente.servico()))
}
