using SparseArrays

function make_sparse_matrix(snapshot::ParsedSnapshot)
    n = length(snapshot.nodes)
    matrix = spzeros(n, n)
    for (i, node) in enumerate(snapshot.nodes)
        for edge in snapshot.edges[node.edge_indexes]
            matrix[i, edge.to] = edge.name
        end
    end
    return matrix
end
