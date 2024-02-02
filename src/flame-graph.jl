mutable struct FlameNode
    node::Node
    attr_name::Union{Nothing,String}
    self_value::Int
    total_value::Int
    parent::Union{FlameNode,Nothing}
    children::Vector{FlameNode}
end

function FlameNode(node::Node, self_size::Int)
    return FlameNode(node, nothing, self_size, 0, nothing, Vector{FlameNode}())
end

function Base.show(io::IO, node::FlameNode)
    print(io, "FlameNode($(node.attr_name): $(node.node), $(node.self_value) self, $(node.total_value) total, $(length(node.children)) children)")
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
    
    @info "getting spanning tree"
    
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
        child.attr_name = edge.name
        push!(node.children, child)
        
        push!(stack, StackFrame(child))
    end
    
    @info "computing sizes"
    
    compute_sizes!(root_flame_node)
    
    return root_flame_node
end

function compute_sizes!(root::FlameNode)
    stack = [StackFrame(root)]
    while !isempty(stack)
        frame = stack[end]
        node = frame.node
        
        if frame.child_index > length(node.children)
            pop!(stack)
            continue
        end
        
        child = node.children[frame.child_index]
        frame.child_index += 1
        
        push!(stack, StackFrame(child))
    end
end

function as_json(node::FlameNode; cur_depth=0, max_depth=10000)
    children = get_relevant_children(node; cur_depth=cur_depth, max_depth=max_depth)
    return Dict(
        "name" => if node.attr_name === nothing
            node.node.type
        else
            "$(node.attr_name): $(node.node.type)"
        end,
        "self_value" => node.self_value,
        "total_value" => node.total_value,
        "num_children" => length(node.children),
        "children" => [
            as_json(child; cur_depth=cur_depth+1, max_depth=max_depth)
            for child in children
        ]
    )
end

# return the top 10 nodes by total value
# TODO: "rest" node
function get_relevant_children(node::FlameNode; cur_depth=0, max_depth=10000, top_n=5)
    if cur_depth > max_depth
        return []
    end
    sorted = sort(node.children, by=child -> child.total_value, rev=true)
    return first(sorted, top_n)
end
