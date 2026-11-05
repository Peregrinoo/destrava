import Foundation

extension Locale {
    static let ptBR = Locale(identifier: "pt_BR")
}

extension Date {
    var curta: String {
        formatted(.dateTime.day().month(.abbreviated).locale(.ptBR))
    }

    func dias(ate outra: Date) -> Int {
        let calendario = Calendar.current
        return calendario.dateComponents([.day], from: calendario.startOfDay(for: self),
                                         to: calendario.startOfDay(for: outra)).day ?? 0
    }

    static func dia(_ ano: Int, _ mes: Int, _ dia: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: ano, month: mes, day: dia)) ?? .now
    }
}

extension String {
    var primeiraMaiuscula: String { prefix(1).uppercased() + dropFirst() }
}

func mensagem(de erro: Error) -> String {
    (erro as? LocalizedError)?.errorDescription ?? "Algo deu errado. Tente de novo."
}
