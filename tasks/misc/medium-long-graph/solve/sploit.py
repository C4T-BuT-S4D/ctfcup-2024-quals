from typing import List, Tuple, Set, Optional
import sys
import requests
import re
import json

HOST = sys.argv[1]
PORT = 7117
url = f"http://{HOST}:{PORT}/graph.json"

def get_range(n: int) -> str:
    q = requests.get(url, headers={"Range": f"bytes={n - 1000}-{n + 1000}"})
    return q.text

def binsearch_vertex(v: int, file_len: int) -> Tuple[List[int], Optional[str]]:
    def test(n: int) -> bool:
        first_n = int(re.search(r'("[0-9]*"): ', get_range(n)).group(1)[1:-1])
        return v >= first_n

    lb = 0
    rb = file_len - 1

    while rb - lb > 1:
        mb = (lb + rb) // 2

        if test(mb):
            lb = mb
        else:
            rb = mb
    if test(lb):
        res = lb
    else:
        res = rb

    resp = get_range(res)
    flag = None

    q = re.search('"flag": ("[^"]*")', resp)
    if q is not None:
        flag = q.group(1)

    return [int(i) for i in json.loads(re.search(r'\[("[0-9]*", )*"[0-9]*"]', resp).group(0))], flag

def dfs(file_len: int, graph, visited: Set[int], v: int) -> Optional[str]:
    if v in visited:
        return None

    visited.add(v)

    if v not in graph:
        to_extend, flag = binsearch_vertex(v, file_len)
        graph[v] = to_extend
        if flag is not None:
            return flag

    for u in graph[v]:
        flag = dfs(file_len, graph, visited, u)
        if flag is not None:
            return flag
    

def main():
    resp = requests.head(url)
    file_len = int(resp.headers["Content-Length"])
    resp = requests.get(url, headers={"Range": "bytes=0-1000"})

    graph = {}
    zero_neighbors = [int(i) for i in json.loads(re.search(r'\[("[0-9]*", )*"[0-9]*"]', resp.text).group(0))]
    graph[0] = zero_neighbors

    print(dfs(file_len, graph, set(), 0))



if __name__ == "__main__":
    main()
