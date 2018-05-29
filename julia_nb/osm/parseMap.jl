type OSMattributes
    oneway::Bool
    oneway_override::Bool
    oneway_reverse::Bool
    visible::Bool
    lanes::Int
    traffic_signals::Bool
    maxspeed::Int

    name::String
    class::String
    detail::String
    int_ref::String


    # XML elements
    element::Symbol # :None, :Node, :Way, :Tag[, :Relation]
    parent::Symbol # :Building, :Feature, :Highway
    way_nodes::Vector{Int} # for buildings and highways

    id::Int # Uninitialized this is highway id in osm and osm id in petter's version
    lat::Float64 # Uninitialized
    lon::Float64 # Uninitialized


    OSMattributes() = new(false,false,false,false,1,false,0,
                          "","","","",:None,:None,[])
end
type NodeInfor
    coords::LatLon
    geohash::String
end 

type OSMdata
    nodes::Dict{Int,NodeInfor}
    highways::Dict{Int,Highway}
    attr::OSMattributes
    OSMdata() = new(Dict(),Dict(),OSMattributes())
end

function reset_attributes!(osm::OSMattributes)
    #osm.oneway = osm.oneway_override = osm.oneway_reverse = osm.visible = osm.traffic_signals = false
    #osm.lanes = 1
    #osm.maxspeed = 0
    #osm.name = osm.class = osm.detail  = osm.int_ref = ""
    #osm.element = osm.parent = :None
    #empty!(osm.way_nodes)
    return osm = OSMattributes()
end

### PARSE XML ELEMENTS ###

function parse_node(attr::OSMattributes, attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    attr.visible = true
    attr.element = :Node
    if haskey(attrs_in, "id")
        attr.id = @compat( parse(Int,attrs_in["id"]) )
        attr.lat = float(attrs_in["lat"])
        attr.lon = float(attrs_in["lon"])
    end
end

function parse_way(attr::OSMattributes, attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    attr.visible = true
    attr.element = :Way
    if haskey(attrs_in, "id")
        attr.id = @compat( parse(Int,attrs_in["id"]) )
    end
end

function parse_nd(attr::OSMattributes, attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    if haskey(attrs_in, "ref")
        push!(attr.way_nodes, @compat( parse(Int64,attrs_in["ref"]) ) )
    end
end

function parse_tag(attr::OSMattributes, attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    if haskey(attrs_in, "k") && haskey(attrs_in, "v")
        k, v = attrs_in["k"], attrs_in["v"]
        if k == "name"
            if isempty(attr.name)
                attr.name = v # applicable to roads (highways), buildings, features
            end
        elseif attr.element == :Way
            if k == "building"
            else
           # if k == "highway"
                
#                 parse_highway(attr, k, v)
                if search(v,r"service|living_street|pedestrian|track|bus_guideway|escape|footway|bridleway|steps|path|sidewalk|construction|cycleway|raceway|platform|proposed|road") == 0:-1
                    parse_highway(attr, k, v) # for other highway tags
                end
            end
        end
    else
        # Nothing to be done here?
    end
end

### PARSE OSM ENTITIES ###

function parse_highway(attr::OSMattributes, k::@compat(AbstractString), v::@compat(AbstractString))
    if k == "highway"
        attr.class = v
        if v == "services" # Highways marked "services" are not traversable
            attr.visible = false
            return
        end
        if v == "motorway" || v == "motorway_link"
            attr.oneway = true # motorways default to oneway
        end
        if v == "uncontrolled"
            attr.traffic_signals = false
        end
        if v == "traffic_signals"
            attr.traffic_signals = true
        end
        attr.parent = :Highway
    elseif k == "oneway"
        if v == "-1"
            attr.oneway = true
            attr.oneway_reverse = true
        elseif v == "false" || v == "no" || v == "0"
            attr.oneway = false
            attr.oneway_override = true
        elseif v == "true" || v == "yes" || v == "1"
            attr.oneway = true
        end
    elseif k == "junction" && v == "roundabout"
        attr.oneway = true
    elseif k == "lanes" && length(v)==1 && '1' <= v[1] <= '9'
        attr.lanes = @compat parse(Int,v)
    elseif k == "int_ref"
        attr.int_ref = v
    elseif k == "maxspeed"
        if v in ["walk", "signals"]
            attr.maxspeed = 0
        elseif contains(v,";")
            attr.maxspeed = parse(Int,v[end-1:end])
        elseif contains(v,"knots") || contains(v,"mph")
            attr.maxspeed = 0 
        else
            attr.maxspeed = parse(Int,v)
        end
    else
        return
    end
end


function parse_feature(attr::OSMattributes, k::@compat(AbstractString), v::@compat(AbstractString))
    attr.parent = :Feature
    attr.class = k
    attr.detail = v
end

### LibExpat.XPStreamHandlers ###

function parseElement(handler::LibExpat.XPStreamHandler, name::@compat(AbstractString), attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    attr = handler.data.attr::OSMattributes
    if attr.visible
        if name == "nd"
            parse_nd(attr, attrs_in)
        elseif name == "tag"
            parse_tag(attr, attrs_in)
        end
    elseif !(haskey(attrs_in, "visible") && attrs_in["visible"] == "false")
        if name == "node"
            parse_node(attr, attrs_in)
        elseif name == "way"
            parse_way(attr, attrs_in)
        end
    end # no work done for "relations" yet
end

function collectValues(handler::LibExpat.XPStreamHandler, name::@compat(AbstractString))
    # println(typeof(name))
    osm = handler.data::OSMdata
    attr = osm.attr::OSMattributes
    if name == "node"
        push!(osm.nodes,attr.id => NodeInfor(LatLon(attr.lat, attr.lon),geo_encode(attr.lat, attr.lon)))
    elseif name == "way"
        if attr.parent == :Highway
            if attr.oneway_reverse
                reverse!(attr.way_nodes)
            end
            push!(osm.highways,attr.id => Highway(attr.class, attr.lanes,(attr.oneway && !attr.oneway_override), attr.name, copy(attr.way_nodes),attr.traffic_signals,attr.int_ref,copy(attr.maxspeed), copy(attr.id)))
        end
    else # :Tag or :Nd (don't reset values!)
        return
    end
    #reset_attributes!(osm.attr)
    osm.attr = OSMattributes()
end

### Parse the data from an openStreetMap XML file ###
function parseMapXML(filename::@compat(AbstractString))

    # Parse the file
    street_map = LightXML.parse_file(filename)

    if LightXML.name(LightXML.root(street_map)) != "osm"
        throw(ArgumentError("Not an OpenStreetMap datafile."))
    end

    return street_map
end

function getOSMData(filename::@compat(AbstractString); args...)
    osm = OSMdata()

    callbacks = LibExpat.XPCallbacks()
    callbacks.start_element = parseElement
    callbacks.end_element = collectValues

    LibExpat.parsefile(filename, callbacks, data=osm; args...)
    osm.nodes, osm.highways
end
