import Foundation
import Observation

enum SituacaoCarregamento: Equatable {
    case ocioso
    case carregando
    case pronto
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
    private(set) var editais: [Edital] = []
    private(set) var situacao: SituacaoCarregamento = .ocioso

    @ObservationIgnored private let servico: any EditalService
    @ObservationIgnored private let intervaloAcompanhamento: Duration
    @ObservationIgnored private var carregamento: Task<Void, Never>?
    @ObservationIgnored private var acompanhamento: Task<Void, Never>?

    init(servico: any EditalService, intervaloAcompanhamento: Duration = .seconds(2)) {
        self.servico = servico
        self.intervaloAcompanhamento = intervaloAcompanhamento
    }

    func edital(id: String) -> Edital? {
        editais.first { $0.id == id }
    }

    func carregar() async {
        if let carregamento {
            await carregamento.value
            return
        }
        let tarefa = Task { await buscarLista() }
        carregamento = tarefa
        await tarefa.value
        carregamento = nil
    }

    func atualizar(id: String) async throws {
        salvar(try await servico.buscar(id: id))
    }

    func enviar(pdf: URL) async throws -> Edital {
        let edital = try await servico.enviar(pdf: pdf)
        salvar(edital)
        return edital
    }

    func enviar(link: URL) async throws -> Edital {
        let edital = try await servico.enviar(link: link)
        salvar(edital)
        return edital
    }

    private func buscarLista() async {
        if editais.isEmpty { situacao = .carregando }
        do {
            editais = try await servico.listar()
            situacao = .pronto
            acompanharPendentes()
        } catch is CancellationError {
            if editais.isEmpty { situacao = .ocioso }
        } catch {
            situacao = editais.isEmpty ? .falhou(mensagem(de: error)) : .pronto
        }
    }

    private func salvar(_ edital: Edital) {
        substituir(edital)
        situacao = .pronto
        acompanharPendentes()
    }

    private func substituir(_ edital: Edital) {
        if let indice = editais.firstIndex(where: { $0.id == edital.id }) {
            editais[indice] = edital
        } else {
            editais.insert(edital, at: 0)
        }
    }

    private var pendentes: [String] {
        editais.filter { $0.status == .processando }.map(\.id)
    }

    private func acompanharPendentes() {
        guard acompanhamento == nil, !pendentes.isEmpty else { return }
        acompanhamento = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, !self.pendentes.isEmpty else { break }
                let intervalo = self.intervaloAcompanhamento
                let ids = self.pendentes
                try? await Task.sleep(for: intervalo)
                for id in ids {
                    if let edital = try? await self.servico.buscar(id: id) {
                        self.substituir(edital)
                    }
                }
            }
            self?.acompanhamento = nil
            self?.acompanharPendentes()
        }
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
                    return DataAgendada(id: "\(edital.id)-\(item.id)", evento: item.evento, data: data,
                                        editalId: edital.id, editalTitulo: edital.titulo)
                }
            }
            .sorted { $0.data < $1.data }
    }
}
