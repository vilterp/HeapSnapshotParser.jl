mutable struct FlameNode
    node::Node
    self_value::Int
    total_value::Int
    parent::Union{FlameNode,Nothing}
    children::Vector{FlameNode}
end

function FlameNode(node::Node)
    return FlameNode(node, 0, 0, nothing, [])
end

function get_flame_graph(snapshot::HeapSnapshot)
    nodes = Dict{UInt64,FlameNode}()
    for node in values(snapshot.nodes)
        nodes[node.id] = FlameNode(node)
    end
    # in-edges per node
    num_in_edges_per_node = Dict{UInt64,Int}()
    for edge in values(snapshot.edges)
        num_in_edges_per_node[edge.to.id] = get(num_in_edges_per_node, edge.to.id, 0) + 1
    end
    
    # find nodes with no in edges
    nodes_with_no_in_edges = Set{UInt64}()
    for node in values(snapshot.nodes)
        if !haskey(num_in_edges_per_node, node.id)
            push!(nodes_with_no_in_edges, node.id)
        end
    end
    
    @assert length(nodes_with_no_in_edges) == 1
    
    start_node = nodes[collect(nodes_with_no_in_edges)[1]]
    
    # do DFS
    seen = Set{UInt64}()
    stack = [start_node]
    
    while !isempty(stack)
        node = pop!(stack)
        if haskey(seen, node.node.id)
            continue
        end
        push!(seen, node.node.id)
        
        for edge in node.node.out_edges
            child = nodes[edge.to.id]
            child.parent = node
            push!(node.children, child)
            push!(stack, child)
        end
    end
    
    return start_node
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