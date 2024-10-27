# pwn | pointless

## Information

Если уж Аль Капоне попался на налогах, то представьте, что творится в бухгалтерии хакерского бара! Надеюсь, за нами шпионит не налоговая, но навести порядок в записях в любом случае не помешает.

If Al Capone got caught for tax evasion, imagine what's going on in the accounting department of a hacker bar! I hope it's not the IRS spying on us, but it wouldn't hurt to get our records in order anyway.

## Deploy

```sh
cd deploy
docker compose -p pointless up --build -d
```

## Public

Provide zip archive: [public/pointless.zip](public/pointless.zip).

## TLDR

Simple pwn where we can inject into scanf.

## Writeup (ru)

1. Видим, что защита PIE отключена, а частичная защита RELRO позволяет изменять таблицу GOT.
2. Используем уязвимость `sscanf`, чтобы изменить работу программы через указатели на стеке, как в технике с `printf`.
3. Сначала заменяем `sscanf` в таблице GOT на `printf`, чтобы программа выводила адреса нужных нам функций.
4. С помощью `printf` выводим лик `libc`.
5. Заменяем `sscanf` на `system`, чтобы выполнить команды на системе.

## Writeup (en)

We can inject our payload into a sscanf formt, no pie, partial relro, therefore first using a technique similar to printf exploitation insert 8 `%s` formats pointing at our pointers on the stack and overwrite sscanf plt to printf got this way. Now its easy leak libc with printf and ovewrite plt sscanf to system.


[Exploit](solve/sploit.py)


## Cloudflare

No
