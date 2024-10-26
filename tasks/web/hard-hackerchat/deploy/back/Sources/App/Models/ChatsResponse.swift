import Vapor

final class ChatsResponse: Content, Codable, @unchecked Sendable {
    var names: [String]

    init() {
        self.names = []
    }
    init(_ names: [String]) {
        self.names = names
    }
}
