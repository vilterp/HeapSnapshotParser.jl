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

struct IndexedSnapshot
    raw_snapshot::RawSnapshot
    edges_start_by_node_idx::Vector{Int}
end

# index

function build_indexes(raw_snapshot::RawSnapshot)
    edges_start_by_node_idx = Vector{Int}()
    
    num_nodes = length(raw_snapshot.nodes) / NUM_NODE_FIELDS
    
    node_idx = 0
    edge_start = 0
    
    while node_idx < num_nodes
        num_edges = get_node_num_edges(raw_snapshot, node_idx)
        push!(edges_start_by_node_idx, edge_start)
        
        edge_start += num_edges * NUM_EDGE_FIELDS
        node_idx += 1
    end
    
    return IndexedSnapshot(raw_snapshot, edges_start_by_node_idx)
end

# getters

function get_node_name(snapshot::RawSnapshot, node_idx::Int)
    return snapshot.strings[
        node_idx * NUM_NODE_FIELDS + 2
    ]
end

function get_node_num_edges(snapshot::RawSnapshot, node_idx::Int)
    return snapshot.nodes[
        node_idx * NUM_NODE_FIELDS + 5
    ]
end

function get_node_out_edges(snapshot::RawSnapshot, node_idx::Int)
    return XXX
end
