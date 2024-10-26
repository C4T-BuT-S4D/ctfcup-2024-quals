import Fluent
import Vapor

struct FBIRequest: Content, Codable {
    var chat: String
    var args: [String]
}

struct FBIAdd: Content, Codable {
    var name: String
    var method: String
    var url: String
}

final class FBI: Model, Content, @unchecked Sendable {
    static let schema = "fbi"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "method")
    var method: String

    @Field(key: "url")
    var url: String

    init() {}

    init(id: UUID? = nil, name: String, method: String, url: String) {
        self.id = id
        self.name = name
        self.method = method
        self.url = url
    }
}

struct CreateFBI: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(FBI.schema)
            .id()
            .field("name", .string, .required)
            .field("method", .string, .required)
            .field("url", .string, .required)
            .create()

        try await FBI(id: nil, name: "call", method: "PUT", url: "/beta/fbi/user").create(
            on: database)
        try await FBI(id: nil, name: "kick", method: "DELETE", url: "/beta/fbi/user").create(
            on: database)
    }

    func revert(on database: Database) async throws {
        try await database.schema(FBI.schema).delete()
    }
}
