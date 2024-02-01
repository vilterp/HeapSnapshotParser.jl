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
    # convert to a flame graph
    nodes = Dict{Int, FlameNode}()
    
    nodes_with_no_parent = Set{Int}()
    
    for edge in mst
        if !haskey(nodes, edge.dst)
            nodes[edge.dst] = FlameNode(seq_to_node[edge.dst].type)
        end
        push!(nodes_with_no_parent, edge.dst)
        if !haskey(nodes, edge.src)
            nodes[edge.src] = FlameNode(seq_to_node[edge.src].type)
        end
        push!(nodes_with_no_parent, edge.src)
    end

    # set parents and children
    for edge in mst
        parent = nodes[edge.src]
        child = nodes[edge.dst]
        delete!(nodes_with_no_parent, edge.dst)
        child.parent = parent
        push!(parent.children, child)
        # parent.self_value += snapshot.edges[(edge.src, edge.dst)].self_size
    end
    
    @assert length(nodes_with_no_parent) == 1
    
    root_id = collect(nodes_with_no_parent)[1]
    return nodes[root_id]
end

function as_json(node::FlameNode, depth=0, threshold=10000)
    return Dict(
        "name" => node.name,
        "value" => node.self_value,
        "children" => if depth > threshold
            []
        else
            [as_json(child; depth=depth+1, threshold=threshold) for child in node.children]
        end
    )
end