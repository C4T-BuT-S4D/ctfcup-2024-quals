import Vapor

extension User: LosslessStringConvertible {
    var description: String {
        String(data: (try? JSONEncoder().encode(self))!, encoding: .utf8)!
    }
    
    convenience init?(_ description: String) {
        guard let data = description.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: data)
        else {
            return nil
        }
        self.init(id: user.id, login: user.login, password: user.password, admin: user.admin)
    }
}

extension User: SessionAuthenticatable {
    var sessionID: User {
        self
    }

    typealias SessionID = User
}

struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    func authenticate(sessionID: User, for request: Vapor.Request) async throws {
        request.auth.login(sessionID)
    }

    typealias User = App.User
}
