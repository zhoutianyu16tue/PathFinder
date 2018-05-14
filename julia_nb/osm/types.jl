type Highway
    @compat class::AbstractString       # Type of highway
    lanes::Int          # Number of lanes (1 if unspecified)
    oneway::Bool        # True if road is one-way
    @compat name::AbstractString        # Name, if available
    nodes::Vector{Int}  # List of nodes
    traffic_signals::Bool
    int_ref::AbstractString
    maxspeed::Int
    id::Int # Uninitialized this is highway id in osm and osm id in petter's version
end

type Segment
    node0::Int64          # Source node ID
    node1::Int64          # Target node ID
    nodes::Vector{Int64}  # List of nodes falling within node0 and node1
    dist::Real          # Length of the segment
    class::Int          # Class of the segment
    parent::Int         # ID of parent highway
    oneway::Bool        # True if road is one-way
    traffic_signals::Bool
    maxspeed::Int
    id::Int # Uninitialized this is highway id in osm and osm id in petter's version
    #direction::Vector{Float64}
end


type Intersection
    highways::Set{Int}  # Set of highway IDs
end
Intersection() = Intersection(Set{Int}())

type HighwaySet # Multiple highways representing a single "street" with a common name
    highways::Set{Int}
end

type Style
    color::UInt32
    width::Real
    spec::AbstractString
end
Style(x,y) = Style(x,y,"-")
