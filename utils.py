import networkx as nx
import random
import numpy as np
import mxnet as mx
import matplotlib.pyplot as plt

def load_model(prefix, epochs, train_iterator, context):
    
    sym, arg_params, aux_params = mx.model.load_checkpoint(prefix, epochs)
    model = mx.mod.Module(symbol=sym, context=context)
    model.bind(train_iterator.provide_data, train_iterator.provide_label)
    model.set_params(arg_params, aux_params)
    
    return model

def calc_path_weight_sum(G, path):
    
    weight_sum = 0.0
    
    for idx, node in enumerate(path[:-1]):
        weight_sum += G.edge[node][path[idx + 1]]['weight']
        
    return weight_sum

def plot_g(G, with_labels=True, node_size=300, font_size=8):
    
    pos = {}
    for t in G.node.items():
        pos[t[0]] = (t[1]['x'], t[1]['y'])

    nx.draw(G, pos=pos, node_size=node_size, font_size=font_size, with_labels=with_labels)
    plt.show()

def generate_low_degree_g(num_nodes=20, min_out_degree=2, max_out_degree=4, weight_min=0.0, weight_max=1.0):
    
    G = nx.DiGraph()
    G.add_nodes_from(range(0, num_nodes))
    
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

def generate_rand_weighted_g(node_size=20, p=0.02, directed=True, weight_min=0.0, weight_max=1.0):

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