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

Мы можем вставить в формат sscanf-а, нет pie, паршиал relro, поэтому сначала вставим формат считывания строчки ссылаясь на наши указатели на стеке (как в технике с printf), перепишем plt sscanf на printf гот, чтобы в следующий раз на нашей строчке вызвался printf. Теперь все просто: ликаем либси и переписываем plt sscanf на system.

## Writeup (en)

We can inject our payload into a sscanf formt, no pie, partial relro, therefore first using a technique similar to printf exploitation insert 8 `%s` formats pointing at our pointers on the stack and overwrite sscanf plt to printf got this way. Now its easy leak libc with printf and ovewrite plt sscanf to system.


[Exploit](solve/sploit.py)


## Cloudflare

No
