PBOX = [14, 13, 0, 11, 2, 12, 3, 1, 15, 4, 5, 10, 8, 7, 9, 6]
SBOX = [11, 114, 118, 143, 81, 49, 163, 101, 73, 220, 77, 113, 148, 8, 195, 237, 108, 62, 211, 223, 116, 4, 50, 20, 242, 136, 92, 53, 119, 36, 17, 76, 217, 152, 208, 144, 185, 51, 71, 120, 70, 212, 45, 201, 255, 238, 48, 210, 55, 160, 236, 233, 57, 205, 187, 102, 222, 33, 46, 117, 75, 132, 32, 138, 59, 64, 23, 28, 166, 153, 115, 93, 84, 176, 26, 18, 72, 145, 202, 234, 15, 61, 147, 100, 10, 165, 193, 104, 227, 37, 86, 74, 25, 225, 40, 137, 206, 245, 58, 192, 188, 6, 88, 207, 9, 179, 105, 172, 29, 16, 106, 110, 215, 126, 199, 175, 154, 200, 167, 80, 130, 30, 85, 63, 0, 157, 60, 128, 243, 151, 184, 141, 182, 146, 13, 142, 82, 183, 191, 254, 89, 122, 19, 91, 224, 241, 41, 21, 196, 170, 161, 235, 131, 229, 228, 226, 14, 253, 1, 83, 65, 140, 203, 68, 99, 239, 39, 78, 218, 247, 171, 66, 173, 230, 190, 7, 133, 54, 129, 219, 174, 180, 124, 240, 109, 90, 177, 95, 42, 79, 162, 123, 22, 231, 150, 213, 214, 197, 98, 155, 139, 111, 52, 67, 164, 186, 2, 107, 38, 3, 178, 149, 249, 47, 43, 169, 112, 194, 251, 232, 189, 44, 69, 246, 159, 31, 5, 121, 135, 56, 252, 24, 35, 204, 198, 158, 250, 244, 96, 181, 103, 156, 87, 209, 216, 168, 127, 248, 34, 97, 12, 94, 221, 125, 27, 134]
MATRIX = [[114, 164, 184, 87], [171, 84, 219, 123], [144, 8, 103, 181], [196, 57, 53, 157]]

def apply_sbox():
    asm = []

    for i in range(16):
        asm.extend([
            "mov rax, 0",
            f"mov al, byte ptr[rdi + {i}]",
            "mov al, byte ptr[sbox + rax]",
            f"mov byte ptr[rdi + {i}], al"
        ])

    return asm

def apply_pbox():
    asm = []

    for i in range(16):
        asm.extend([
            "mov rbx, 0",
            f"mov bl, byte ptr[pbox + {i}]",
            f"mov al, byte ptr[rdi + rbx]",
            f"mov byte ptr [rbp - 16 + {i}], al"
        ])
    for i in range(16):
        asm.extend([
            f"mov al, byte ptr [rbp - 16 + {i}]",
            f"mov byte ptr[rdi + {i}], al",
        ])

    return asm

def xor_with_key():
    asm = []

    for i in range(16):
        asm.extend([
            "mov rax, 0",
            "mov rbx, 0",
            f"mov al, byte ptr[rdi + {i}]",
            f"mov bl, byte ptr[rsi + {i}]",
            "mov ax, word ptr[shift_8_table + rax * 2]",
            "mov al, byte ptr[xor_table + rax + rbx]",
            f"mov byte ptr[rdi + {i}], al",
        ])

    return asm

def mul_by_matrix():
    asm = []

    for i in range(4):
        for j in range(4):
            asm.extend([
                "mov rcx, 0",
            ])
            for k in range(4):
                asm.extend([
                    "mov rax, 0",
                    "mov rbx, 0",
                    f"mov al, byte ptr[rdi + 4 * {i} + {k}]",
                    f"mov bl, byte ptr[matrix + 4 * {k} + {j}]",
                    "mov ax, word ptr[shift_8_table + rax * 2]",
                    "mov al, byte ptr[mul_table + rax + rbx]",
                    "mov ah, 0",
                    "mov ax, word ptr[shift_8_table + rax * 2]",
                    "mov cl, byte ptr[add_table + rax + rcx]",
                    "mov ch, 0",
                ])

            asm.extend([
                f"mov byte ptr[rbp - 16 + 4 * {i} + {j}], cl",
            ])
    for i in range(16):
        asm.extend([
            f"mov al, byte ptr [rbp - 16 + {i}]",
            f"mov byte ptr[rdi + {i}], al",
        ])

    return asm

def main():
    asm = [".intel_syntax noprefix"]

    asm.extend([
        ".data",
        "shift_8_table:",
        ".word " + ", ".join(hex(i << 8) for i in range(256)),
        "matrix:",
        ".byte " + ", ".join(hex(MATRIX[i][j]) for i in range(4) for j in range(4)),
        "sbox:",
        ".byte " + ", ".join(hex(s) for s in SBOX),
        "pbox:",
        ".byte " + ", ".join(hex(p) for p in PBOX),
        "add_table:",
        ".byte " + ", ".join(hex((a + b) % 256) for a in range(256) for b in range(256)),
        "mul_table:",
        ".byte " + ", ".join(hex((a * b) % 256) for a in range(256) for b in range(256)),
        "xor_table:"
        ".byte " + ", ".join(hex(a ^ b) for a in range(256) for b in range(256)),
    ])
    asm.extend([
        ".text",
        ".global _encrypt_block_inner",
        "_encrypt_block_inner:",
        "push rbp",
        "push rax",
        "push rbx",
        "push rcx",
        "mov rbp, rsp",
    ])

    for _ in range(16):
        asm.extend(xor_with_key())
        asm.extend(apply_sbox())
        asm.extend(apply_pbox())
        asm.extend(mul_by_matrix())

    asm.extend([
        "mov rsp, rbp",
        "pop rcx",
        "pop rbx",
        "pop rax",
        "pop rbp",
        "ret",
    ])

    print('\n'.join(asm))

if __name__ == "__main__":
    main()
