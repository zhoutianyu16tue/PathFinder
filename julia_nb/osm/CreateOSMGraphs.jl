module CreateOSMGraphs

using Geodesy
using LightGraphs
using LibExpat
using Compat
using Winston
import LightGraphs.SimpleGraphs: SimpleDiGraph,SimpleEdge
export parseMapXML, getOSMData, roadways, CreateOSM, path_dijkstra
export findIntersections, nearestNode, segmentHighways, highwaySegments
export createGraph, shortestRoute, fastestRoute, routeEdges, bearing
export nodesWithinRange, nodesWithinDrivingDistance, nodesWithinDrivingTime
export findHighwaySets, findIntersectionClusters, replaceHighwayNodes!
include("geohash.jl")
include("speeds.jl")
include("types.jl")
include("classes.jl")
include("parseMap.jl")
include("routing.jl")
include("intersections.jl")
include("highways.jl")
include("layers.jl")
include("plot.jl")
const PropDict = Dict{Symbol,Any}

function CreateOSMGraph(filename::String)
    println("getOSMData")
    @time nodesInfor, highways = getOSMData(filename)
    println("intersections")
    @time intersections = findIntersections(highways)
    println("roadways")
    @time classes = roadways(highways)
    println("segmentHighways")
    @time segment = segmentHighways(nodesInfor, highways, intersections, classes)
    println("createGraph")
    @time graph,vprops,eprops, edgeDict, geohash2edgedict = createGraph(segment, intersections,nodesInfor)
    return graph, vprops, eprops, edgeDict, nodesInfor,highways,geohash2edgedict
end

function path_dijkstra(id1,id2,vprops,graph,nodesInfor)
    node0 = vprops[id1]
    node1 = vprops[id2]
    path = enumerate_paths(dijkstra_shortest_paths(graph, node0), node1)
    for p in path
        id = props(graph,p)[:id]
        a = string(nodesInfor[id].coords.lat, ",", nodesInfor[id].coords.lon)
        println(replace(a,"°",""))
    end
end

function path_a_star(id1,id2,vprops,graph,nodesLL)
    node0 = vprops[id1]
    node1 = vprops[id2]
    path  = a_star(graph,node0,node1)
    seg_start = node0
    id = props(graph,seg_start)[:id]
    a = string(nodesLL[id].coords.lat, ",", nodesLL[id].coords.lon)
    println(replace(a,"°",""))
    for p in path
        id = props(graph,p.dst)[:id]
        a = string(nodesLL[id].coords.lat, ",", nodesLL[id].coords.lon)
        println(replace(a,"°",""))
    end
end

end
