# ppc | just bfs

## Information

Простая олимпиадная задача, запустите бфс.

Simple olympic problem, just run bfs.

## Deploy

```sh
cd deploy
docker compose -p just_bfs up --build -d
```

## Public

Provide zip archive.

## TLDR

We need to ocr a simple graph.

## Writeup (ru)

Авторское решение делит картинку на множества связанных (распологающихся рядом) черных и синих клеток. Очевидно что каждая вершина представляет собой одно или несколько множеств синих точек (при этом если их будет несколько то достаточно взять только достаточно большие). Теперь достаточно посмотреть какие черные множества имеют соседние точки из синих множеств: каждое черное множество ялвяется ребром если оно имеет соседние точки из двух синих множеств. Теперь прогонил ocr на обработанные квадратах обрезанных под каждое синие множество чтобы получить букву вершины. Стоит заметить решение на питоне скорее всего не пройдет по времени.

## Writeup (en)

The solution is first to divide the picture into sets of connect (i.e. being next to each other) black and blue cells. Obviously each vertex is one or multiple sets of blue cells (in case of multiple just take ones that are big enough). Then each black set connectiong (i.e. having adjacent elements to) to 2 blue sets is an edges. All that is left is to ocr the processed rectangle bounded by each large enough blue set to get the vertex letter. It is worth noting that a solution in python will likely not work because of time costraints.

[Exploit](solve/src/main.rs)

## Cloudflare

Yes
