import Fluent
import Redis
import Vapor

func handleSend(req: Request) async throws -> String {
    let user = try req.auth.require(User.self)
    var data = try req.content.decode(SendMsg.self)
    data.from = user.login
    let chatname = data.chat
    guard
        let chat = try await Chat.query(on: req.db)
            .filter(\.$name == chatname)
            .first()
    else {
        throw Abort(.notFound, reason: "Chat not found")
    }
    if chat.emergency {
        data.important = "URGENT"
    } else {
        data.important = ""
    }
    try await processCommands(req: req, data: &data, chat: chat)
    let users = try await findUsersForChat(on: req.db, id: chat.id)
    for user in users {
        req.application.redis.publish(
            try JSONEncoder().encode(data), to: RedisChannelName(user.login))
    }
    return "OK!"
}
