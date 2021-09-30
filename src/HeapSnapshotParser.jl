module HeapSnapshotParser

using JSON3

Base.@kwdef struct Node
    kind::Symbol
    type::String

    # out_edges::Array{Edge}
end

Base.@kwdef struct Edge
    kind::Symbol

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
NUM_EDGE_FIELDS = length(NODE_FIElDS)

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

        node = Node(
            kind=Symbol(node_kind_enum[kind_key + 1]),
            type=parsed.strings[name_key + 1],
        )

        push!(snapshot.nodes, node)
    end

    # edges = parsed.edges
    # num_edges = convert(Int, length(edges)/NUM)
    # for edge_idx = 0:(num_edges-1)
    #     kind_key = edges[edge_idx*NUM_EDGE_FIELDS + 1]
    #     name_key = edges[edge_idx*NUM_EDGE_FIELDS + 2]
    #     to_key = edges[edge_idx*NUM_EDGE_FIELDS + 3]

    #     edge = Edge(
    #         kind=Symbol(edge_kind_enum[kind_key]),
    #         name=XXXX,
    #         from=XXX,
    #         to=snapshot.nodes[XXXX]
    #     )

    #     push!(snapshot.edges, edge)
    # end

    return snapshot
end

end # module
