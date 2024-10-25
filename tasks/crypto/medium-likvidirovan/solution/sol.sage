from sage.all import *
import os
import random
import string

block_len = 4

inputs = [''.join(random.choice(string.ascii_letters + string.digits) for i in range(4)) for j in range(150)]
print('INPUT THIS STRING: ', ''.join(inputs))
hashes = eval(input("INPUT HASH ARRAY: "))

result_hash_pairs = []

# if hash(aboba1) < 0, then we can only xor it with another hash(aboba2) < 0
pair_lz = (0, '')
for i in range(len(hashes)):
    if hashes[i] < 0:
        if pair_lz[0] == 0:
            pair_lz = (hashes[i], inputs[i])
        else:
            pair_lz = (hashes[i] ^^ pair_lz[0], pair_lz[1] + inputs[i])
            result_hash_pairs.append((pair_lz[0], pair_lz[1]))
            pair_lz = (0, '')
    else:
        result_hash_pairs.append((hashes[i], inputs[i]))

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

result_strings = []
for vec in L:
    string = ''
    for i in range(len(vec)):
        if vec[i] % 2:
            string += result_hash_pairs[i][1]
    result_strings.append(string)

result_strings.sort(key = lambda st: len(st))
[len(i) for i in result_strings]

print("YOUR STRINGS:")
print(result_strings[0])
print(result_strings[1])
