# rev | searcher

## Information

Ищем флаги.

Searching for flags.

## Public

Provide binary: [public/searcher](public/searcher).

## TLDR

Rust binary that use multiple regexes to search for flag.

## Writeup (ru)

Крекмишка на расте. Сразу же проваливаемся в функцию check_flag. Она проверяет что флаг начинается с "ctfcup{" и заканчивается на "}" и убирает эти символы. Затем она проверяет флаг подходит под несколько регулярок, вида "[abcdg]" n раз. Нетрудно догадатся что нам нужно просто посимвольно пересечь эти множества.

## Writeup (en)

Rust crackme. Go straight to the check_flag function. It first checks that flag starts with "ctfcup{" and ends with "}" and strips these symbols. Next it checks that the flag matches several regexes of the form "[abcdg]" n times. We have to intersect all sets for each symbol to obtain the flag.


[Exploit](solve/solve.py)

## Flag

ctfcup{46142aaf07754af06e6b2ec120892d58}
