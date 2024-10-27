# crypto | Annihilatornaya pushka

## Information

> В баре к вам подходит незнакомец и предлагает купить некую "аннигиляторную пушка". Стоит ли соглашаться? Вы берете ее на тест-драйв. Сможете ли вы выведать ее секреты?

> A stranger comes up to you in a bar and offers to buy some kind of "annihilator cannon". Should I agree? You take it for a test drive. Will you be able to find out her secrets?

## Public

Provide public/ directory content.

## TLDR

Invert `t(x) = (148*x + 337)*x mod 2^80` function, find first hint from the end and then recover chunk by chunk.

## Writeup (ru)

Для начала надо подумать: можно ли инвертировать функцию `t = lambda x: (148*x + 337)*x % (2**80)`? Да, это делается последовательным взятием `mod 2, `mod 2^2, ...`, восстанавливая бит за битом.

```python
M = 2**80
t = lambda x: (148*x + 337)*x

a = 12323976543456789868
b = t(a)
def recover_prev_first_nbits(output, known_bits=80):
    known = 0
    for bit in range(known_bits):
        mod = 2**(bit+1)
        for b in (0, 1):
            guess = (b<<bit) + known
            if t(guess) % mod == output % mod:
                known = guess
    return known
assert a == recover_prev_first_nbits(b, 80)
```

Осталось воспользоваться `stream`. Давайте его представим в более читабельной форме, где для каждого числа `i` свой вывод:

```python
In [6]: stream = [stream[i : i + 80 // 4] for i in range(0, len(stream), 80 // 4)]

In [13]: stream[-60:-50]
Out[13]:
[[0, 0, 1, 1, 1, 0, 9, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0],
 [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 7, 0, 0, 1, 0, 1],
 [1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 9, 0, 0, 1],
 [1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 5, 1, 0, 1, 1],
 [0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0],
 [0, 1, 15, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
 [1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 10, 0, 0, 1, 1, 1],
 [9, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
 [0, 0, 3, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1],
 [0, 0, 0, 0, 5, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0]]
```

Числа, отличающие от 0 и 1 выглядят подозрительно, прочитаем сорцы таска:
```python
stream = []
for i in range(700):
    key = t(key) % M
    hint_index = random.choice(range(0, 80, 4))
    for i in range(0, 80, 4):
        sub = (key >> i) % 2**4
        if i == hint_index:
            stream.append(sub)
```

Функцию `t` мы уже умеем инвертировать по последним битам, так давайте найдем с конца первый `stream[i][0] != 0,1`, тогда мы восстановим все `stream[i-1][0], stream[i-2][0], ..., stream[0][0]`. Восстановив их, мы можем сделать так же для `stream[i][1]` и так далее. Получив `stream[0]` ключ восстанавливается таким же методом.


## Writeup (en)
First you need to think: is it possible to invert the function `t = lambda x: (148*x + 337)*x % (2**80)`? Yes, this is done by sequentially taking `mod 2, `mod 2^2, ...`, recovering bit by bit.

```python
M = 2**80
t = lambda x: (148*x + 337)*x

a = 12323976543456789868
b = t(a)
def recover_prev_first_nbits(output, known_bits=80):
    known = 0
    for bit in range(known_bits):
        mod = 2**(bit+1)
        for b in (0, 1):
            guess = (b<<bit) + known
            if t(guess) % mod == output % mod:
                known = guess
    return known
assert a == recover_prev_first_nbits(b, 80)
```

It remains to use `stream'. Let's present it in a more readable form, where each number `i` has its own output:

```python
In [6]: stream = [stream[i : i + 80 // 4] for i in range(0, len(stream), 80 // 4)]

In [13]: stream[-60:-50]
Out[13]:
[[0, 0, 1, 1, 1, 0, 9, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0],
 [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 7, 0, 0, 1, 0, 1],
 [1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 9, 0, 0, 1],
 [1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 5, 1, 0, 1, 1],
 [0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0],
 [0, 1, 15, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
 [1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 10, 0, 0, 1, 1, 1],
 [9, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1],
 [0, 0, 3, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1],
 [0, 0, 0, 0, 5, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0]]
```

Numbers other than 0,1 look suspicious, lets read task code:
```python
stream = []
for i in range(700):
    key = t(key) % M
    hint_index = random.choice(range(0, 80, 4))
    for i in range(0, 80, 4):
        sub = (key >> i) % 2**4
        if i == hint_index:
            stream.append(sub)
```

We already know how to invert the `t` function by the last bits, so let's find the first `i` from the end`stream[i][0] != 0,1`, then we will recover all `stream[i-1][0], stream[i-2][0], ..., stream[0][0]'. After recovering them, we can do the same for `stream[i][1]` and so on. After recovering `stream[0]`, the key is derived using the same method.


[Exploit](solution/sol.py)
