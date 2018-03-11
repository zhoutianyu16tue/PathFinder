import networkx as nx
import random
import numpy as np
import mxnet as mx
import matplotlib.pyplot as plt
from config import *

def plot_g(G, with_labels=True):
    nx.draw(G, with_labels=with_labels)
    plt.show()

def generate_low_degree_g(node_size=20, min_out_degree=2, max_out_degree=4, weight_min=WEIGHT_MIN, weight_max=WEIGHT_MAX):
    
    G = nx.DiGraph()
    G.add_nodes_from(range(0, node_size))
    
    for node in G.nodes:
        tmp_nodes = list(G.nodes)
        tmp_nodes.remove(node)
        random.shuffle(tmp_nodes)
        
        out_neighbors = tmp_nodes[:random.randint(min_out_degree, max_out_degree)]
        
#         print(node, out_neighbors)
        
#         G.add_edges_from(map(lambda d:(node, d), out_neighbors))
        
        for out_neighbor in out_neighbors:
            G.add_edge(node, out_neighbor, weight=random.uniform(weight_min, weight_max))
        
    return G

def generate_rand_weighted_g(node_size=NUM_NODE, p=0.02, directed=True, weight_min=WEIGHT_MIN, weight_max=WEIGHT_MAX):

    rnd_g = nx.erdos_renyi_graph(node_size, p, directed=directed)

    for edge in rnd_g.edges(data=True):
        rnd_g.add_edge(edge[0], edge[1], weight=random.uniform(weight_min, weight_max))
        
    return rnd_g

def print_g(G):
    for edge in G.edges(data=True):
        print(edge)
        
def extract_path(prev, src, dst):
    
    path = []
    u = dst

    while prev[u] != -1:
        path.insert(0, u)
        u = prev[u]
        
    path.insert(0, src)
    return path

def my_dijkstra_path(G, src, dst=None):
    
    prev = [-1 for _ in range(G.number_of_nodes())]
    distance = [float('Inf') for _ in range(G.number_of_nodes())]
    distance[src] = 0
    Q = {}
    intermediate_paths = {}
    
    for node, dist in enumerate(distance):
        Q[node] = dist
        intermediate_paths[node] = []
    
    while len(Q) != 0:
        
        u = min(Q, key=Q.get)
        del Q[u]
        
        for edge in G.edges(u):
            
            
            v = edge[1]
            new_dist = distance[u] + G.get_edge_data(u, v)['weight']
            
#             intermediate_paths[v] += 1
            
            if new_dist < distance[v]:
                distance[v] = new_dist
                Q[v] = new_dist
                prev[v] = u
                
                # extract the tmp path for v here for analysis
                # TODO
                
                intermediate_paths[v].append(extract_path(prev, src, v))
                
    return extract_path(prev, src, dst), intermediate_paths