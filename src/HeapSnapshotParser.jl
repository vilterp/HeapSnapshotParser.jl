module HeapSnapshotParser

using JSON3

Base.@kwdef struct Node
    kind::Symbol
    type::String
    num_edges::Int
    self_size::Int

    # index into snapshot.edges
    # would be an array of indexes, but Julia doesn't
    # support types which refer to each other :facepalm:
    # https://github.com/JuliaLang/julia/issues/269
    out_edge_indexes::Array{Int}
end

Base.@kwdef struct Edge
    kind::Symbol
    name::String

    from::Node
    to::Node
end

Base.@kwdef struct HeapSnapshot
    nodes::Array{Node}
    edges::Array{Edge}
end

NODE_FIElDS = ["type", "name", "id", "self_size", "edge_count", "trace_node_id", "detachedness"]
NUM_NODE_FIELDS = length(NODE_FIElDS)

EDGE_FIELDS = ["type", "name_or_index", "to_node"]
NUM_EDGE_FIELDS = length(EDGE_FIELDS)

function parse_snapshot(input::IOStream)::HeapSnapshot
    parsed = JSON3.read(input)
    snapshot = HeapSnapshot(nodes=[], edges=[])

    node_kind_enum = parsed.snapshot.meta.node_types[1]
    edge_kind_enum = parsed.snapshot.meta.edge_types[1]

    nodes = parsed.nodes
    num_nodes = convert(Int, length(nodes)/NUM_NODE_FIELDS)
    for node_idx = 0:(num_nodes-1)
        kind_key = nodes[node_idx*NUM_NODE_FIELDS + 1]
        name_key = nodes[node_idx*NUM_NODE_FIELDS + 2]
        self_size = nodes[node_idx*NUM_NODE_FIELDS + 4]
        num_edges = nodes[node_idx*NUM_NODE_FIELDS + 5]

        node = Node(
            kind=Symbol(node_kind_enum[kind_key + 1]),
            type=parsed.strings[name_key + 1],
            num_edges=num_edges,
            self_size=self_size,
            out_edge_indexes=[], # filled in below
        )

        push!(snapshot.nodes, node)
    end

    edges = parsed.edges
    edge_idx = 0
    for from_node in snapshot.nodes
        for edge_num = 1:(from_node.num_edges)
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
                parsed.strings[name_key+1]
            end

            edge = Edge(
                kind=kind,
                name=name,
                from=from_node,
                to=snapshot.nodes[to_node_idx],
            )

            push!(snapshot.edges, edge)
            push!(from_node.out_edge_indexes, length(snapshot.edges))
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

# need this because we can't store the edges directly on the node
function out_edges(snapshot::HeapSnapshot, node::Node)::Array{Edge}
    out = Edge[]
    for edge_idx in node.out_edge_indexes
        edge = snapshot.edges[edge_idx]
        push!(out, edge)
    end
    return out
end

# TODO: struct RawEdge
# TODO: struct RawNode

end # module
