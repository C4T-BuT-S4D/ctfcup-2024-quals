import Vapor

struct SendMsg: Codable {
    var content: String
    var chat: String
    var from: String
    var replyTo: String
    var id: String
    var important: String
}
