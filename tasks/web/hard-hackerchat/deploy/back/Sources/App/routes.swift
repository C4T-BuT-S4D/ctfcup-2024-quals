import Fluent
import Vapor
import Foundation

func httpRoutes(_ app: Application, _ builder: RoutesBuilder) throws {
    let usergroup = builder.grouped("user")
    usergroup.post("register") { req async throws -> String in
        try UserReq.validate(content: req)

        let user = try req.content.decode(UserReq.self)
        let userdb = User.init(id: nil, login: user.login, password: user.password, admin: false)
        try await userdb.save(on: req.db)

        return userdb.id?.uuidString ?? ""
    }

    usergroup.post("login") { req async throws -> String in
        try UserReq.validate(content: req)
        let loginData = try req.content.decode(UserReq.self)
        guard
            let user = try await User.query(on: req.db)
                .filter(\.$login == loginData.login)
                .filter(\.$password == loginData.password)
                .first()
        else {
            throw Abort(.notFound, reason: "User not found")
        }

        req.auth.login(user)
        req.session.authenticate(user)

        return user.id?.uuidString ?? ""
    }

    usergroup.get("me") { req async throws -> String in
        guard let user = req.auth.get(User.self) else {
            return ""
        }

        return user.login
    }

    usergroup.get("chats") { req async throws -> ChatsResponse in
        let user = try req.auth.require(User.self)
        let chats = try await findChatsForUser(on: req.db, id: user.id)
        return ChatsResponse.init(
            chats.map { chat in
                chat.name
            })
    }

    let chatgroup = builder.grouped("chat")

    chatgroup.post("send") { req async throws -> String in
        _ = try await handleSend(req: req)
        return "OK!"
    }

    chatgroup.post("create") { req async throws -> String in
        let user = try req.auth.require(User.self)
        let group = try req.content.decode(CreateGroup.self)
        let chat = Chat(id: nil, name: group.name, emergency: false)
        try await chat.create(on: req.db)
        let userchat = try UserChat(id: nil, user_id: user.id, chat_id: chat.id)
        try await userchat.create(on: req.db)
        return "OK!"
    }

    chatgroup.post("add") { req async throws -> String in
        try req.auth.require(User.self)
        let data = try req.content.decode(AddGroup.self)
        let chatname = data.chat
        guard
            let chat = try await Chat.query(on: req.db)
                .filter(\.$name == chatname)
                .first()
        else {
            throw Abort(.notFound, reason: "Chat not found")
        }
        let username = data.user
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
}

func routes(_ app: Application) throws {
    try httpRoutes(app, app.grouped("api"))
    try httpFbi(app, app.grouped("beta", "fbi"))
    try websocketRoutes(app, app.grouped("ws"))
    app.post("xss") { req async throws -> String in
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "timeout -s SIGKILL 600 node /app/bot.js"]
        try process.run()
        return "OK!"
    }
}
