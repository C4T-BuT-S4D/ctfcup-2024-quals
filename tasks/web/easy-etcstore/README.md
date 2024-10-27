# web | etcstore

## Information

Моя прелесть, моя гордость, мое совершенство! Хранилище заметок по секретному проекту по переносу сознания в мета-миры... Надеюсь, никто до него не добрался.

My darling, my pride, my perfection! A repository of notes on a secret project to transfer consciousness into meta-worlds... I hope no one got to it.

## Deploy

Деплой на команду, но в худшем случае:

```sh
cd deploy
docker compose -p etcstore up --build -d
```

## Public

Provide archive: [public/etcstore.tar.gz](public/etcstore.tar.gz).

## TLDR

~~Path traversal to etcd wia URL-parameters in Golang.~~

Default JWT key.

## Writeup (ru)

На сервере использовался стандартный JWT-ключ. В связи с этим можно просто получить токен админа и получить флаг.

## Writeup (en)

You can use default JWT key to get the admin token and get the flag.


[Exploit](solve/solve_jwt.py)


## Cloudflare 

Yes (need to test)
