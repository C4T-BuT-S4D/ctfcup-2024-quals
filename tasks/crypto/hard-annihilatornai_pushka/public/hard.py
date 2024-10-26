import random

key = (2*random.randint(0, 2**79) + 1)
flag = 'ctfcup{'+ hex(key) +'}'
print(flag)

M = 2**80
t = lambda x: (148*x + 337)*x
f = lambda x0,x1,x2,x3: (x0*x1 + x1*x3 + x0*x1*x3 + x3 + x0*x2) % 2

stream = []
for i in range(700):
    key = t(key) % M
    hint_index = random.choice(range(0, 80, 4))
    for i in range(0, 80, 4):
        sub = (key >> i) % 2**4
        if i == hint_index:
            stream.append(sub)
        else:
            x0, x1, x2, x3 = sub&1, (sub>>1)&1, (sub>>2)&1, (sub>>3)&1
            stream.append(f(x0,x1,x2,x3))

open('output.txt','w').write(f'{stream = }\n')
