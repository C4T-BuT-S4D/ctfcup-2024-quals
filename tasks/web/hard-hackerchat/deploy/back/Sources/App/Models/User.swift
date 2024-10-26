import Fluent
import Vapor

struct UserReq: Codable {
    var login: String
    var password: String
}

extension UserReq: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("login", as: String.self, is: .alphanumeric)
    }
}

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "login")
    var login: String

    @Field(key: "password")
    var password: String

    @Field(key: "admin")
    var admin: Bool

    @Siblings(through: UserChat.self, from: \.$user, to: \.$chat)
    var chats: [Chat]

    init() {}

    init(id: UUID? = nil, login: String, password: String, admin: Bool) {
        self.id = id
        self.login = login
        self.password = password
        self.admin = admin
    }
}

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("login", .string, .required)
            .field("password", .string, .required)
            .field("admin", .bool, .required)
            .unique(on: "login")
            .ignoreExisting()
            .create()
        guard let adminpwd = Environment.get("ADMIN_PASSWORD") else {
            throw Abort(.internalServerError)
        }
        try await User.init(login: "admin", password: adminpwd, admin: true).create(on: database)
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
