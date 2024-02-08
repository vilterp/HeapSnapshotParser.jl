const NodeIdx = Int

struct RawNode
    kind::Int
    name::Int
    id::Int
    self_size::Int
    edge_indexes::UnitRange{Int}
end

struct RawEdge
    kind::Symbol
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
