import Vapor
import Logging
import NIOCore
import NIOPosix

@main
struct Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)
        app.http.server.configuration.hostname = "0.0.0.0"

        let executorTakeoverSuccess = NIOSingletons.unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
        app.logger.debug("Tried to install SwiftNIO's EventLoopGroup as Swift's global concurrency executor", metadata: ["success": .stringConvertible(executorTakeoverSuccess)])

        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }

        try? await app.asyncBoot()
        let flag = Environment.get("FLAG") ?? "ctfcup{example}"
        try await app.redis.set("flag", to: flag).get()
        // hIiBBm1J2XyGw9IDy9CVXpOT23ff7I8Ml5v+8qTVc94=
        try await app.redis.set("vrs-hIiBBm1J2XyGw9IDy9CVXpOT23ff7I8Ml5v+8qTVc94=", to: "{\"_UserSession\":\"{\\\"id\\\":\\\"E27702D7-368A-40CE-AF8E-3788424FF646\\\",\\\"admin\\\":true,\\\"login\\\":\\\"admin\\\",\\\"password\\\":\\\"537d52b068bedbb77f2c8a267b5c\\\"}\"}").get()
        try await app.execute()
        try await app.asyncShutdown()
    }
}
