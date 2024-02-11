using SparseArrays

function make_sparse_matrix(snapshot::ParsedSnapshot)
    n = length(snapshot.edges)
    
    lefts = zeros(Int, n)
    rights = zeros(Int, n)
    values = zeros(Int, n)
    
    i = 0
    for node_idx in 1:length(snapshot.nodes)
        node = snapshot.nodes[node_idx]
        for edge_idx in node.edge_indexes
            i += 1
            
            edge = snapshot.edges[edge_idx]
            lefts[i] = node_idx
            rights[i] = edge.to
            values[i] = edge.name
        end
    end
    
    return sparse(lefts, rights, values)
end
