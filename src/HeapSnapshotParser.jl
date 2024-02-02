module HeapSnapshotParser

using JSON3
using StructEquality

# Using a type parameter to avoid mutually recursive struct
# declarations, which Julia doesn't support https://github.com/JuliaLang/julia/issues/269
@struct_hash_equal Base.@kwdef struct Node
    kind::Symbol
    type::String
    id::UInt64
    num_edges::Int
    self_size::Int
    out_edges::Vector{Int}
end

function Base.show(io::IO, node::Node)
    print(io, "Node($(node.kind), $(node.type), $(node.id), $(node.num_edges), $(node.self_size))")
end

@struct_hash_equal Base.@kwdef struct Edge
    kind::Symbol
    name::String

    from::Node
    to::Node
end

function Base.show(io::IO, edge::Edge)
    print(io, "Edge($(edge.kind), $(edge.name), $(edge.from.id), $(edge.to.id))")
end

Base.@kwdef struct HeapSnapshot
    nodes::Dict{UInt64, Node}
    nodes_vec::Vector{Node}
    edges::Vector{Edge}
end

function HeapSnapshot()
    return HeapSnapshot(
        nodes=Dict{UInt64, Node}(),
        nodes_vec=Vector{Node}(),
        edges=Vector{Edge}(),
    )
end

#                    ,8,     4314,   4474241184,    57, 0,            0,               0
const NODE_FIElDS = ["type", "name", "id", "self_size", "edge_count", "trace_node_id", "detachedness"]
const NUM_NODE_FIELDS = length(NODE_FIElDS)

const EDGE_FIELDS = ["type", "name_or_index", "to_node"]
const NUM_EDGE_FIELDS = length(EDGE_FIELDS)

function parse_snapshot(file_path::String)::HeapSnapshot
    open(file_path) do f
        return parse_snapshot(f)
    end
end

function parse_snapshot(input::IOStream)::HeapSnapshot
    @info "parsing JSON"
    
    parsed = JSON3.read(input, RawSnapshot)
    
    return assemble_snapshot(parsed)
end

function assemble_snapshot(parsed::RawSnapshot)
    snapshot = HeapSnapshot()

    @info "assembling nodes"
    
    node_kind_enum = parsed.snapshot.meta.node_types[1]
    edge_kind_enum = parsed.snapshot.meta.edge_types[1]

    nodes = parsed.nodes
    strings = parsed.strings
    num_nodes = convert(Int, length(nodes)/NUM_NODE_FIELDS)
    for node_idx = 0:(num_nodes-1)
        kind_key = nodes[node_idx*NUM_NODE_FIELDS + 1]
        name_key = nodes[node_idx*NUM_NODE_FIELDS + 2]
        id = nodes[node_idx*NUM_NODE_FIELDS + 3]
        self_size = nodes[node_idx*NUM_NODE_FIELDS + 4]
        num_edges = nodes[node_idx*NUM_NODE_FIELDS + 5]

        node = Node(
            kind=Symbol(node_kind_enum[kind_key + 1]),
            type=strings[name_key + 1],
            num_edges=num_edges,
            self_size=self_size,
            out_edges=[], # filled in below
            id=id,
        )

        snapshot.nodes[id] = node
        push!(snapshot.nodes_vec, node)
    end
    
    @info "assembling edges"
    
    edges = parsed.edges
    edge_idx = 0
    for from_node in values(snapshot.nodes_vec)
        for edge_num = 1:(from_node.num_edges)
            kind_key = edges[edge_idx*NUM_EDGE_FIELDS + 1]
            name_key = edges[edge_idx*NUM_EDGE_FIELDS + 2]
            to_key = edges[edge_idx*NUM_EDGE_FIELDS + 3]

            to_node_idx = convert(UInt64, to_key/NUM_NODE_FIELDS) + 1
            # @info "edge" from_node.id edge_idx to_node_idx

            kind = Symbol(edge_kind_enum[kind_key + 1])

            # name = if kind == :internal
            #     "<internal>"
            # elseif kind == :element
            #     "<element>"
            # else
            #     strings[name_key+1]
            # end
            name = strings[name_key+1]
            to_node = snapshot.nodes_vec[to_node_idx]
            
            # @info "to_node" snapshot.nodes_vec[to_node_idx]

            edge = Edge(
                kind=kind,
                name=name,
                from=from_node,
                to=to_node,
            )

            push!(snapshot.edges, edge)
            push!(from_node.out_edges, edge_idx + 1)
            edge_idx += 1
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

include("raw-snapshot.jl")
include("flame-graph.jl")

end # module
