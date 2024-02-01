mutable struct FlameNode
    name::String
    self_value::Float64
    total_value::Float64
    parent::Union{FlameNode,Nothing}
    children::Vector{FlameNode}
end

function FlameNode(name::String)
    return FlameNode(name, 0.0, 0.0, nothing, [])
end

function get_flame_graph(snapshot::HeapSnapshot)
    graph, seq_to_node = as_lightgraph(snapshot)
    undir = LightGraphs.SimpleGraph(graph)
    mst = LightGraphs.prim_mst(undir)
    @show(mst)
    # convert to a flame graph
    nodes = Dict{Int, FlameNode}()
    root = nothing
    
    for edge in mst
        if !haskey(nodes, edge.dst)
            nodes[edge.dst] = FlameNode(seq_to_node[edge.dst].type)
        end
        if !haskey(nodes, edge.src)
            nodes[edge.src] = FlameNode(seq_to_node[edge.src].type)
        end
    end
    # set parents and children
    for edge in mst
        parent = nodes[edge.src]
        child = nodes[edge.dst]
        child.parent = parent
        push!(parent.children, child)
        # parent.self_value += snapshot.edges[(edge.src, edge.dst)].self_size
        if root === nothing
            println("setting parent")
            root = parent
        end
    end
    
    return root
end