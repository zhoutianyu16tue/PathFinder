# A Deep Learning Approach for Route Planning in Road Networks
Traditionally, route planning in road networks relies heavily on shortest path algorithms such as Dijkstra's and A* search.
Dijkstra's algorithm guarantees to find the optimal paths if exist. However, its time complexity, $O(E + VlogV)$ where $E$ and $V$ are the number of edges and nodes respectively, makes it inefficient in large graphs. A* search, as a variation of Dijkstra's, uses heuristics to accelerate, resulting in complexity of $\Theta (E)$. The acceleration comes at the prices that:  
* the algorithm is not guaranteed to converge, meaning it may not be able to find paths;  
* the paths generated are not necessarily the optimal ones.

## Background

## Method

## Experiments

