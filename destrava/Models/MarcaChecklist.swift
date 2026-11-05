import Foundation
import SwiftData

@Model
final class MarcaChecklist {
    var editalId: String
    var itemId: String
    var feito: Bool
    var atualizadoEm: Date

    init(editalId: String, itemId: String, feito: Bool) {
        self.editalId = editalId
        self.itemId = itemId
        self.feito = feito
        self.atualizadoEm = .now
    }
}
