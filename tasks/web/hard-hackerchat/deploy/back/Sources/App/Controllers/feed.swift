import Vapor
import Redis

func websocketRoutes(_ app: Application, _ builder: RoutesBuilder) throws {
    builder.webSocket("feed") { req, ws async in
        do {
            let user = try req.auth.require(User.self)
            try await req.application.redis.subscribe(to: RedisChannelName(user.login)) { channel, message in
                let msg: RESPValue = message;
                let str = msg.string!;
                ws.send(str)
            }.get()
        } catch {
            req.application.logger.error("WebSocket connection error: \(error)")
            try? await ws.close()
        }
    }
}
