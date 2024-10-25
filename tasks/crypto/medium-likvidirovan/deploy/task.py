import os


s = input()
assert(len(s) <= 4*150 and len(s)%4==0)
print([hash(s[i:i+4]) for i in range(0, len(s), 4)])

for round in range(2):
    s2 = input()
    assert 0 < len(s2) <= 30*4 and len(s2) % 4 == 0

    blocks = [s2[i:i+4] for i in range(0, len(s2), 4)]
    assert len(blocks) == len(set(blocks))

    result_hash = 0
    for block in blocks:
        result_hash ^= hash(block)
    assert result_hash == 0

print(os.getenv("FLAG", "flag{test_flag}"))
