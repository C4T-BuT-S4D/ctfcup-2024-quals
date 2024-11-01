import os
import random

key = bytes([random.randint(0, 64) for i in range(8)])
flag = 'ctfcup{' + key.hex() + '}'

SBOX = [1, 14, 27, 40, 53, 66, 79, 92, 105, 118, 131, 144, 157, 170, 183, 196, 209, 222, 235, 248, 5, 18, 31, 44, 57, 70, 83, 96, 109, 122, 135, 148, 161, 174, 187, 200, 213, 226, 239, 252, 9, 22, 35, 48, 61, 74, 87, 100, 113, 126, 139, 152, 165, 178, 191, 204, 217, 230, 243, 0, 13, 26, 39, 52, 65, 78, 91, 104, 117, 130, 143, 156, 169, 182, 195, 208, 221, 234, 247, 4, 17, 30, 43, 56, 69, 82, 95, 108, 121, 134, 147, 160, 173, 186, 199, 212, 225, 238, 251, 8, 21, 34, 47, 60, 73, 86, 99, 112, 125, 138, 151, 164, 177, 190, 203, 216, 229, 242, 255, 12, 25, 38, 51, 64, 77, 90, 103, 116, 129, 142, 155, 168, 181, 194, 207, 220, 233, 246, 3, 16, 29, 42, 55, 68, 81, 94, 107, 120, 133, 146, 159, 172, 185, 198, 211, 224, 237, 250, 7, 20, 33, 46, 59, 72, 85, 98, 111, 124, 137, 150, 163, 176, 189, 202, 215, 228, 241, 254, 11, 24, 37, 50, 63, 76, 89, 102, 115, 128, 141, 154, 167, 180, 193, 206, 219, 232, 245, 2, 15, 28, 41, 54, 67, 80, 93, 106, 119, 132, 145, 158, 171, 184, 197, 210, 223, 236, 249, 6, 19, 32, 45, 58, 71, 84, 97, 110, 123, 136, 149, 162, 175, 188, 201, 214, 227, 240, 253, 10, 23, 36, 49, 62, 75, 88, 101, 114, 127, 140, 153, 166, 179, 192, 205, 218, 231, 244]
ROUNDS = 2
step = random.randint(1,7)

def xor_bytes(a, b):
    assert len(a) == len(b)
    return bytes(i^j for i,j in zip(a,b))

def mix_bytes(bs):
    return bytes(bs[step:] + bs[:step])

def sub_bytes(bs):
    return bytes(SBOX[x] for x in bs)

def gen_rand(bs, key):
    assert len(bs) == len(key)
    ct = bs
    for round in range(ROUNDS):
        ct = xor_bytes(ct, key)
        ct = sub_bytes(ct)
        ct = mix_bytes(ct)
    ct = list(ct)
    random.shuffle(ct)
    return bytes(ct)

pts = []
cts = []

for i in range(8):
    pt = os.urandom(8)
    pts.append(pt.hex())
    cts.append(gen_rand(pt, key).hex())

print(flag)
open('output.txt', 'w').write(f'{pts= }\n{cts= }\n')
