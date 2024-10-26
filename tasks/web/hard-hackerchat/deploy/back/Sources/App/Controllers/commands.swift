import Vapor
import Fluent

struct Command {
    var name: String
    var args: [String]
}

func parseCommand(_ data: String) -> Command? {
    if data.isEmpty {
        return nil
    }
    if data[data.startIndex] != "/" {
        return nil
    }
    let components = data.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter {
        !$0.isEmpty
    }
    guard let firstComponent = components.first else {
        return nil
    }
    return Command(name: firstComponent, args: Array(components.dropFirst()))
}

func handleUser(req: Request, args: [String], chat: Chat, data: inout SendMsg) async throws {
    if args.isEmpty {
        return
    }
    let cmd  = args[0]
    let args = args.dropFirst()
    guard let cmd = try await FBI.query(on: req.db).filter(\.$name == cmd).first() else {
        data.content = "ALARM!!! \(data.from) used unknown user command \(cmd)"
        return
    }

    let callargs = FBIRequest(chat: chat.name, args: Array(args))
    let url = Environment.get("BETA_FBI_URl") ?? "http://localhost"
    let resp = try await req.client.send(HTTPMethod(rawValue: cmd.method), to: "\(url)\(cmd.url)", beforeSend: { req in
        try req.content.encode(callargs)
    })
    if resp.status.code > 299 {
        data.content = "ALARM!!! \(data.from) used command \(cmd) that failed with status \(resp.status)"
    }
}

func processEmergency(req: Request, data: inout SendMsg, chat: Chat) async throws {
    guard let cmd = parseCommand(data.content) else { return }
    switch cmd.name {
        case "/user":
            try await handleUser(req: req, args: cmd.args, chat: chat, data: &data)
        default:
            data.content = "ALARM!!! \(data.from) used unknown command \(cmd.name)"
    }
}

func processCommands(req: Request, data: inout SendMsg, chat: Chat) async throws {
    if chat.emergency {
        try await processEmergency(req: req, data: &data, chat: chat)
    } else {
        guard let cmd = parseCommand(data.content) else { return }
        switch cmd.name {
            case "hi":
                data.content = "👋😄 \(data.from) says hi to \(cmd.args.joined(by: ", "))"
            case "game":
                data.content = "🎮🤗 \(data.from) wants to play \(cmd.args.joined(by: ", "))"
            case "happy":
                data.content = "😂✨ \(data.from) is happy!!! \(cmd.args.joined(by: ", "))"
            case "sad":
                data.content = "🎮🤗 \(data.from) id upset by \(cmd.args.joined(by: ", "))"
            case "love":
                data.content = "🎮🤗 \(data.from) loves \(cmd.args.joined(by: ", "))"
            default:
                data.content = "\(data.from) used unknown command \(cmd.name)"
        }
    }
}
