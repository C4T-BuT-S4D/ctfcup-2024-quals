# rev | searcher

## Information

О нет, кажется мои прошлогодние школьники были довольно умны. Это была одна из самых первых домашек на курсе по реверсу, а я не могу решить ее взглядом...

Oh no, it seems my students from last year were quite smart. This was one of the very first homework assignments in the reverse course, and I can't solve it with my eyes...

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
