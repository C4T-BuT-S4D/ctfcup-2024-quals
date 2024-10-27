# ppc | just bfs

## Information

Много лет назад, когда в этом здании только появились компьютерная школа с клубом и наш бар, таинственный седовласый мужчина подменил планы здания в БТИ: никто не должен был знать, что мы заняли бывший советский бункер с широкой сетью подземных проходов. Оригинал сохранился только у нас, и то в довольно специфическом виде. Если он попадет не в те руки — нам придётся несладко.

Many years ago, when this building first housed a computer school with a club and our bar, a mysterious grey-haired man changed the plans of the building in the BTI: no one was supposed to know that we occupied a former Soviet bunker with a wide network of underground passages. Only we have the original, and even then in a rather specific form. If it falls into the wrong hands, we will have a hard time.

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

Авторское решение делит картинку на множества связанных (распологающихся рядом) черных и синих клеток. Очевидно, что каждая вершина представляет собой одно или несколько множеств синих точек (при этом, если их будет несколько, то достаточно взять только достаточно большие). 
Теперь достаточно посмотреть, какие черные множества имеют соседние точки из синих множеств: каждое черное множество ялвяется ребром, если оно имеет соседние точки из двух синих множеств. Теперь прогоним ocr на обработанных квадратах, обрезанных под каждое синие множество, чтобы получить букву вершины. 
Стоит заметить, решение на питоне, скорее всего, не пройдет по времени.

## Writeup (en)

The solution is first to divide the picture into sets of connect (i.e. being next to each other) black and blue cells. Obviously each vertex is one or multiple sets of blue cells (in case of multiple just take ones that are big enough). Then each black set connectiong (i.e. having adjacent elements to) to 2 blue sets is an edges. All that is left is to ocr the processed rectangle bounded by each large enough blue set to get the vertex letter. It is worth noting that a solution in python will likely not work because of time costraints.

[Exploit](solve/src/main.rs)

## Cloudflare

Yes
