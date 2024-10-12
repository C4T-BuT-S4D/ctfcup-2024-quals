#pragma GCC optimize(                                                          \
    "O3,Ofast,no-stack-protector,rename-registers,unroll-all-loops,inline-functions,sched-spec")
#include <cstdint>
#include <iostream>
#include <string>
/*#include <string_view>*/

#define MAX_LENGTH 200

using namespace std;

uint64_t prefix[MAX_LENGTH];

string s;

void build_prefix_hashes() {
  uint64_t h = 0;
  prefix[0] = h;
  for (int i = 0; i < s.size(); i++) {
    h = h * 31337 + s[i];
    prefix[i + 1] = h;
  }
}

uint64_t pow64(uint64_t base, uint64_t exp) {
  uint64_t res = 1;
  while (exp != 0) {
    if (exp % 2 == 1) {
      res = res * base;
    }
    base = base * base;
    exp /= 2;
  }
  return res;
}

void test_case() {
  cin >> s;
  build_prefix_hashes();
  int q;
  cin >> q;
  for (int i = 0; i < q; i++) {
    int la, ra;
    int lb, rb;
    cin >> la;
    cin >> ra;
    cin >> lb;
    cin >> rb;
    ra += 1;
    rb += 1;
    int ha = prefix[la] - prefix[ra] * pow64(31337, ra - la);
    int hb = prefix[la] - prefix[ra] * pow64(31337, rb - lb);
    if (ha == hb && s.substr(la, ra - la) == s.substr(rb, rb - lb)) {
      puts("YES");
    } else {
      puts("NO");
    }
  }
}

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  setvbuf(stdin, NULL, _IONBF, 0);
  int q;
  cin >> q;

  for (int i = 0; i < q; i++) {
    test_case();
  }
}
