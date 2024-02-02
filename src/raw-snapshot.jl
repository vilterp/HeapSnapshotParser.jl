struct RawSnapshotMeta
    node_fields::Vector{String}
    node_types::Vector{Union{String, Vector{String}}}
    edge_fields::Vector{String}
    edge_types::Vector{Union{String, Vector{String}}}
end

struct RawSnapshotSnapshot
    meta::RawSnapshotMeta
end

struct RawSnapshot
    snapshot::RawSnapshotSnapshot
    nodes::Vector{Int}
    edges::Vector{Int}
    strings::Vector{String}
end
