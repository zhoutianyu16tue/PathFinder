#Pkg.add("Geodesy")
include("CreateMetaGraphs.jl")
#Pkg.add("GraphPlot")
using CreateMetaGraphs
using MetaGraphs, LightGraphs,GraphPlot
import LightGraphs.SimpleGraphs: SimpleEdge,SimpleDiGraph
@time graph,vprops,eprops,nodesLL,highways = CreateMetaGraphs.CreateMetaGraph("sweden-latest.osm");
