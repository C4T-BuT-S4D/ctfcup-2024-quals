exec(open('output.txt').read())

M = 2**80
t = lambda x: (148*x + 337)*x

stream = [stream[i:i+80//4] for i in range(0, len(stream), 80//4)]

# a = 12323976543456789868
# b = t(a)
def recover_prev_first_nbits(output, known_bits=80):
    known = 0
    for bit in range(known_bits):
        mod = 2**(bit+1)
        for b in (0, 1):
            guess = (b<<bit) + known
            if t(guess) % mod == output % mod:
                known = guess
    return known

def parse_known_bits(block, already_known_bits):
    known = 0
    known_bits_count = 0
    for i in range(len(block)):
        if block[i]<=1 and known_bits_count>=already_known_bits:
            break
        known_bits_count += 4
        known += 16**i * block[i]
    return (known, known_bits_count)

def format_block(known,known_bits_count):
    return [(known>>(i))%16 for i in range(0, known_bits_count, 4)]


known, known_bits_count = [], 0
for i in range(len(stream)-1, 0,-1):
    block = stream[i]
    known, known_bits_count = parse_known_bits(block, known_bits_count)
    if known_bits_count:
        prev_known = recover_prev_first_nbits(known, known_bits_count)
        prev_block_part = format_block(prev_known, known_bits_count)
        print(f"BYLO {i-1}", stream[i-1])
        for prev_index in range(len(prev_block_part)):
            stream[i-1][prev_index] = prev_block_part[prev_index]
        print(f"UPDATE {i-1}", stream[i-1])

key = recover_prev_first_nbits(*parse_known_bits(stream[0], 80))
print('ctfcup{'+hex(key)+'}')
