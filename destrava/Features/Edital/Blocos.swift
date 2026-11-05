import SwiftData
import SwiftUI
import UIKit

struct BlocoSecao: View {
    let editalId: String
    let secao: Secao
    let aoAbrirFonte: (TrechoFonte) -> Void

    var body: some View {
        switch secao.bloco {
        case .checklist:
            BlocoChecklist(editalId: editalId, secao: secao, aoAbrirFonte: aoAbrirFonte)
        case .etapas:
            BlocoEtapas(secao: secao, aoAbrirFonte: aoAbrirFonte)
        case .valores:
            BlocoValores(secao: secao, aoAbrirFonte: aoAbrirFonte)
        case .lista, .tabela, .texto:
            BlocoLista(secao: secao, aoAbrirFonte: aoAbrirFonte)
        }
    }
}

extension Secao {
    var iconeSeguro: String {
        if let icone, UIImage(systemName: icone) != nil { return icone }
        return "doc.text"
    }
}

struct BlocoLista: View {
    let secao: Secao
    let aoAbrirFonte: (TrechoFonte) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CabecalhoSecao(secao.pergunta, icone: secao.iconeSeguro)
            ForEach(secao.itens) { item in
                HStack(alignment: .top, spacing: 10) {
                    if secao.bloco != .texto {
                        Circle()
                            .fill(Paleta.destaque)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                            .accessibilityHidden(true)
                    }
                    LinhaComFonte(texto: item.texto, detalhe: item.detalhe, fonte: item.fonte, aoAbrirFonte: aoAbrirFonte)
                }
            }
        }
        .cartao()
    }
}

struct BlocoEtapas: View {
    let secao: Secao
    let aoAbrirFonte: (TrechoFonte) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CabecalhoSecao(secao.pergunta, icone: secao.iconeSeguro)
            ForEach(Array(secao.itens.enumerated()), id: \.element.id) { indice, item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(indice + 1)")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Paleta.destaque)
                        .frame(width: 28, height: 28)
                        .background(Paleta.destaqueSuave, in: .circle)
                        .accessibilityLabel("Etapa \(indice + 1)")
                    LinhaComFonte(texto: item.texto, detalhe: item.detalhe, fonte: item.fonte, aoAbrirFonte: aoAbrirFonte)
                }
            }
        }
        .cartao()
    }
}

struct BlocoValores: View {
    let secao: Secao
    let aoAbrirFonte: (TrechoFonte) -> Void

    private let colunas = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CabecalhoSecao(secao.pergunta, icone: secao.iconeSeguro)
            LazyVGrid(columns: colunas, alignment: .leading, spacing: 10) {
                ForEach(secao.itens) { item in
                    bloco(item)
                }
            }
        }
        .cartao()
    }

    @ViewBuilder
    private func bloco(_ item: ItemSecao) -> some View {
        let conteudo = VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.valor ?? "—")
                    .font(.title3.weight(.heavy))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let fonte = item.fonte { MarcadorFonte(fonte: fonte) }
            }
            Text(item.texto)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .background(Paleta.neutro, in: .rect(cornerRadius: 18, style: .continuous))

        if let fonte = item.fonte {
            Button {
                aoAbrirFonte(TrechoFonte(afirmacao: "\(item.valor ?? "") \(item.texto)", fonte: fonte))
            } label: {
                conteudo
            }
            .buttonStyle(.plain)
        } else {
            conteudo
        }
    }
}

struct BlocoChecklist: View {
    let editalId: String
    let secao: Secao
    let aoAbrirFonte: (TrechoFonte) -> Void

    @Environment(\.modelContext) private var contexto
    @Query private var marcas: [MarcaChecklist]

    init(editalId: String, secao: Secao, aoAbrirFonte: @escaping (TrechoFonte) -> Void) {
        self.editalId = editalId
        self.secao = secao
        self.aoAbrirFonte = aoAbrirFonte
        _marcas = Query(filter: #Predicate<MarcaChecklist> { $0.editalId == editalId })
    }

    private func feito(_ item: ItemSecao) -> Bool {
        marcas.contains { $0.itemId == item.id && $0.feito }
    }

    private var concluidos: Int { secao.itens.filter(feito).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CabecalhoSecao(secao.pergunta, icone: secao.iconeSeguro) {
                Text("\(concluidos) de \(secao.itens.count)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Paleta.destaque)
                    .contentTransition(.numericText())
            }

            ProgressView(value: Double(concluidos), total: Double(max(secao.itens.count, 1)))
                .tint(Paleta.destaque)
                .padding(.bottom, 4)

            ForEach(secao.itens) { item in
                HStack(spacing: 8) {
                    Button { alternar(item) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: feito(item) ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(feito(item) ? AnyShapeStyle(Paleta.destaque) : AnyShapeStyle(.tertiary))
                                .contentTransition(.symbolEffect(.replace))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.texto)
                                    .foregroundStyle(feito(item) ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                                    .multilineTextAlignment(.leading)
                                if let detalhe = item.detalhe {
                                    Text(detalhe)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(feito(item) ? .isSelected : [])

                    if let fonte = item.fonte {
                        Button {
                            aoAbrirFonte(TrechoFonte(afirmacao: item.texto, fonte: fonte))
                        } label: {
                            MarcadorFonte(fonte: fonte)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cartao()
        .sensoryFeedback(.selection, trigger: concluidos)
    }

    private func alternar(_ item: ItemSecao) {
        withAnimation(.snappy) {
            if let marca = marcas.first(where: { $0.itemId == item.id }) {
                marca.feito.toggle()
                marca.atualizadoEm = .now
            } else {
                contexto.insert(MarcaChecklist(editalId: editalId, itemId: item.id, feito: true))
            }
        }
    }
}
