# pwn | olymp

## Information

Ой, Софи до сих пор хранит наше фото с первой олимпиады! Помню, сзади была ссылка на мой код... Минуточку, я и правда это написал?

Oh, Sophie still has our photo from the first Olympics! I remember there was a link to my code on the back... Wait a minute, did I really write that?

## Deploy

```sh
cd deploy
docker compose -p olymp up --build -d
```

## Public

Provide zip archive: [public/olymp.zip](public/olymp.zip).

## TLDR

Overflow of polymial prefix hash.

## Writeup (ru)

На bss есть очевидное переполнение, но мы переполняем префиксный хэш. Используем технику lll, чтобы подделать полимиальный хэш, равный setvbuf plt, затем перепишем cin>>(int) с помощью puts, что приведет к утечке libstdc++ и, следовательно, libc. Затем перепишем memcmp, используемый в сравнении строк, в system и вытащите оболочку.

## Writeup (en)

There is a obvious overflow on bss, but we are overflowing a prefix hash. Use the lll technique to forge a polymial hash equal to setvbuf plt, then overwrite cin>>(int) with puts, leaking libstdc++ and therefore libc. Next overwrite memcmp used in string comparison to system and pop a shell.

[Exploit](solve/sploit.py)


## Cloudflare

No
