import Foundation
import Observation

@MainActor
@Observable
final class EnviarModelo {
    var link = ""
    private(set) var arquivo: URL?
    private(set) var enviando = false
    private(set) var erro: String?

    var linkValido: URL? {
        let texto = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: texto),
              let esquema = url.scheme?.lowercased(), ["http", "https"].contains(esquema),
              url.host() != nil
        else { return nil }
        return url
    }

    var podeEnviar: Bool {
        (arquivo != nil || linkValido != nil) && !enviando
    }

    func receberArquivo(_ resultado: Result<URL, Error>) {
        switch resultado {
        case .success(let url):
            arquivo = copiarParaTemporario(url)
        case .failure:
            erro = "Não foi possível abrir esse arquivo."
        }
    }

    func enviar(usando store: EditalStore) async -> Edital? {
        guard podeEnviar else { return nil }
        enviando = true
        erro = nil
        defer { enviando = false }

        do {
            if let arquivo {
                return try await store.enviar(pdf: arquivo)
            }
            if let url = linkValido {
                return try await store.enviar(link: url)
            }
            return nil
        } catch {
            self.erro = mensagem(de: error)
            return nil
        }
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
}
