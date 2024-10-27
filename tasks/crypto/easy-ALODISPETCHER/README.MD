# crypto | ALODISPETCHER

## Information

> Вы опять вышли из бара и стали свидетелем погони за шпионами. Четкая приора шпионов постоянно меняла номера, из-за чего вам тяжело было дать их ориентировку. Так вот, за рулем вы подключились к их Тесле и выкачали оттуда их код для смены номеров (спасибо Илону Маску что водителей прочипировали, и это не заставило труда сделать). Теперь необходимо узнать какой у них номер был изначально.

> You left the bar again and witnessed a spy chase. A black lada priora of spies constantly changed the numbers, which made it difficult for you to give them an orientation. So, while driving, you connected to their Tesla and pumped out their code for changing numbers (thanks to Elon Musk that the drivers were piped, and it didn't make it difficult to do). Now you need to find out what their number was originally.

## Public

Provide public/ directory.

## TLDR

Z3 equation solve

## Writeup (ru)

Для начала нужно заметить, что `SBOX` довольно линейный. Даже глазками можно увидеть `SBOX = [(13*i+1)%256 for i in range(256)]`. То есть `SBOX[i] = 13*i+1`, то есть вывели формула `SBOX`.

Вторым движением будет убрать `random.shuffle(ct)`, взяв `sum(ct) % 256`.

Сам же шифр имеет всего 2 раунда и очень линеен, поэтому все можно забить в `z3`. Может быть проблема с тем, что `key` будет не единственный, т.к. берем `ct % 256`, но мы знаем `key[i] = random.randint(0, 64)`, поэтому добавим условие `z3.ULE(k[i], 64)`.

## Writeup (en)

First of all, it should be noted that `SBOX` is quite linear. Even with your eyes you can see `SBOX = [(13*i+1)%256 for i in range(256)]`. That is, `SBOX[i] = 13*i+1`, that is, the formula `SBOX` was derived.

The second move will be to remove `random.shuffle(ct)` by taking `sum(ct)%256`.

The cipher itself has only 2 rounds and is very linear, so everything can be scored in `z3`. There may be a problem with the fact that `key` will not be the only one, because we take `ct % 256`, but we know `key[i] = random.randint(0, 64)`, so we add the condition `z3.ULE(k[i], 64)`.

[Exploit](solution/sol.py)
