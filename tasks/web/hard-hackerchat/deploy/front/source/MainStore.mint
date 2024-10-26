record ChatsResponse {
  names : Array(String)
}

store MainStore {
  state username : Maybe(String) = Maybe::Nothing
  state isReady : Bool = false
  state chats : Array(Chat) = []

  fun setChats (value : Array(Chat)) : Promise(Void) {
    next { chats: value }
  }

  fun getChats : Promise(Void) {
    let resp =
      await Http.get("/api/user/chats")
      |> Http.send()

    let body =
      case resp {
        Result::Ok(resp) =>
          case resp.body {
            Http.ResponseBody::JSON(body) => Maybe::Just(body)

            =>
              {
                Ui.Notifications.notifyDefault(<{ "chats response is not json" }>)
                Maybe::Nothing
              }
          }

        Result::Err(err) =>
          {
            Ui.Notifications.notifyDefault(<{ "Failed to do http request for user: #{err.status}" }>)
            Maybe::Nothing
          }
      }

    let chats =
      body
      |> Maybe.map(
        (body : Object) {
          let decoded =
            decode body as ChatsResponse

          case decoded {
            Result::Ok(e) => e.names

            Result::Err(e) =>
              {
                Ui.Notifications.notifyDefault(<{ "Failed to parse chats as chats response" }>)
                []
              }
          }
        })
      |> Maybe.withDefault([])
      |> Array.map(Chat)

    next { chats: chats }
  }

  fun getUsername : Promise(Void) {
    let resp =
      await Http.get("/api/user/me")
      |> Http.send()

    let username =
      case resp {
        Result::Ok(resp) =>
          case resp.body {
            Http.ResponseBody::Text(body) =>
              if String.isNotEmpty(body) {
                Maybe::Just(body)
              } else {
                Maybe::Nothing
              }

            => Maybe::Nothing
          }

        Result::Err(err) =>
          {
            Ui.Notifications.notifyDefault(<{ "Failed to do http request for user: #{err.status}" }>)
            Maybe::Nothing
          }
      }

    username
    |> Maybe.map(onLogin)

    next { isReady: true }
  }

  fun onLogin (login : String) : Promise(Void) {
    getChats()
    next { username: Maybe::Just(login) }
  }
}
