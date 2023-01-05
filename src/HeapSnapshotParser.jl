module HeapSnapshotParser

using JSON
using LightGraphs
using StructEquality

@struct_hash_equal Base.@kwdef mutable struct Node
    kind::Union{Symbol,Nothing} = nothing
    type::Union{String,Nothing} = nothing
    id::Union{Int,Nothing} = nothing
    num_edges::Union{Int,Nothing} = nothing
    self_size::Union{Int,Nothing} = nothing

    # index into snapshot.edges
    # would be an array of indexes, but Julia doesn't
    # support types which refer to each other :facepalm:
    # https://github.com/JuliaLang/julia/issues/269
    out_edge_indexes::Array{Int} = Int[]
end

dummy_node = Node()

@struct_hash_equal Base.@kwdef mutable struct Edge
    kind::Symbol = :null
    name::String = ""

    from::Node = dummy_node
    to::Node = dummy_node
end

Base.@kwdef struct HeapSnapshot
    nodes::Array{Node}
    edges::Array{Edge}
end

NODE_FIElDS = ["type", "name", "id", "self_size", "edge_count", "trace_node_id", "detachedness"]
NUM_NODE_FIELDS = length(NODE_FIElDS)

EDGE_FIELDS = ["type", "name_or_index", "to_node"]
NUM_EDGE_FIELDS = length(EDGE_FIELDS)

function parse_snapshot(file::String)::HeapSnapshot

    # JSON.parsefile is faster than JSON.parse because it uses mmap
    parsed = JSON.parsefile(file)

    snapshot = HeapSnapshot(nodes=[], edges=[])

    node_kind_enum = parsed["snapshot"]["meta"]["node_types"][1]
    edge_kind_enum = parsed["snapshot"]["meta"]["edge_types"][1]

    nodes = parsed["nodes"]
    strings = parsed["strings"]
    num_nodes = convert(Int, length(nodes)/NUM_NODE_FIELDS)

    all_num_edges = Vector{Int}(undef, num_nodes + 1)
    all_num_edges[1] = 0
    num_edges_accum = Vector{Int}(undef, num_nodes + 1)

    append!(snapshot.nodes, map(_->Node(), 1:num_nodes))

    Threads.@threads for node_idx = 0:(num_nodes-1)
        kind_key = nodes[node_idx*NUM_NODE_FIELDS + 1]
        name_key = nodes[node_idx*NUM_NODE_FIELDS + 2]
        id = nodes[node_idx*NUM_NODE_FIELDS + 3]
        self_size = nodes[node_idx*NUM_NODE_FIELDS + 4]
        num_edges = nodes[node_idx*NUM_NODE_FIELDS + 5]

        node = snapshot.nodes[node_idx + 1]
        node.kind = Symbol(node_kind_enum[kind_key + 1])
        node.type = strings[name_key + 1]
        node.num_edges = num_edges
        node.self_size = self_size
        node.out_edge_indexes = [] # filled in below
        node.id = id

        all_num_edges[node_idx + 2] = num_edges
    end
    cumsum!(num_edges_accum, all_num_edges)

    for _ in 1:num_edges_accum[end]
        push!(snapshot.edges, Edge())
    end

    edges = parsed["edges"]
    Threads.@threads for (node_i, from_node) in collect(enumerate(snapshot.nodes))
        for edge_num = 1:(from_node.num_edges)
            edge_idx = num_edges_accum[node_i] + (edge_num - 1)

            kind_key = edges[edge_idx*NUM_EDGE_FIELDS + 1]
            name_key = edges[edge_idx*NUM_EDGE_FIELDS + 2]
            to_key = edges[edge_idx*NUM_EDGE_FIELDS + 3]

            to_node_idx = convert(Int, to_key/NUM_NODE_FIELDS) + 1

            kind = Symbol(edge_kind_enum[kind_key + 1])

            name = if kind == :internal
                "<internal>"
            elseif kind == :element
                "<element>"
            else
                strings[name_key+1]
            end

            edge = snapshot.edges[edge_idx + 1]
            edge.kind = kind
            edge.name = name
            edge.from = from_node
            edge.to = snapshot.nodes[to_node_idx]

            push!(from_node.out_edge_indexes, edge_idx)
        end
    end

    return snapshot
end

function root_node(snapshot::HeapSnapshot)::Node
    return snapshot.nodes[1]
end

function live_bytes(snapshot::HeapSnapshot)::Int
    sum = 0
    for node in snapshot.nodes
        sum += node.self_size
    end
    return sum
end

# need this because we can't store the edges directly on the node
function out_edges(snapshot::HeapSnapshot, node::Node)::Array{Edge}
    out = Edge[]
    for edge_idx in node.out_edge_indexes
        edge = snapshot.edges[edge_idx]
        push!(out, edge)
    end
    return out
end

function as_lightgraph(snapshot::HeapSnapshot)::LightGraphs.DiGraph
    g = SimpleDiGraph{Int}()
    id_to_seq = Dict()
    i = 0
    for node in snapshot.nodes
        # LightGraphs doesn't let us add nodes with our own ids,
        # it assigns sequential ids.
        # So, keep a mapping from our ids to sequential ids.
        add_vertex!(g)
        id_to_seq[node.id] = i
        i += 1
    end
    for edge in snapshot.edges
        add_edge!(g, id_to_seq[edge.from.id], id_to_seq[edge.to.id])
    end
    return g
end

# TODO: struct RawEdge
# TODO: struct RawNode

end # module
