component MainSpinner {
  style loader {
    @keyframes rotation {
      from {
        transform: rotate(0deg);
      }

      to {
        transform: rotate(360deg);
      }
    }

    width: 48px;
    height: 48px;
    border: 5px solid #FFF;
    border-bottom-color: #FF3D00;
    border-radius: 50%;
    display: inline-block;
    box-sizing: border-box;
    animation: rotation 1s linear infinite;
  }

  fun render : Html {
    <Ui.Layout.Centered>
      <span::loader/>
    </Ui.Layout.Centered>
  }
}

routes {
  * {
    MainStore.getUsername()
  }
}

component Main {
  connect MainStore exposing { username, isReady, onLogin }

  state shouldRegister : Bool = false

  fun onRegister (login : String) : Promise(Void) {
    Ui.Notifications.notifyDefault(<{ "Register successfully. You can login now." }>)
    next { shouldRegister: false }
  }

  fun switchShouldRegister (value : Bool) : Promise(Void) {
    next { shouldRegister: value }
  }

  fun renderReady : Html {
    <Ui.Theme.Root
      fontConfiguration={Ui:DEFAULT_FONT_CONFIGURATION}
      tokens={Ui:DEFAULT_TOKENS}>

      case username {
        Maybe::Just(username) => <MainWindow username={username}/>

        Maybe::Nothing =>
          if shouldRegister {
            <Register
              onRegister={onRegister}
              switchShouldRegister={switchShouldRegister}/>
          } else {
            <Login
              onLogin={onLogin}
              switchShouldRegister={switchShouldRegister}/>
          }
      }

    </Ui.Theme.Root>
  }

  fun render : Html {
    if isReady {
      renderReady()
    } else {
      <MainSpinner/>
    }
  }
}
