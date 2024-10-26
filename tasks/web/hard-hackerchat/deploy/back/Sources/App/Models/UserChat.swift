import Fluent
import Vapor

final class UserChat: Model, Content, @unchecked Sendable {
    static let schema = "user_chat"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "chat_id")
    var chat: Chat

    init() {}

    init(id: UUID? = nil, user_id: UUID?, chat_id: UUID?) throws {
        guard let user = user_id else {
            throw Abort(.internalServerError)
        }
        guard let chat = chat_id else {
            throw Abort(.internalServerError)
        }
        self.id = id
        self.$user.id = user
        self.$chat.id = chat
    }
}

struct CreateUserChats: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UserChat.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .field("chat_id", .uuid, .required, .references(Chat.schema, "id"))
            .unique(on: "chat_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(UserChat.schema).delete()
    }
}
