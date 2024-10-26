record WSMessages.Config {
  callback : Function(Message, Promise(Void))
}

provider Provider.WSMessages : WSMessages.Config {
  state conn : Maybe(WebSocket) = Maybe::Nothing

  fun openWebsocket : WebSocket {
    WebSocket.open(
      {
        onMessage: onMessage,
        onOpen: (ws : WebSocket) { next { } },
        onClose: () { Ui.Notifications.notifyDefault(<{ "Websocket connection close" }>) },
        onError:
          () {
            Ui.Notifications.notifyDefault(<{ "Websocket connection error" }>)
          },
        reconnectOnClose: false,
        url: "ws://#{Window.url().host}/ws/feed"
      })
  }

  fun update : Promise(Void) {
    if Array.isEmpty(subscriptions) {
      case conn {
        Maybe::Just(w) => WebSocket.closeWithoutReconnecting(w)
        => next { }
      }
    } else {
      next { conn: Maybe::Just(openWebsocket()) }
    }
  }

  fun onMessage (message : String) {
    let Result::Ok(object) =
      Json.parse(message) or return Ui.Notifications.notifyDefault(<{ "Failed to parse #{message} as json" }>)

    let Result::Ok(msg) =
      decode object as Message or return Ui.Notifications.notifyDefault(<{ "Failed to decode #{message} as Message" }>)

    for sub of subscriptions {
        sub.callback(msg)
    }

    next { }
  }
}
