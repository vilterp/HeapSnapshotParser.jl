mutable struct FlameNode
    node::Node
    self_value::Int
    total_value::Int
    parent::Union{FlameNode,Nothing}
    # TODO: name for each child
    children::Vector{FlameNode}
end

function FlameNode(node::Node, self_size::Int)
    return FlameNode(node, self_size, 0, nothing, Vector{FlameNode}())
end

function Base.show(io::IO, node::FlameNode)
    print(io, "FlameNode($(node.node), $(node.self_value) self, $(node.total_value) total, $(length(node.children)) children)")
end

mutable struct StackFrame
    node::FlameNode
    child_index::Int
end

function StackFrame(node::FlameNode)
    return StackFrame(node, 1)
end

function get_flame_graph(snapshot::HeapSnapshot)
    flame_nodes = Dict{UInt64,FlameNode}()
    for node in values(snapshot.nodes)
        flame_nodes[node.id] = FlameNode(node, node.self_size)
    end
    
    # do DFS
    seen = Set{UInt64}()
    root_flame_node = flame_nodes[0]
    stack = [StackFrame(root_flame_node)]
    
    @info "doing DFS"
    
    while !isempty(stack)
        frame = stack[end]
        node = frame.node
        if frame.child_index > length(node.node.out_edges)
            pop!(stack)
            continue
        end
        edge = node.node.out_edges[frame.child_index]
        frame.child_index += 1
        if in(edge.to.id, seen)
            continue
        end
        push!(seen, edge.to.id)
        child = flame_nodes[edge.to.id]
        child.parent = node
        push!(node.children, child)
        push!(stack, StackFrame(child))
    end
    
    @info "computing sizes"
    
    compute_sizes!(root_flame_node)
    
    return root_flame_node
end

function compute_sizes!(root::FlameNode)
    # visit all nodes
    stack = [StackFrame(root)]
    while !isempty(stack)
        frame = stack[end]
        node = frame.node
        
        if frame.child_index > length(node.children)
            # done with this node
            pop!(stack)
            continue
        end
        child = frame.node.children[frame.child_index]
        frame.child_index += 1
        push!(stack, StackFrame(child))
    end
end

function as_json(node::FlameNode; depth=0, threshold=10000)
    return Dict(
        "name" => node.node.type,
        "self_value" => node.self_value,
        "total_value" => node.total_value,
        "num_children" => length(node.children),
        "children" => if depth >= threshold
            []
        else
            [
                as_json(child; depth=depth+1, threshold=threshold)
                for child in node.children
            ]
        end
    )
end