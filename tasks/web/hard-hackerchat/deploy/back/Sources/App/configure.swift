import Fluent
import FluentPostgresDriver
import Redis
import Vapor

func configureDatabase(_ app: Application) async throws {
    app.databases.use(
        .postgres(
            configuration: SQLPostgresConfiguration(
                hostname: Environment.get("DB_HOST") ?? "localhost",
                port: Environment.get("DB_PORT").flatMap(Int.init)
                    ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.get("DB_USER") ?? "postgres",
                password: Environment.get("DB_PASSWORD") ?? "postgres",
                database: Environment.get("DB_NAME") ?? "chats",
                tls: .disable
            )
        ),
        as: .psql
    )

    app.migrations.add(CreateUser())
    app.migrations.add(CreateChats())
    app.migrations.add(CreateUserChats())
    app.migrations.add(CreateFBI())
    try await app.autoMigrate()
}

func configureRedis(_ app: Application) async throws {
    app.redis.configuration = try RedisConfiguration(
        url: "redis://\(Environment.get("REDIS_URL") ?? "localhost:6379")")
}

func configureSessions(_ app: Application) {
    app.sessions.use(.redis)
}

// configures your application
public func configure(_ app: Application) async throws {
    try await configureRedis(app)
    try await configureDatabase(app)
    configureSessions(app)

    app.middleware.use(app.sessions.middleware)
    app.middleware.use(UserSessionAuthenticator())

    try routes(app)
}
