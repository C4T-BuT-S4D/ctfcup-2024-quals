import numpy as np
import networkx as nx
from scipy.spatial import Voronoi
import string


def voronoi_to_networkx(points):
    vor = Voronoi(points)

    graph = nx.Graph()

    point_names = {}
    max_point_name_index = 0
    for simplex in vor.ridge_vertices:
        if -1 not in simplex:
            i, j = simplex
            p = tuple(vor.vertices[i])
            q = tuple(vor.vertices[j])
            if p not in point_names:
                point_names[p] = string.ascii_uppercase[max_point_name_index]
                max_point_name_index += 1
            if q not in point_names:
                point_names[q] = string.ascii_uppercase[max_point_name_index]
                max_point_name_index += 1
            if 0 <= p[0] <= 1 and 0 <= p[1] <= 1 and 0 <= q[0] <= 1 and 0 <= q[1] <= 1:
                graph.add_edge(point_names[p], point_names[q])

    return graph

def generate_planar_graph(points: np.array):
    points = np.random.rand(points, 2)
    return voronoi_to_networkx(points)

def main():
    import matplotlib.pyplot as plt
    graph = generate_planar_graph(8)
    nx.draw_planar(graph, node_size=10000, labels={n: n for n in graph.nodes()}, font_family="OCR A")
    plt.savefig("lol.png")

if __name__ == "__main__":
    main()
