# rev | weird_crypter

## Information

Этот мета-проект очень дорог для нас с Софи, ведь мы потратили на него больше двух лет активной мозговой деятельности... Разумеется, мы хорошо охраняем свои секреты. Кто к нам с мечом — того мы криптокирпичом.

This meta-project is very dear to Sophie and me, because we spent more than two years of active brainwork on it... Of course, we guard our secrets well. Whoever comes to us with a sword - we will cryptobrick them.


## Public

Provide archive: [public/weird_crypter.zip](public/weird_crypter.zip).

## TLDR

Movfuscated block cipher.

## Writeup (ru)

Нам дан криптер, который шифрует все файлы в папке `"."` и записывает ключ в файл `"key.bin"`. Для шифрования он используется режим cbc (iv пишется в начале файла) с кастомным шифром написаном на мувах. Сам внутренний шифр не содержит никаких веток и использует технику таблицы для реализования арифметических операций:
```python
a + b = [a + b for a in range(256) for b in range(256)][a + [a << 8 for a in range(256)][a]]
a ^ b = [a ^ b for a in range(256) for b in range(256)][a + [a << 8 for a in range(256)][a]]
```
Сам шифр довольно простой: он ксорит с ключом, применяет SBOX, применяет PBOX, умножает на невырожденную матрицу в Z256.

## Writeup (en)

We are given a crypter, which encrypts all files in "." and writes the key to "key.bin". It uses the cbc mode (iv is written at the beginning of the file) with a custom movfuscated cipher. The inner cipher is branchless and uses the movfuscator table technique to make arithmetic operations
```python
a + b = [a + b for a in range(256) for b in range(256)][a + [a << 8 for a in range(256)][a]]
a ^ b = [a ^ b for a in range(256) for b in range(256)][a + [a << 8 for a in range(256)][a]]
```
The cipher itself is quite simple: it xors with key, applies SBOX, applies PBOX, multiplies by a non-singular matrix in Z256.

[Exploit](solve/sploit.py)

## Flag

ctfcup{7cdbef04d1589bd249d9bfbba49902ac}
