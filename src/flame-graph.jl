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
    print(io, "FlameNode($(node.node), $(length(node.children)) children)")
end

function get_flame_graph(snapshot::HeapSnapshot)
    nodes = Dict{UInt64,FlameNode}()
    for node in values(snapshot.nodes)
        nodes[node.id] = FlameNode(node, node.self_size)
    end
    
    # do DFS
    seen = Set{UInt64}()
    root_flame_node = nodes[0]
    stack = [root_flame_node]
    
    @info "doing DFS"
    @info "starting with node" root_flame_node.node.id
    
    while !isempty(stack)
        node = pop!(stack)
        if in(node.node.id, seen)
            continue
        end
        push!(seen, node.node.id)
        
        if length(stack) > 0
            parent = stack[end]
            @info "marking $(parent.node.id) as the parent of $(node.node.id)"
            node.parent = parent
            push!(parent.children, node)
        end
        
        i = 0
        for edge in node.node.out_edges
            child = nodes[edge.to.id]
            push!(stack, child)

            i += 1
        end
    end
    
    @info "computing sizes"
    
    compute_sizes!(root_flame_node)
    
    return root_flame_node
end

function find_unique_edge_name(node::FlameNode, name::String)
    if !haskey(node.children, name)
        return name
    end
    i = 1
    while true
        new_name = "$name-$i"
        if !haskey(node.children, new_name)
            return new_name
        end
        i += 1
    end
end

mutable struct StackFrame
    node::FlameNode
    child_index::Int
end

function StackFrame(node::FlameNode)
    return StackFrame(node, 1)
end

function compute_sizes!(root::FlameNode)
    # visit all nodes
    iteration = 0
    stack = [StackFrame(root)]
    while !isempty(stack)
        iteration += 1
        
        frame = stack[end]
        node = frame.node
        
        if iteration % 1000 == 0
            @info "iteration" iteration depth=length(stack) id=frame.node.node.id
        end
        
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