import Foundation

struct Edital: Codable, Identifiable, Hashable {
    let id: String
    let status: StatusEdital
    let nomeArquivo: String?
    let criadoEm: Date?
    let conteudo: ConteudoEdital?
    let erro: String?

    var titulo: String { conteudo?.documento.titulo ?? nomeArquivo ?? "Edital" }
    var tipo: TipoDocumento { conteudo?.documento.tipo ?? .outro }
}

enum StatusEdital: String, Codable, Hashable {
    case processando = "PROCESSING"
    case pronto = "READY"
    case falhou = "FAILED"
}

struct ConteudoEdital: Codable, Hashable {
    let documento: Documento
    let resumoSimples: String
    let destaques: [String]
    let exigeAcao: Bool
    let proximoPasso: ProximoPasso?
    let datas: [DataImportante]
    let atencao: [Alerta]
    let naoInformado: [String]
    let contato: Contato?
    let secoes: [Secao]
}

struct Documento: Codable, Hashable {
    let titulo: String
    let orgao: String?
    let tipo: TipoDocumento
    let finalidade: String?
}

enum TipoDocumento: String, Codable, Hashable {
    case selecao, exame, licitacao, convocacao, resultado, retificacao, judicial, outro

    init(from decoder: Decoder) throws {
        let valor = try decoder.singleValueContainer().decode(String.self)
        self = TipoDocumento(rawValue: valor) ?? .outro
    }

    var rotulo: String {
        switch self {
        case .selecao: "Seleção"
        case .exame: "Exame"
        case .licitacao: "Licitação"
        case .convocacao: "Convocação"
        case .resultado: "Resultado"
        case .retificacao: "Retificação"
        case .judicial: "Judicial"
        case .outro: "Edital"
        }
    }

    var icone: String {
        switch self {
        case .selecao: "person.crop.rectangle.stack"
        case .exame: "pencil.and.list.clipboard"
        case .licitacao: "building.columns"
        case .convocacao: "megaphone"
        case .resultado: "checkmark.seal"
        case .retificacao: "pencil.line"
        case .judicial: "scale.3d"
        case .outro: "doc.text"
        }
    }
}

struct ProximoPasso: Codable, Hashable {
    let acao: String
    let link: URL?
    let prazo: Date?
}

struct DataImportante: Codable, Hashable, Identifiable {
    let id: String
    let evento: String
    let data: Date?
    let hora: String?
    let fonte: Fonte?
}

struct Alerta: Codable, Hashable, Identifiable {
    let id: String
    let alerta: String
    let gravidade: Gravidade
    let fonte: Fonte?
}

enum Gravidade: String, Codable, Hashable {
    case alta, media

    init(from decoder: Decoder) throws {
        let valor = try decoder.singleValueContainer().decode(String.self)
        self = Gravidade(rawValue: valor) ?? .media
    }
}

struct Contato: Codable, Hashable {
    let email: String?
    let site: URL?
}

struct Fonte: Codable, Hashable {
    let trecho: String
    let pagina: Int?
    let verificada: Bool?
}

struct Secao: Codable, Hashable, Identifiable {
    let id: String
    let pergunta: String
    let bloco: TipoBloco
    let icone: String?
    let itens: [ItemSecao]
}

enum TipoBloco: String, Codable, Hashable {
    case lista, checklist, etapas, valores, tabela, texto

    init(from decoder: Decoder) throws {
        let valor = try decoder.singleValueContainer().decode(String.self)
        self = TipoBloco(rawValue: valor) ?? .lista
    }
}

struct ItemSecao: Codable, Hashable, Identifiable {
    let id: String
    let texto: String
    let detalhe: String?
    let valor: String?
    let data: Date?
    let fonte: Fonte?
}
