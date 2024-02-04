# ==== 'raw' version ====

struct RawSnapshotMeta
    node_fields::Vector{String}
    node_types::Vector{Union{String, Vector{String}}}
    edge_fields::Vector{String}
    edge_types::Vector{Union{String, Vector{String}}}
end

struct RawSnapshotSnapshot
    meta::RawSnapshotMeta
end

# JSON3 parses directly into this
struct RawSnapshot
    snapshot::RawSnapshotSnapshot
    nodes::Vector{Int}
    edges::Vector{Int}
    strings::Vector{String}
end

# ==== 'parsed' version ====

const NodeIdx = Int

struct RawNode
    kind::Int
    name::Int
    id::Int
    self_size::Int
    num_edges::Int
end

struct RawEdge
    kind::Int
    name::Int
    to::NodeIdx
end

struct ParsedSnapshot
    nodes::Vector{RawNode}
    edges::Vector{RawEdge}
    strings::Vector{String}
end

function ParsedSnapshot()
    ParsedSnapshot(
        Vector{RawNode}(),
        Vector{RawEdge}(),
        Vector{String}(),
    )
end

# iterators

function node_indexes(snapshot::RawSnapshot)
    return 1:div(length(snapshot.nodes), NUM_NODE_FIELDS)
end

function edge_indexes(snapshot::RawSnapshot)
    return 1:div(length(snapshot.edges), NUM_EDGE_FIELDS)
end

# getters

function get_node_name(snapshot::RawSnapshot, node_idx::Int)
    string_idx = snapshot.nodes[node_idx * NUM_NODE_FIELDS + 2]
    return snapshot.strings[string_idx]
end

function get_node_id(snapshot::RawSnapshot, node_idx::Int)
    println("id idx", node_idx*NUM_NODE_FIELDS + 3)
    return snapshot.nodes[node_idx*NUM_NODE_FIELDS + 3]
end

function get_node_self_size(snapshot::RawSnapshot, node_idx::Int)
    return snapshot.nodes[node_idx*NUM_NODE_FIELDS + 4]
end

function get_node_num_edges(snapshot::RawSnapshot, node_idx::Int)
    return snapshot.nodes[node_idx * NUM_NODE_FIELDS + 5]
end

function get_node_out_edges(snapshot::RawSnapshot, node_idx::Int)
    return XXX
end
