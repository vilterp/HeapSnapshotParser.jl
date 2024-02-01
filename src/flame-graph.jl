mutable struct FlameNode
    name::String
    self_value::Float64
    children::Vector{FlameNode}
end

function FlameNode(name::String)
    return FlameNode(name, 0.0, [])
end

function get_flame_graph(snapshot::HeapSnapshot)
    graph, seq_to_node = as_lightgraph(snapshot)
    undir = LightGraphs.SimpleGraph(graph)
    mst = LightGraphs.prim_mst(undir)
    # convert to a flame graph
    nodes = Dict{Int, FlameNode}()
    root = FlameNode("root")
    nodes[-1] = root
    # TODO: how do we find the root in the snapshot?
    for edge in mst
        if !haskey(nodes, edge.src)
            nodes[edge.src] = FlameNode(seq_to_node[edge.src].type)
        end
        if !haskey(nodes, edge.dst)
            nodes[edge.dst] = FlameNode(seq_to_node[edge.dst].type)
        end
    end
    for edge in mst
        parent = nodes[edge.src]
        child = nodes[edge.dst]
        # parent.self_value += snapshot.edges[(edge.src, edge.dst)].self_size
        push!(parent.children, child)
    end
    
    return root
end