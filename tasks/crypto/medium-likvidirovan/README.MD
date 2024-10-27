# crypto | likvidirovan

## Information

> Вы вышли из бара и увидели шпиона, наблюдавшего за замесом цемента на сверхсекретной стройке шаурмечной. Он был прижат в угол и напоследок оставил секретный ключ для своих ребят. Без него люди не смогут спокойно есть шаурму, поэтому вам просто необходимо его достать!

> You walked out of a bar and saw a spy watching cement mixing at a top-secret shawarma shop construction site. He was cornered and left a secret key for his guys. Without it people will not be able to eat shawarma in peace, so you just need to get it!

## Deploy

```sh
cd deploy
docker compose up --build -d
```

## Public

Provide task.py archive: [public/task.py](public/task.py).

## TLDR

use LLL for right kernel matrix of equations

## Writeup (ru)

У нас есть возможноность пошифровать пару строчек `hash('abcd')` (При каждом запуске питона `hash` имеет разные значения, и тайм лимит на коннект есть, поэтому пывнить `hash`, наверное, не надо).

И нам нужно подобрать такие `x_i = hash(input_i)`, чтобы `x_1 ^ x_2 ^ ... ^ x_n = 0`. Еще есть условия, чтобы `x_i != x_j`, чтобы нельзя было вставить два одинаковых хэша и их ксор был равен нулю.

Так как ксор является сложением по модулю 2, то давайте разобьем каждый хеш на 64 бита и составим уравнение `Mx = 0` в `GF(2)`, где `x` лежит в `right_kernel` матрицы `M`.

$$M = \begin{bmatrix}
h_{1,1} & h_{2,1} & h_{3,1} & \cdots\\
h_{1,2} & h_{2,2} & h_{3,2} & \cdots\\
h_{1,3} & h_{2,3} & h_{3,3} & \cdots\\
\vdots & \ddots & &
\end{bmatrix}$$

`x` таково, что если `x_i!=0`, то мы берем хеш в сообщение, иначе не берем.

И решим его через `sage`:

```sage
def to_bits(h):
    return [(h>>i)&1 for i in range(64)]

def from_bits(lst):
    return sum(lst[i]<<i for i in range(63,-1,-1))

F2 = GF(2)

M = Matrix(F2, [to_bits(hsh) for hsh, inp in result_hash_pairs]).T

right_kernel_matrix = M.right_kernel_matrix().change_ring(ZZ)
for i in range(len(result_hash_pairs)):
    if len(result_hash_pairs[i][1]) > block_len:
        right_kernel_matrix[:, i] *= 3 # make greater weight (because we hash 2 blocks instead of one) of hash(aboba1) ^^ hash(aboba2) where aboba's < 0

L = right_kernel_matrix.LLL()
```

Так как вектора в `right_kernel` могут быть не оч короткими, то применим `LLL`. 

## Writeup (en)

We have the opportunity to encrypt a couple of lines of `hash('abcd')` (Each time python is launched, `hash` has different values, and there is a time limit on the connection, so you probably don't need to remember `hash`).

And we need to find such `x_i = hash(input_i)` so that `x_1 ^ x_2^ ... ^ x_n = 0`. There are still conditions for `x_i != x_j` so that two identical hashes cannot be inserted and their ksor is zero.

Since xor is just addition modulo 2, let's split each hash into 64 bits and create equation `Mx = 0` in `GF(2)`, where `x` lies in the `right_kernel` of the matrix `M`.

$$A = \begin{bmatrix}
h_{1,1} & h_{2,1} & h_{3,1} & \cdots\\
h_{1,2} & h_{2,2} & h_{3,2} & \cdots\\
h_{1,3} & h_{2,3} & h_{3,3} & \cdots\\
\vdots & \ddots & &
\end{bmatrix}$$

`x` is such that if `x_i!=0`, then we take the hash in the message, otherwise we don't take it.

Let's solve it with `sage`:

```sage
def to_bits(h):
    return [(h>>i)&1 for i in range(64)]

def from_bits(lst):
    return sum(lst[i]<<i for i in range(63,-1,-1))

F2 = GF(2)

M = Matrix(F2, [to_bits(hsh) for hsh, inp in result_hash_pairs]).T

right_kernel_matrix = M.right_kernel_matrix().change_ring(ZZ)
for i in range(len(result_hash_pairs)):
    if len(result_hash_pairs[i][1]) > block_len:
        right_kernel_matrix[:, i] *= 3 # make greater weight (because we hash 2 blocks instead of one) of hash(aboba1) ^^ hash(aboba2) where aboba's < 0

L = right_kernel_matrix.LLL()
```

Because vectors in `right_kernel` not so small as we need, we can `LLL` on it.

[Exploit](solution/sol.sage)


## Cloudflare

No


