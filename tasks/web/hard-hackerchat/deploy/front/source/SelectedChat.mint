record AddGroupReq {
  user : String,
  chat : String
}

component InviteUser {
  state name : String = ""
  property chat : String

  fun render : Html {
    <Ui.Field
      orientation={Ui.Field::Vertical}
      label="Invite user to group">

      <Ui.Row>
        <Ui.Input
          placeholder={"Username"}
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
      AddGroupReq(name, chat)

    let response =
      await Http.post("/api/chat/add")
      |> Http.jsonBody(encode req)
      |> Http.send()

    case response {
      Result::Ok(e) =>
        next { name: "" }

      Result::Err(e) =>
        Ui.Notifications.notifyDefault(<{ "Failed to send message" }>)
    }
  }
}

component BottomChat {
  state msg : String = ""
  property chatName : String

  fun render : Html {
    <Ui.Row>
      <Ui.Input
        placeholder={"Type message here..."}
        value={msg}
        icon={
          <Ui.Icon icon={Ui.Icons:X}/>
        }
        iconInteractive={true}
        onIconClick={(e : Html.Event) { next { msg: "" } }}
        onChange={
          (value : String) {
            next { msg: value }
          }
        }/>

      <Ui.Button
        iconBefore={Ui.Icons:MAIL}
        onClick={(e : Html.Event) { send() }}/>
    </Ui.Row>
  }

  fun send : Promise(Void) {
    if String.isEmpty(msg) {
      next { }
    } else {
      let message =
        Message("", chatName, msg, "", "", "")

      let response =
        await Http.post("/api/chat/send")
        |> Http.jsonBody(encode message)
        |> Http.send()

      case response {
        Result::Ok(e) =>
          next { msg: "" }

        Result::Err(e) =>
          Ui.Notifications.notifyDefault(<{ "Failed to send message" }>)
      }
    }
  }
}

record Message {
  from : String,
  chat : String,
  content : String,
  replyTo : String,
  id : String,
  important : String
}

component Messages {
  property messages : Array(Message)

  fun render : Html {
    let msgs =
      messages
      |> Array.map(Message.render)
      |> Array.reverse()

    <Ui.Column>
      <{ msgs }>
    </Ui.Column>
  }
}

component SelectedChat {
  property chatName : String
  property messages : Array(Message)

  fun render : Html {
    <Ui.Layout.Website
      content={<Messages messages={messages}/>}
      footer={<InviteUser chat={chatName}/>}
      breadcrumbs={
        <BottomChat chatName={chatName}/>
      }/>
  }
}
