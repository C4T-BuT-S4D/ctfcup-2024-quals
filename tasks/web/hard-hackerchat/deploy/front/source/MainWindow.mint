record Chat {
  name : String
}

record CreateGroupReq {
  name : String
}

component AddGroup {
  state name : String = ""
  property callback : Function(String, Promise(Void))

  fun render : Html {
    <Ui.Field
      orientation={Ui.Field::Vertical}
      label="Add group">

      <Ui.Row>
        <Ui.Input
          placeholder={"Group name"}
          value={name}
          icon={<Ui.Icon icon={Ui.Icons:X}/>}
          iconInteractive={true}
          onIconClick={(e : Html.Event) { next { name: "" } }}
          onChange={
            (value : String) {
              next { name: value }
            }
          }/>

        <Ui.Button
          iconBefore={Ui.Icons:MAIL}
          onClick={(e : Html.Event) { send() }}/>
      </Ui.Row>

    </Ui.Field>
  }

  fun send : Promise(Void) {
    let req =
      CreateGroupReq(name)

    let response =
      await Http.post("/api/chat/create")
      |> Http.jsonBody(encode req)
      |> Http.send()

    case response {
      Result::Ok(e) =>
        {
          callback(name)
          next { name: "" }
        }

      Result::Err(e) =>
        Ui.Notifications.notifyDefault(<{ "Failed to send message" }>)
    }
  }
}

component MainWindow {
  connect MainStore exposing { chats, setChats }

  property username : String

  state selectedChat : Maybe(Number) = Maybe::Nothing

  state messages : Map(String, Array(Message)) = Map.empty()

  fun addChat (name : String) : Promise(Void) {
    setChats(Array.append(chats, [Chat(name)]))
  }

  use Provider.WSMessages { callback: processMessage }

  fun processMessage (msg : Message) : Promise(Void) {
    let chats =
      if Array.contains(chats, Chat(msg.chat)) {
        chats
      } else {
        Array.append(chats, [Chat(msg.chat)])
      }

    let messages =
      Map.set(messages, msg.chat, Array.append(Map.getWithDefault(messages, msg.chat, []), [msg]))

    setChats(chats)

    let sc =
      if msg.important == "URGENT" {
        Ui.Notifications.notifyDefault(<{ "🚨🚨🚨 ALARM 🚨🚨🚨" }>)
        Array.indexOf(chats, Chat(msg.chat))
      } else {
        selectedChat
      }

    next
      {
        messages: messages,
        selectedChat: sc
      }
  }

  fun render : Html {
    let chatsList =
      chats
      |> Array.mapWithIndex(
        (chat : Chat, i : Number) : Ui.NavItem {
          let iconBefore =
            if selectedChat == Maybe::Just(i) {
              <Ui.Icon icon={Ui.Icons:PLAY}/>
            } else {
              Html.empty()
            }

          Ui.NavItem::Item(
            action: (event : Html.Event) { next { selectedChat: Maybe::Just(i) } },
            iconBefore: iconBefore,
            iconAfter: Html.empty(),
            label: chat.name)
        })

    let menu =
      Array.append(
        [
          Ui.NavItem::Html(<AddGroup callback={addChat}/>),
          Ui.NavItem::Divider
        ],
        chatsList)

    <Ui.Layout.Documentation
      items={menu}
      mobileNavigationLabel=<{ "Chats" }>>

      case selectedChat {
        Maybe::Just(i) =>
          {
            let Maybe::Just(c) =
              chats[i] or return Html.empty()

            let chatName =
              c.name

            let m =
              Map.getWithDefault(messages, chatName, [])

            <SelectedChat
              chatName={
                chatName
              }
              messages={
                m
              }/>
          }

        Maybe::Nothing => Html.empty()
      }

    </Ui.Layout.Documentation>
  }
}
