# ppc | Loooooooong graph

## Information

Бесполезные командировки приятны только одной вещью — можно спокойно залипать на вид из иллюминатора на ночной город. Калейдоскопы горящих улиц, строение глиальных клеток, простейшие графы — все это так похоже и по-своему прекрасно.

Useless business trips are pleasant only for one thing - you can calmly stare at the view from the porthole of the night city. Kaleidoscopes of burning streets, the structure of glial cells, the simplest graphs - all this is so similar and beautiful in its own way.

## Deploy

```sh
cd deploy
docker compose -p long_graph up --build -d
```

## Public

Provide url /graph.json

## TLDR

We are give a url that gives us a very long sparse graph in json format, evidently we have to traverse it.

## Writeup (ru)

Идея в том, что поскольку граф длинный, разряженный и отсортированный, по ID вершины мы можем воспользоватся бинпоиском с http рейнжами (которые сервер принимает), чтобы найти определенную вершину. Просто обойдем граф, используя этот прием для получения неизвестных нам матриц. Сам граф состоит из 100 вершин с хотя бы одним ребром, в одной из которых лежит флаг.

## Writeup (en)

The idea is that since the graph is long, sparse and sorted by vertex id we can use binsearch with http ranges (which the server excepts) to find a concrete vertex, then just traverse the graph, using this approach to find unseen vertices. The actual graph consists of 100 or so vertices so it takes around a minute to traverse.

[Exploit](solve/solve.py)

## Cloudflare

Yes
