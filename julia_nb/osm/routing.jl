### Get list of vertices (highway nodes) in specified levels of classes ###
# For all highways
function highwayVertices(highways::Dict{Int,Highway})
    vertices = Set{Int}()
    for highway in values(highways)
        union!(vertices, highway.nodes)
    end
    return vertices
end

# For classified highways, we select only values less than 7
function highwayVertices(highways::Dict{Int,Highway}, classes::Dict{Int,Int})
    vertices = Set{Int}()
    for key in keys(classes)
        if classes[key] <7
            union!(vertices, highways[key].nodes)
        end
    end
    return vertices
end

# For specified levels of a classifier dictionary
function highwayVertices(highways::Dict{Int,Highway}, classes::Dict{Int,Int}, levels)
    vertices = Set{Int}()
    for (key, class) in classes
        if in(class, levels)
            union!(vertices, highways[key].nodes)
        end
    end
    return vertices
end

#calculate direction
function bearing(endpoint::LatLon,startpoint::LatLon)
    y1 = endpoint.lat
    x1 = endpoint.lon
    y2 = startpoint.lat
    x2 = startpoint.lon
    radians = atan2((y1-y2),(x1-x2))
    compass = radians * (180/pi)
    coordnames = ["E", "NE", "N", "NW", "W", "SW", "S", "SE", "E"]
    coordindex = Int(round(compass / 45))
    index = coordindex < 0 ? coordindex + 9 : coordindex + 1
    return coordnames[index]
end

#calculate segment lat long
function segmentmid(segment)
    nodes = segment.nodes
    l = length(nodes)
    if l == 2
        return -1
    else
        return nodes[Int(round(l/2))]
    end 
end

#calculate weights
function calculate_weight(segment)
    segmentlen = segment.dist
    segmentspeed = SPEED_ROADS_RURAL[segment.class]*5/18
    traffic = segment.traffic_signals == true ? 15 : 0
    weight = segmentlen/segmentspeed + traffic
    return weight
end
#interpolate straight lines
function interpolatestraightline(nofpoints::Int,LLA1::LatLon{Float64},LLA2::LatLon{Float64})
    startlat,startlon = LLA1.lat, LLA1.lon
    endlat,endlon = LLA2.lat, LLA2.lon
    latdif = (startlat-endlat)/(nofpoints+1)
    londif = (startlon-endlon)/(nofpoints+1)
    newpoints = Array{Tuple{Float64,Float64},1}(nofpoints)
    for i = 1:nofpoints
        newpoints[i] = (startlat-i*latdif,startlon-i*londif)
    end
    return newpoints
end
    
#create dict from geohash to edge
function geohash2edge(geohash2edgedict::Dict{String,Tuple{Int64,Int64}},segment::Segment, nodeLLA::Dict{Int64,CreateOSMGraphs.NodeInfor},node0::Int64,node1::Int64)
    nodes = segment.nodes
    nofnodes = length(nodes)
    newpoints = Array{Tuple{Float64,Float64},1}(0)
    for i = 1:nofnodes-1
        push!(geohash2edgedict,nodeLLA[nodes[i]].geohash=>(node0,node1))
        nofpoints = floor(Int,Geodesy.distance(nodeLLA[nodes[i]].coords, nodeLLA[nodes[i+1]].coords)/80)
        if nofpoints > 0
            subnewpoints = interpolatestraightline(nofpoints,nodeLLA[nodes[i]].coords, nodeLLA[nodes[i+1]].coords)
            append!(newpoints,subnewpoints)
            for p in subnewpoints
                push!(geohash2edgedict, geo_encode(p[1],p[2])=>(node0,node1))
            end
        end
    end
    push!(geohash2edgedict,nodeLLA[node1].geohash=>(node0,node1))
    return newpoints
