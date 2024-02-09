import DataStructures

struct RestNode
    num::Int
    first_child_id::Int
end

mutable struct TreeNode
    node::Union{RawNode,RestNode}
    retainers::Int
    attr_name::Union{Nothing,String}
    self_value::Int
    total_value::Int
    children::Vector{TreeNode}
end

function TreeNode(node::RawNode)
    return TreeNode(node, 0, nothing, node.self_size, 0, Vector{TreeNode}())
end

function Base.show(io::IO, node::TreeNode)
    print(io, "TreeNode($(node.attr_name): $(node.node), $(node.self_value) self, $(node.total_value) total, $(length(node.children)) children)")
end

function assemble_tree_nodes(snapshot::ParsedSnapshot)
    tree_nodes = Dict{UInt64,TreeNode}()
    for (idx, node) in enumerate(snapshot.nodes)
        tree_nodes[idx] = TreeNode(node)
    end
    return tree_nodes
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
    "Base.IdDict{Any, Any}",
    "Core",
    "Any",
])

function get_spanning_tree(snapshot::ParsedSnapshot)
    @info "assembling tree nodes"
    
    @time tree_nodes = assemble_tree_nodes(snapshot)
    
    # deprioritize these types while computing spanning tree
    avoid_ids = Set{Int}()
    for name in AVOID_SET
        idx = findfirst(isequal(name), snapshot.strings)
        if idx !== nothing
            push!(avoid_ids, idx)
        end
    end

    # do BFS with priority queue
    seen = Set{UInt64}() # set of node indexes
    root_tree_node = tree_nodes[1]
    queue = DataStructures.PriorityQueue{TreeNode, Int}(Base.Order.Reverse)
    DataStructures.enqueue!(queue, root_tree_node, NORMAL_PRIORITY)
    
    i = 0
    @info "getting spanning tree"
    
    while !isempty(queue)
        i += 1
        
        if i % 100000 == 0
            @info "visited $i nodes"
        end
        
        node = DataStructures.dequeue!(queue)
        
        for edge_idx in node.node.edge_indexes
            edge = snapshot.edges[edge_idx]
            child = tree_nodes[edge.to]
            child.retainers += 1
            if edge.to in seen
                continue
            end
            
            push!(seen, edge.to)
            push!(node.children, child)
            child.attr_name = get_attr_name(snapshot, edge)
            
            priority = get_priority(avoid_ids, child.node)
            DataStructures.enqueue!(queue, child, priority)
        end
        
    end
    
    @info "computing sizes"
    compute_sizes!(root_tree_node)
    
    return root_tree_node
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

function compute_sizes!(root::TreeNode)
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

const NORMAL_PRIORITY = 1
const AVOID_PRIORITY = -1

function get_priority(avoid_set::Set{Int}, node::RawNode)
    if node.name in avoid_set
        return AVOID_PRIORITY
    end
    return NORMAL_PRIORITY
end

function visit(f::Function, root::TreeNode)
    stack = Stack()
    push!(stack, root)
    i = 0
    while !isempty(stack)
        i += 1
        
        if i % 100000 == 0
            @info "visited $i nodes"
        end
        
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

function get_id(node::TreeNode)
    if node.node isa RawNode
        return node.node.id
    end
    return node.node.first_child_id
end

function get_name(snapshot::ParsedSnapshot, node::TreeNode)
    if node.node isa RawNode
        node_name = snapshot.strings[node.node.name]
        num_out_edges = length(node.node.edge_indexes)
        suffix = "$(node_name) ($(format_bytes(node.total_value)) total size) ($num_out_edges out edges) ($(node.retainers) retainers)"
        return if node.attr_name === nothing
            suffix
        else
            "$(node.attr_name): $(suffix)"
        end
    end
    return "$(node.node.num) more ($(format_bytes(node.total_value)) total size)"
end
