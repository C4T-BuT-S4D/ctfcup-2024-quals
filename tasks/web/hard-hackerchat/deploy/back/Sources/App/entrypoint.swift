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
        try await app.execute()
        try await app.asyncShutdown()
    }
}
