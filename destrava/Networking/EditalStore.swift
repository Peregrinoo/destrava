import Foundation
import Observation

enum Carregamento<Valor> {
    case ocioso
    case carregando
    case carregado(Valor)
    case falhou(String)
}

struct DataAgendada: Identifiable, Hashable {
    let id: String
    let evento: String
    let data: Date
    let editalId: String
    let editalTitulo: String
}

@MainActor
@Observable
final class EditalStore {
    private(set) var estado: Carregamento<[Edital]> = .ocioso
    private let servico: any EditalService

    init(servico: any EditalService) {
        self.servico = servico
    }

    var editais: [Edital] {
        if case .carregado(let lista) = estado { return lista }
        return []
    }

    func carregar() async {
        if editais.isEmpty { estado = .carregando }
        do {
            estado = .carregado(try await servico.listar())
        } catch is CancellationError {
            return
        } catch {
            if editais.isEmpty { estado = .falhou(mensagem(de: error)) }
        }
    }

    func enviar(pdf: URL) async throws -> Edital {
        let edital = try await servico.enviar(pdf: pdf)
        salvarNaLista(edital)
        return edital
    }

    func enviar(link: URL) async throws -> Edital {
        let edital = try await servico.enviar(link: link)
        salvarNaLista(edital)
        return edital
    }

    func buscar(id: String) async throws -> Edital {
        let edital = try await servico.buscar(id: id)
        salvarNaLista(edital)
        return edital
    }

    private func salvarNaLista(_ edital: Edital) {
        var lista = editais
        if let indice = lista.firstIndex(where: { $0.id == edital.id }) {
            lista[indice] = edital
        } else {
            lista.insert(edital, at: 0)
        }
        estado = .carregado(lista)
    }

    var proximoPrazo: (edital: Edital, passo: ProximoPasso, data: Date)? {
        let hoje = Calendar.current.startOfDay(for: .now)
        return editais
            .compactMap { edital -> (edital: Edital, passo: ProximoPasso, data: Date)? in
                guard let conteudo = edital.conteudo, conteudo.exigeAcao,
                      let passo = conteudo.proximoPasso, let data = passo.prazo, data >= hoje
                else { return nil }
                return (edital, passo, data)
            }
            .min { $0.data < $1.data }
    }

    var proximasDatas: [DataAgendada] {
        let hoje = Calendar.current.startOfDay(for: .now)
        return editais
            .flatMap { edital in
                (edital.conteudo?.datas ?? []).compactMap { item -> DataAgendada? in
                    guard let data = item.data, data >= hoje else { return nil }
                    return DataAgendada(id: edital.id + item.id, evento: item.evento, data: data,
                                        editalId: edital.id, editalTitulo: edital.titulo)
                }
            }
            .sorted { $0.data < $1.data }
    }
}
