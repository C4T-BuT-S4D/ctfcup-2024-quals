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

Path traversal to etcd wia URL-parameters in Golang.

## Writeup (ru)

В задании используется etcd для хранения данных. Ключи в etcd имеют иерархическую структуру (как файловая система). Ключи для etcd собираются через функцию path.Join() в Go. Данная функция нормализует путь, тем самым создавая path-traversal уязвимость.

Данные кладутся по пути `/users/<user>/data/<key>`, где мы контролируем `<user>` и `key`. При регистрации проверяется чтобы username был alphanumeric. Но мы полностью контролируем `<key>`. Тут на помощь приходит новый роутер Go, в котором `{key...}` позволит положить в key "../" если сделать urlencode. 

Итоговое решение.
1. Регистрируем пользователя.
2. Через ../ получаем пароль админа.
3. Заходим за админа и находим флаг.

## Writeup (en)

Task uses etcd to store data. Keys in etcd have a hierarchical structure (like a file system). The keys for etcd are created through the path.Join() function in Go. This function normalizes the path, thereby creating path-traversal vulnerability.

The data is stored at the path `/users/<user>/data/<key>`, where we control `<user>` and `key`. When registering, we make sure that username is alphanumeric. But we have full control over `<key>`. This is where the new Go router comes to the rescue, where `{key...}` will let you put “../” in the key if you urlencode it. 

The final solution.
1. Register a user.
2. Get the admin password via ../.
3. Log in as admin and find the flag.

[Exploit](solve/solve.py)


## Cloudflare 

No
