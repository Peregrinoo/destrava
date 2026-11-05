import Foundation

@MainActor
protocol EditalService {
    func listar() async throws -> [Edital]
    func buscar(id: String) async throws -> Edital
    func enviar(pdf: URL) async throws -> Edital
    func enviar(link: URL) async throws -> Edital
}

struct HTTPEditalService: EditalService {
    let cliente: APIClient

    func listar() async throws -> [Edital] {
        try await cliente.requisicao("editais")
    }

    func buscar(id: String) async throws -> Edital {
        try await cliente.requisicao("editais/\(id)")
    }

    func enviar(pdf: URL) async throws -> Edital {
        let conteudo = try Data(contentsOf: pdf)
        var corpo = CorpoMultipart()
        corpo.adicionarArquivo(campo: "arquivo", nome: pdf.lastPathComponent, tipo: "application/pdf", conteudo: conteudo)
        corpo.finalizar()
        return try await cliente.requisicao("editais", metodo: "POST", corpo: corpo.dados, tipoConteudo: corpo.tipoConteudo)
    }

    func enviar(link: URL) async throws -> Edital {
        let corpo = try JSONEncoder().encode(["url": link.absoluteString])
        return try await cliente.requisicao("editais", metodo: "POST", corpo: corpo, tipoConteudo: "application/json")
    }
}
