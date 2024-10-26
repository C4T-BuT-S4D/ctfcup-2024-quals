import Fluent
import Vapor

func httpFbi(_ app: Application, _ builder: RoutesBuilder) throws {
    builder.post("rule") { req async throws -> String in
        let user = try req.auth.require(User.self)
        if !user.admin {
            throw Abort(.forbidden, reason: "only admin can access beta")
        }
        let content = try req.content.decode(FBIAdd.self)
        let fbi = FBI.init(id: nil, name: content.name, method: content.method, url: content.url)
        try await fbi.save(on: req.db)
        return "OK!"
    }
    builder.put("user") { req async throws -> String in
        let content = try req.content.decode(FBIRequest.self)
        if content.args.count != 1 {
            throw Abort(.badRequest, reason: "expected exacly 1 argument")
        }

        let chatname = content.chat
        guard
            let chat = try await Chat.query(on: req.db)
                .filter(\.$name == chatname)
                .first()
        else {
            throw Abort(.notFound, reason: "Chat not found")
        }
        let username = content.args[0]
        guard
            let user = try await User.query(on: req.db)
                .filter(\.$login == username)
                .first()
        else {
            throw Abort(.notFound, reason: "User not found")
        }
        let userchat = try UserChat(id: nil, user_id: user.id, chat_id: chat.id)
        try await userchat.create(on: req.db)
        return "OK!"
    }
    builder.delete("user") { req async throws -> String in
        let content = try req.content.decode(FBIRequest.self)
        if content.args.count != 1 {
            throw Abort(.badRequest, reason: "expected exacly 1 argument")
        }

        let chatname = content.chat
        guard
            let chat = try await Chat.query(on: req.db)
                .filter(\.$name == chatname)
                .first()
        else {
            throw Abort(.notFound, reason: "Chat not found")
        }
        let username = content.args[0]
        guard
            let user = try await User.query(on: req.db)
                .filter(\.$login == username)
                .first()
        else {
            throw Abort(.notFound, reason: "User not found")
        }
        guard let user_id = user.id else { throw Abort(.internalServerError) }
        guard let chat_id = chat.id else { throw Abort(.internalServerError) }
        guard
            let userchat = try await UserChat.query(on: req.db)
                .filter(\.$user.$id == user_id)
                .filter(\.$chat.$id == chat_id)
                .first()
        else { throw Abort(.notFound, reason: "User not found in this chat") }
        try await userchat.delete(force: true, on: req.db)
        return "Ok!"
    }
}
