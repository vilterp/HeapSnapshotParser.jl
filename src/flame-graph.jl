mutable struct FlameNode
    node::Node
    self_value::Float64
    total_value::Float64
    parent::Union{FlameNode,Nothing}
    children::Vector{FlameNode}
end

function FlameNode(node::Node)
    return FlameNode(node, 0.0, 0.0, nothing, [])
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
            nodes[edge.dst] = FlameNode(seq_to_node[edge.dst])
        end
        push!(nodes_with_no_parent, edge.dst)
        if !haskey(nodes, edge.src)
            nodes[edge.src] = FlameNode(seq_to_node[edge.src])
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
        # update values
        cur = child
        cur.self_value += cur.node.self_size
        while cur != nothing
            cur.total_value += cur.node.self_size
            cur = cur.parent
        end
    end
    
    @assert length(nodes_with_no_parent) == 1
    
    root_id = collect(nodes_with_no_parent)[1]
    return nodes[root_id]
end

function as_json(node::FlameNode; depth=0, threshold=10000)
    return Dict(
        "name" => node.node.type,
        "self_value" => node.self_value,
        "total_value" => node.total_value,
        "children" => if depth > threshold
            []
        else
            [as_json(child; depth=depth+1, threshold=threshold) for child in node.children]
        end
    )
end