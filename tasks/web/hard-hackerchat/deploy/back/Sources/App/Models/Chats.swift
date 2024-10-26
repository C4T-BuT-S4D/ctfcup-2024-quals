import Fluent
import Vapor

final class Chat: Model, Content, @unchecked Sendable {
    static let schema = "chats"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    // alpha, for FBI, OPEN UP cases
    @Field(key: "emergency")
    var emergency: Bool

    @Siblings(through: UserChat.self, from: \.$chat, to: \.$user)
    var users: [User]

    init() {}

    init(id: UUID? = nil, name: String, emergency: Bool) {
        self.id = id
        self.name = name
        self.emergency = emergency
    }
}

struct CreateChats: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Chat.schema)
            .id()
            .field("name", .string, .required)
            .field("emergency", .bool, .required)
            .unique(on: "name")
            .create()
        try await Chat(id: nil, name: "__test_emergency_chat", emergency: true)
            .create(on: database)
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Chat.schema).delete()
    }
}