end 
#create directed graph with metadigraph
function createGraph(segments::Vector{Segment}, intersections::Dict{Int,Intersection}, nodeLLA::Dict{Int64,CreateOSMGraphs.NodeInfor}, reverse::Bool=false)
    #graph = MetaDiGraph()
    graph = SimpleDiGraph()
    geohash2edgedict = Dict{String,Tuple{Int64,Int64}}()
    vprops = Dict()
    eprops = Dict()
    edgeDict = Dict()
    i = 1
    for vert in keys(intersections)
        add_vertex!(graph)
        #set_prop!(graph,i,:id,vert)
        push!(vprops,vert => i)
        i+=1
    end
    
    for segment in segments
        # Add edges to graph and compute weights
        #if reverse
            #node0 = segment.node1
            #node1 = segment.node0
        #else
            node0 = segment.node0
            node1 = segment.node1
        #end
        push!(eprops, node0 => nodeLLA[node0])
        push!(eprops, node1 => nodeLLA[node1])
        startLL = nodeLLA[node0].coords
        endLL = nodeLLA[node1].coords
        direction  = bearing(endLL, startLL)
        #mid = segmentmid(segment)
        #if mid == -1
            #lat = (startLL.lat + endLL.lat) / 2
            #lon = (startLL.lon + endLL.lon) / 2
            #midLL = LatLon(lat,lon)
        #else
            #midLL = nodeLLA[mid].coords
        #end
        newpoints = geohash2edge(geohash2edgedict,segment,nodeLLA,node0,node1)
        e = Edge(vprops[node0], vprops[node1])
        add_edge!(graph,e)
#         weight = calculate_weight(segment)
        speed = segment.maxspeed != 0 ? segment.maxspeed : SPEED_ROADS_RURAL[segment.class]
        push!(edgeDict, e => Dict(:interpolates => newpoints,
    :direction => direction,:id => segment.id, :segmentlen => segment.dist, :speed => speed / 3.6, :traffic => segment.traffic_signals))
        #set_prop!(graph,e,:location,midLL)
        #set_prop!(graph,e,:direction,direction)
        #set_prop!(graph,e,:weight,weight)
        #set_prop!(graph,e,:speed, speed)
        #set_prop!(graph,e,:traffic, segment.traffic_signals)
        #set_prop!(graph,e,:id,segment.id)
        # eprops[e] = Dict(:distance=>weight,:class=>class)
        # push!(defaultweight,weight)
        # if !segment.oneway
        #     e = Edge(vprops[node1], vprops[node0])
        #     add_edge!(graph,e)
        #     set_props!(graph,e,Dict(:weight,weight))
        #     # eprops[e] = Dict(:distance=>weight,:class=>class)
        #     # push!(defaultweight,weight)
        # end
    end
    return graph, vprops, eprops, edgeDict, geohash2edgedict
end


# Put all edges in network.g in an array, indexed by their edge index

# #Get direction of segments
# function directionode(nodes::Dict{Int,Geodesy.LatLon}, node0, node1)
#     loc0 = nodes[node0]
#     loc1 = nodes[node1]
#     dist = distance(loc0, loc1)
#     direc = (loc0 - loc1)./dist
#     return direc
# end

### Get distance between two nodes ###
# ENU Coordinates
function distancenode(nodes::Dict{Int,NodeInfor}, node0, node1)
    loc0 = nodes[node0].coords
    loc1 = nodes[node1].coords
    return distance(loc0, loc1)
end

### Compute the distance of a route ###
function distancenode(nodes::Dict{Int,NodeInfor}, route::Vector{Int})
    if length(route) == 0
        return Inf
    end
    dist = 0.0
    prev_point = nodes[route[1]].coords
    for i = 2:length(route)
        point = nodes[route[i]].coords
        dist += distance(prev_point, point)
        prev_point = point
    end

    return dist
end

### Shortest Paths ###
# Dijkstra's Algorithm
function dijkstra(g, w, start_vertex)
    return dijkstra_shortest_paths(g, w, start_vertex)
end

# Bellman Ford's Algorithm
function bellmanFord(g, w, start_vertices)
    return bellman_ford_shortest_paths(g, w, start_vertices)
end

# Extract route from Dijkstra results object
function extractRoute(dijkstra, start_index, finish_index)
    route = Int[]

    distance = dijkstra.dists[finish_index]

    if distance != Inf
        index = finish_index
        push!(route, index)
        while index != start_index
            index = dijkstra.parents[index].index
            push!(route, index)
        end
    end

    reverse!(route)

    return route, distance
