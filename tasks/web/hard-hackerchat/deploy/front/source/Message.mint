module Message {
  fun renderMono (msg : String) : Html {
    <{
      String.split(msg, "`")
      |> Array.mapWithIndex(
        (elem : String, idx : Number) : Html {
          if idx % 2 == 0 {
            <{ elem }>
          } else {
            <tt>
              <{ elem }>
            </tt>
          }
        })
    }>
  }

  fun renderItalic (msg : String) : Html {
    <{
      String.split(msg, "__")
      |> Array.mapWithIndex(
        (elem : String, idx : Number) : Html {
          if idx % 2 == 0 {
            renderMono(elem)
          } else {
            <i>
              <{ elem }>
            </i>
          }
        })
    }>
  }

  fun renderBold (msg : String) : Html {
    <{
      String.split(msg, "**")
      |> Array.mapWithIndex(
        (elem : String, idx : Number) : Html {
          if idx % 2 == 0 {
            renderItalic(elem)
          } else {
            <strong>
              <{ elem }>
            </strong>
          }
        })
    }>
  }

  fun highlight (msg : String) : Html {
    let s =
      String.split(msg, "\n")

    let Maybe::Just(lang) =
      s[0] or return Html.empty()

    let code =
      String.join(Array.takeEnd(s, Array.size(s) - 1), "\n")

    if String.isEmpty(lang) {
      <Hljs code={msg}/>
    } else {
      <Hljs
        code={code}
        language={lang}/>
    }
  }

  fun renderSmart (msg : Message) : Maybe(Html) {
    let s =
      msg.content

    let splittedCode =
      String.split(s, "\n```")

    let res =
      if Array.size(splittedCode) % 2 == 0 {
        Maybe::Nothing
      } else {
        Maybe::Just(splittedCode)
      }

    res
    |> Maybe.map(
      (splitted : Array(String)) : Html {
        let a =
          splitted
          |> Array.mapWithIndex(
            (elem : String, idx : Number) : Html {
              if idx % 2 == 1 {
                highlight(elem)
              } else {
                renderBold(elem)
              }
            })

        <{ a }>
      })
  }

  fun render (msg : Message) : Html {
    let smart =
      renderSmart(msg)

    let c =
      case smart {
        Maybe::Just(s) => s
        Maybe::Nothing => <{ msg.content }>
      }

    <Ui.Box>
      <{ c }>
    </Ui.Box>
  }
}
