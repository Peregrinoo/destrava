import Foundation

enum APIError: LocalizedError {
    case semConexao
    case respostaInvalida
    case servidor(status: Int)
    case recusado(String)
    case decodificacao

    var errorDescription: String? {
        switch self {
        case .semConexao: "Sem conexão com o servidor. Confira sua internet."
        case .respostaInvalida: "O servidor respondeu de um jeito inesperado."
        case .servidor(let status) where status == 404: "Não encontramos esse edital."
        case .servidor(let status) where status == 401: "Sua sessão expirou. Entre de novo."
        case .servidor: "O servidor teve um problema. Tente de novo em instantes."
        case .decodificacao: "Não conseguimos entender a resposta do servidor."
        case .recusado(let mensagem): mensagem
        }
    }
}

@MainActor
final class APIClient {
    let urlBase: URL
    var token: String?
    private let sessao: URLSession

    init(urlBase: URL, sessao: URLSession = .shared) {
        self.urlBase = urlBase
        self.sessao = sessao
    }

    func requisicao<Resposta: Decodable>(
        _ caminho: String,
        metodo: String = "GET",
        corpo: Data? = nil,
        tipoConteudo: String? = nil
    ) async throws -> Resposta {
        var req = URLRequest(url: urlBase.appending(path: caminho))
        req.httpMethod = metodo
        req.httpBody = corpo
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let tipoConteudo { req.setValue(tipoConteudo, forHTTPHeaderField: "Content-Type") }
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let dados: Data
        let resposta: URLResponse
        do {
            (dados, resposta) = try await sessao.data(for: req)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.semConexao
        }

        guard let http = resposta as? HTTPURLResponse else { throw APIError.respostaInvalida }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 400, let mensagem = Self.mensagemDeErro(em: dados) {
                throw APIError.recusado(mensagem)
            }
            throw APIError.servidor(status: http.statusCode)
        }

        do {
            return try Self.decodificador.decode(Resposta.self, from: dados)
        } catch {
            throw APIError.decodificacao
        }
    }

    private static func mensagemDeErro(em dados: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: dados) as? [String: Any] else { return nil }
        if let mensagem = json["message"] as? String { return mensagem }
        if let mensagens = json["message"] as? [String] { return mensagens.first }
        return nil
    }

    static let decodificador: JSONDecoder = {
        let decodificador = JSONDecoder()
        decodificador.keyDecodingStrategy = .convertFromSnakeCase
        decodificador.dateDecodingStrategy = .custom { decoder in
            let texto = try decoder.singleValueContainer().decode(String.self)
            if let data = try? Date(texto, strategy: .iso8601) { return data }
            if let data = try? Date(texto, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) { return data }
            if let data = try? Date(texto, strategy: Date.ISO8601FormatStyle(timeZone: .current).year().month().day()) { return data }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Data inválida: \(texto)"))
        }
        return decodificador
    }()
}

struct CorpoMultipart {
    let limite = "Destrava-\(UUID().uuidString)"
    private(set) var dados = Data()

    var tipoConteudo: String { "multipart/form-data; boundary=\(limite)" }

    mutating func adicionarArquivo(campo: String, nome: String, tipo: String, conteudo: Data) {
        dados.append(Data("--\(limite)\r\n".utf8))
        dados.append(Data("Content-Disposition: form-data; name=\"\(campo)\"; filename=\"\(nome)\"\r\n".utf8))
        dados.append(Data("Content-Type: \(tipo)\r\n\r\n".utf8))
        dados.append(conteudo)
        dados.append(Data("\r\n".utf8))
    }

    mutating func finalizar() {
        dados.append(Data("--\(limite)--\r\n".utf8))
    }
}
