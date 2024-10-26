ROUNDS = 2
pts= ['4728c057c95eccf6', '6c162342d8ec4329', '13487135b5749119', 'edc9314bcb16b7f5', '176132f27f2c9070', '872b245348d80856', '7d080386a3c174d6', '53ddb1972cf2ec11']
cts= ['e0ce7ba2f97651ba', '84db1cabc78805c5', 'c0dfa7b65bbb7319', 'ad91c4bdbe339f94', 'dc0c4a20cbecd2c8', '9c803ed2bbd66b95', '002665bd1cd98198', '22f3a7e791ae78b3']

import z3
from binascii import unhexlify
pts = [unhexlify(i) for i in pts]
cts = [unhexlify(i) for i in cts]


def mix(bs, step):
    return bs[step:] + bs[:step]
def sub(bs):
    return [13*i+1 for i in bs]
def xor_(a,b):
    return [i^j for i,j in zip(a,b)]

def my_enc(bs, key, step):
    ct = bs
    for round in range(ROUNDS):
        ct = xor_(ct, key)
        ct = sub(ct)
        ct = mix(ct, step)
    return sum(ct)

for step in range(1,8):
    s = z3.Solver()
    k = [z3.BitVec(f'k[{i}]', 8) for i in range(8)]

    for i in range(8):
        s.add(z3.ULE(k[i], 64)) # k[i] <= 32 does not work lol https://z3prover.github.io/api/html/classz3py_1_1_bit_vec_ref.html#a8bdd73702fb8ca0c901f78b38632b90c

    for i in range(len(pts)):
        enc = my_enc(pts[i], k, step)
        s.add(enc == sum(list(cts[i]))%256)

    if s.check() == z3.sat:
        model = s.model()
        got_key = [model[i] for i in k]
        print(step, got_key)
        key = bytes(int(str(i)) for i in got_key)
        print('ctfcup{' + key.hex() + '}')
    else:
        print(step, 'no solution')
