using LightGraphs

struct SCCNode
    name::String
    out_edges::Vector{String}
end

struct SCCGraph
    nodes::Dict{String,SCCNode}
end

function condensation(snapshot::ParsedSnapshot)
    XXX
end

function as_lightgraph(snapshot::ParsedSnapshot)
    g = SimpleDiGraph(length(snapshot.nodes))
    for (node_idx, node) in enumerate(snapshot.nodes)
        for edge_idx in node.edge_indexes
            if edge_idx > length(snapshot.edges)
                @info "not found: edge $edge_idx"
                continue
            end
            edge = snapshot.edges[edge_idx]
            add_edge!(g, node_idx, edge.to)
        end
    end
    return g
end
