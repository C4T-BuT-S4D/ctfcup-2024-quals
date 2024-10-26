component Login {
  state errors : Map(String, Array(String)) = Map.empty()
  state password : String = ""
  state login : String = ""
  property onLogin : Function(String, Promise(Void))
  property switchShouldRegister : Function(Bool, Promise(Void))

  style content {
    align-content: start;
    margin-bottom: 2em;
    grid-gap: 2em;
    display: grid;
  }

  style example {
    min-height: 100vh;
    display: grid;
  }

  fun submit (event : Html.Event) {
    let errors =
      Validation.merge(
        [
          Validation.isNotBlank(login, {"login", "Please enter the login."}),
          Validation.isNotBlank(password, {"password", "Please enter the password."})
        ])

    await next { errors: errors }

    if Map.isEmpty(errors) {
      let response =
        await Http.post("/api/user/login")
        |> Http.jsonBody(
          encode {
            login: login,
            password: password
          })
        |> Http.send()

      case response {
        Result::Ok(resp) =>
          if resp.status == 200 {
            Ui.Notifications.notifyDefault(<{ "Login successful!" }>)
            onLogin(login)
          } else {
            Ui.Notifications.notifyDefault(<{ "Login failed. Please try again." }>)
            next { errors: Map.set(errors, "login", ["Invalid login or password"]) }
          }

        Result::Err(error) =>
          Ui.Notifications.notifyDefault(<{ "An error occurred. Please try again later." }>)
      }
    }
  }

  fun render : Html {
    <Ui.Layout.Centered maxContentWidth="320px">
      <Ui.Column gap={Ui.Size::Em(1.5)}>
        <Ui.Brand
          icon={Ui.Icons:BEAKER}
          name="H4ck3r Ch47"/>

        <Ui.Box title=<{ "Login" }>>
          <Ui.Column gap={Ui.Size::Em(1)}>
            <Ui.Field
              error={Validation.getFirstError(errors, "login")}
              label="login *">

              <Ui.Input
                onChange={(value : String) { next { login: value } }}
                invalid={Map.has(errors, "login")}
                placeholder="johndoe"
                value={login}
                type="login"/>

            </Ui.Field>

            <Ui.Field
              error={Validation.getFirstError(errors, "password")}
              label="Password *">

              <Ui.Input
                onChange={(value : String) { next { password: value } }}
                invalid={Map.has(errors, "password")}
                placeholder="12345678"
                value={password}
                type="password"/>

            </Ui.Field>

            <Ui.Button
              iconAfter={Ui.Icons:ARROW_RIGHT}
              onClick={submit}
              label="Continue"/>
          </Ui.Column>
        </Ui.Box>

        <Ui.Content
          textAlign="center"
          size={Ui.Size::Em(0.85)}>

          <div>
            "Forgot your password? "

            <a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">
              "Recover it here."
            </a>
          </div>

          <div>
            "Need an account? "

            <a
              onclick={
                (e : Html.Event) : Promise(Void) {
                  switchShouldRegister(true)
                }
              }
              href="#">

              "Register here."

            </a>
          </div>

        </Ui.Content>
      </Ui.Column>
    </Ui.Layout.Centered>
  }
}
