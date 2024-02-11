using SparseArrays

function make_sparse_matrix(snapshot::ParsedSnapshot)
    n = length(snapshot.nodes)
    matrix = spzeros(n, n)
    for (i, node) in enumerate(snapshot.nodes)
        for edge_idx in node.edge_indexes
            edge = snapshot.edges[edge_idx]
            matrix[i, edge.to] = edge.name
        end
    end
    return matrix
end