end

### Generate an ordered list of edges traversed in route
function routeEdges(network::SimpleDiGraph, route::Vector{Int})
    e = Array(Int, length(route)-1)
    # For each node pair, find matching edge
    for n = 1:length(route)-1
        s = route[n]
        t = route[n+1]
        for e_candidate in Graphs.out_edges(network.v[s],network.g)
            if t == e_candidate.target.key
                e[n] = e_candidate.index
                break
            end
        end
    end
    return e
end

### Shortest Route ###
function shortestRoute(network, node0, node1)
    start_vertex = network.v[node0]

    dijkstra_result = dijkstra(network.g, network.w, start_vertex)

    start_index = network.v[node0].index
    finish_index = network.v[node1].index
    route_indices, distance = extractRoute(dijkstra_result, start_index, finish_index)

    route_nodes = getRouteNodes(network, route_indices)

    return route_nodes, distance
end

function getRouteNodes(network, route_indices)
    route_nodes = Array(Int, length(route_indices))
    v = Graphs.vertices(network.g)
    for n = 1:length(route_indices)
        route_nodes[n] = v[route_indices[n]].key
    end

    return route_nodes
end

function networkTravelTimes(network, class_speeds)
    w = Array(Float64, length(network.w))
    for k = 1:length(w)
        w[k] = network.w[k] / class_speeds[network.class[k]]
        w[k] *= 3.6 # (3600/1000) unit conversion to seconds
    end
    return w
end

### Fastest Route ###
function fastestRoute(network, node0, node1, class_speeds=SPEED_ROADS_URBAN)
    start_vertex = network.v[node0]
    # Modify weights to be times rather than distances
    w = networkTravelTimes(network, class_speeds)
    dijkstra_result = dijkstra(network.g, w, start_vertex)
    start_index = network.v[node0].index
    finish_index = network.v[node1].index
    route_indices, route_time = extractRoute(dijkstra_result, start_index, finish_index)
    route_nodes = getRouteNodes(network, route_indices)
    return route_nodes, route_time
end

function filterVertices(vertices, weights, limit)
    if limit == Inf
        @assert length(vertices) == length(weights)
        return keys(vertices), weights
    end
    indices = Int[]
    distances = Float64[]
    for vertex in vertices
        distance = weights[vertex.index]
        if distance < limit
            push!(indices, vertex.key)
            push!(distances, distance)
        end
    end
    return indices, distances
end

# Extract nodes from BellmanFordStates object within an (optional) limit
# based on driving distance
function nodesWithinDrivingDistance(network::SimpleDiGraph, start_indices, limit=Inf)
    start_vertices = [network.v[i] for i in start_indices]
    bellmanford = bellmanFord(network.g, network.w, start_vertices)
    return filterVertices(values(network.v), bellmanford.dists, limit)
end

function nodesWithinDrivingDistance(network::SimpleDiGraph,
                                    loc::ENU,
                                    limit=Inf,
                                    loc_range=100.0)
    return nodesWithinDrivingDistance(network,
                                      nodesWithinRange(network.v, loc, loc_range),
                                      limit)
end

# Extract nodes from BellmanFordStates object within a (optional) limit,
# based on driving time
function nodesWithinDrivingTime(network,
                                start_indices,
                                limit=Inf,
                                class_speeds=SPEED_ROADS_URBAN)
    # Modify weights to be times rather than distances
    w = networkTravelTimes(network, class_speeds)
    start_vertices = [network.v[i] for i in start_indices]
    bellmanford = bellmanFord(network.g, w, start_vertices)
    return filterVertices(values(network.v), bellmanford.dists, limit)
end

function nodesWithinDrivingTime(network::SimpleDiGraph,
                                loc::ENU,
                                limit=Inf,
                                class_speeds=SPEED_ROADS_URBAN,
                                loc_range=100.0)
    return nodesWithinDrivingTime(network,
                                  nodesWithinRange(network.v, loc, loc_range),
                                  limit)
end
