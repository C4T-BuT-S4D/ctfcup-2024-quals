import Fluent
import Vapor

func findChatsForUser(on db: Database, id: UUID?) async throws -> [Chat] {
    guard let uid = id else {
        throw Abort(.internalServerError)
    }
    guard let user = try await User.query(on: db).filter(\.$id == uid).with(\.$chats).first() else {
        throw Abort(.notFound, reason: "user (\(uid)) not found")
    }
    return user.chats
}

func findUsersForChat(on db: Database, id: UUID?) async throws -> [User] {
    guard let uid = id else {
        throw Abort(.internalServerError)
    }
    guard let chat = try await Chat.query(on: db).filter(\.$id == uid).with(\.$users).first() else {
        throw Abort(.notFound, reason: "chat (\(uid)) not found")
    }
    return chat.users
}
