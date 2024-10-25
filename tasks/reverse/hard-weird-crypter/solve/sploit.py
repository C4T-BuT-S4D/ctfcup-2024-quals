from typing import List

PBOX = [14, 13, 0, 11, 2, 12, 3, 1, 15, 4, 5, 10, 8, 7, 9, 6]
PBOX_INVERSE = [PBOX.index(i) for i in range(16)]
SBOX = [11, 114, 118, 143, 81, 49, 163, 101, 73, 220, 77, 113, 148, 8, 195, 237, 108, 62, 211, 223, 116, 4, 50, 20, 242, 136, 92, 53, 119, 36, 17, 76, 217, 152, 208, 144, 185, 51, 71, 120, 70, 212, 45, 201, 255, 238, 48, 210, 55, 160, 236, 233, 57, 205, 187, 102, 222, 33, 46, 117, 75, 132, 32, 138, 59, 64, 23, 28, 166, 153, 115, 93, 84, 176, 26, 18, 72, 145, 202, 234, 15, 61, 147, 100, 10, 165, 193, 104, 227, 37, 86, 74, 25, 225, 40, 137, 206, 245, 58, 192, 188, 6, 88, 207, 9, 179, 105, 172, 29, 16, 106, 110, 215, 126, 199, 175, 154, 200, 167, 80, 130, 30, 85, 63, 0, 157, 60, 128, 243, 151, 184, 141, 182, 146, 13, 142, 82, 183, 191, 254, 89, 122, 19, 91, 224, 241, 41, 21, 196, 170, 161, 235, 131, 229, 228, 226, 14, 253, 1, 83, 65, 140, 203, 68, 99, 239, 39, 78, 218, 247, 171, 66, 173, 230, 190, 7, 133, 54, 129, 219, 174, 180, 124, 240, 109, 90, 177, 95, 42, 79, 162, 123, 22, 231, 150, 213, 214, 197, 98, 155, 139, 111, 52, 67, 164, 186, 2, 107, 38, 3, 178, 149, 249, 47, 43, 169, 112, 194, 251, 232, 189, 44, 69, 246, 159, 31, 5, 121, 135, 56, 252, 24, 35, 204, 198, 158, 250, 244, 96, 181, 103, 156, 87, 209, 216, 168, 127, 248, 34, 97, 12, 94, 221, 125, 27, 134]
SBOX_INVERSE = [SBOX.index(i) for i in range(256)]
MATRIX = [[114, 164, 184, 87], [171, 84, 219, 123], [144, 8, 103, 181], [196, 57, 53, 157]]
INVERSE_MATRIX = [[46, 111, 177, 52], [46, 240, 101, 169], [71, 134, 5, 132], [3, 78, 238, 108]]

def mul_matrix_mod_256(a: List[List[int]], b: List[List[int]]) -> List[List[int]]:
    res = [[0 for _ in range(len(a))] for _ in range(len(b[0]))]
    for i in range(len(a)):
        for j in range(len(b[0])):
            for k in range(len(a[0])):
                res[i][j] = (res[i][j] + a[i][k] * b[k][j]) % 256
    return res


def decrypt_inner(key: bytes, data: bytes) -> bytes:
    for _ in range(16):
        m = ([[data[4 * i +  j] for j in range(4)] for i in range(4)])
        m = mul_matrix_mod_256(m, INVERSE_MATRIX)
        data = [m[i][j] for i in range(4) for j in range(4)]
        data = [data[i] for i in PBOX_INVERSE]
        data = [SBOX_INVERSE[i] for i in data]
        data = [a ^ b for a, b in zip(data, key)]
        
    return bytes(data)

def decrypt(key: bytes, data: bytes) -> bytes:
    assert len(data) % 16 == 0 and len(data) >= 32
    iv = data[:16]
    data = data[16:]

    res = []

    for i in range(0, len(data), 16):
        block = bytes(a ^ b for a, b in zip(decrypt_inner(key, data[i:i+16]), iv))
        res.append(block)
        iv = data[i:i+16]

    return b''.join(res)

def main():
    with open("flag.txt", 'rb') as f:
        data = f.read()

    with open("key.bin", 'rb') as f:
        key = f.read()
    print(decrypt(key, data))

if __name__ == "__main__":
    main()
