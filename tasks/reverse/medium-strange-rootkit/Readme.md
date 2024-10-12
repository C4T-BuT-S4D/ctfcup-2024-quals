# rev | strange_rootkit

## Information

Перед запуском запустите `echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope`.

Before running run `echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope`.

## Public

Provide binary: [public/strange_rootkit](public/strange_rootkit).

## TLDR

A state machine for read, write actions in binaries.

## Writeup (ru)

Бинарный файл отслеживает процесс, если у него установлена переменная окружения `TRACE_ME`. Он проверяет 4 типа событий: запись системного вызова, чтение системного вызова, env и argc. Для каждого события проверяется наличие строки, а затем выполняется переход к следующему состоянию в глобальной машине состояний. Если достигнуто конечное состояние, он выводит флаг (md5 идентификаторов состояний на пути). Мы можем выгрузить граф, пройти по нему и получить флаг.

## Writeup (en)

The binary traces a process if it has the environment variable `TRACE_ME` set. It checks for 4 types of events: syscall write, syscall read, env and argc. For each event if checks whether a string is present and then stransition to the next state in a global state machine. The if the final state is reached it prints the flag (md5 of the state ids on the path). We can dump the graph, traverse it and get the flag.

[Exploit](solve/solve.py)

## Flag

ctfcup{f7a64435cf1d916401dc480152d5e6d3}
