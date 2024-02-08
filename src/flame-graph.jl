struct RestNode
    num::Int
end

mutable struct FlameNode
    node::Union{RawNode,RestNode}
    attr_name::Union{Nothing,String}
    self_value::Int
    total_value::Int
    parent::Union{FlameNode,Nothing}
    children::Vector{FlameNode}
end

function FlameNode(node::RawNode)
    return FlameNode(node, nothing, node.self_size, 0, nothing, Vector{FlameNode}())
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

function assemble_flame_nodes(snapshot::ParsedSnapshot)
    flame_nodes = Dict{UInt64,FlameNode}()
    for (idx, node) in enumerate(snapshot.nodes)
        flame_nodes[idx] = FlameNode(node)
    end
    return flame_nodes
end

const AVOID_SET = Set{String}([
    "Core.MethodTable",
    "Core.MethodInstance",
    "SimpleVector",
    "Core.TypeName",
    "GlobalRef",
    "TypeVar",
    "Method",
    "Task",
    "(stack frame)",
    "Base.Docs.Binding",
    "Base.Docs.DocStr",
    "Base.Docs.MultiDoc",
    "TOML_CACHE",
    "TOML",
    "Docs",
    "Revise",
    "loaded_modules",
    "Destructors",
])

function get_flame_graph(snapshot::ParsedSnapshot)
    @info "assembling flame nodes"
    
    @time flame_nodes = assemble_flame_nodes(snapshot)
    
    # avoid these types while computing spanning tree
    avoid_ids = Set(
        findfirst(isequal(str), snapshot.strings)
        for str in AVOID_SET
    )
    @info "avoid" AVOID_SET
    should_avoid = node -> node.name in avoid_ids
    
    # do DFS
    seen = Set{UInt64}() # set of node indexes
    root_flame_node = flame_nodes[1]
    stack = Stack()
    push!(stack, root_flame_node)
    
    i = 0
    @info "getting spanning tree"
    
    while !isempty(stack)
        i += 1
        node, child_index = top(stack)
        
        # pop the stack if we're done with this node
        at_last_child = child_index > length(node.node.edge_indexes)
        if at_last_child || should_avoid(node.node)
            pop!(stack)
            continue
        end
        
        # Look at the next edge
        edge_idx = node.node.edge_indexes[child_index]
        edge = snapshot.edges[edge_idx]
        increment!(stack)
        
        # Skip it if we've already seen it
        if in(edge.to, seen)
            continue
        end
        
        child = flame_nodes[edge.to]
        attr_name = get_attr_name(snapshot, edge)
        
        # Look at the next child
        push!(seen, edge.to)
        child.parent = node
        child.attr_name = attr_name
        push!(node.children, child)
        push!(stack, child)
    end
    
    @info "computing sizes"
    compute_sizes!(root_flame_node)
    
    return root_flame_node
end

function get_attr_name(snapshot::ParsedSnapshot, edge::RawEdge)
    if edge.kind == :property
        return snapshot.strings[edge.name]
    end
    if edge.kind == :internal
        return "<internal>"
    end
    if edge.kind == :element
        return "<element>"
    end
    if edge.kind == :hidden
        return "<hidden>"
    end
    error("unknown kind: $kind")
end

function compute_sizes!(root::FlameNode)
    stack = Stack()
    push!(stack, root)
    return_value = 0
    while !isempty(stack)
        node, child_index = top(stack)
        node.total_value += return_value
        return_value = 0
        
        if child_index > length(node.children)
            pop!(stack)
            return_value = node.total_value
            continue
        end
        
        child = node.children[child_index]
        increment!(stack)
        
        child.total_value = child.self_value
        push!(stack, child)
    end
end

function as_json(snapshot::ParsedSnapshot, node::FlameNode; cur_depth=0, max_depth=10000)
    children = get_relevant_children(node; cur_depth=cur_depth, max_depth=max_depth)
    node_name = snapshot.strings[node.node.name]
    return Dict(
        "name" => if node.attr_name === nothing
            node_name
        else
            "$(node.attr_name): $(node_name)"
        end,
        "self_value" => node.self_value,
        "total_value" => node.total_value,
        "num_children" => length(node.children),
        "children" => [
            as_json(snapshot, child; cur_depth=cur_depth+1, max_depth=max_depth)
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

# ====== stack
# TODO: not sure if this is worth it

struct Stack
    nodes::Vector{FlameNode}
    child_indices::Vector{Int}
    
    function Stack()
        return new(Vector{FlameNode}(), Vector{Int}())
    end
end

function Base.push!(stack::Stack, node::FlameNode)
    push!(stack.nodes, node)
    push!(stack.child_indices, 1)
end

function Base.pop!(stack::Stack)
    node = pop!(stack.nodes)
    idx = pop!(stack.child_indices)
    return (node, idx)
end

function increment!(stack::Stack)
    stack.child_indices[end] += 1
end

function Base.isempty(stack::Stack)
    return Base.isempty(stack.nodes)
end

function top(stack::Stack)
    return (
        stack.nodes[end],
        stack.child_indices[end],
    )
end

function nodes_vector(stack::Stack)
    return stack.nodes
end

function visit(f::Function, root::FlameNode)
    stack = Stack()
    push!(stack, root)
    while !isempty(stack)
        node, child_index = top(stack)
        
        f(node, stack)
        
        if child_index > length(node.children)
            pop!(stack)
            continue
        end
        
        child = node.children[child_index]
        increment!(stack)
        push!(stack, child)
    end
end