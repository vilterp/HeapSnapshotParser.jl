struct Stack
    nodes::Vector{TreeNode}
    child_indices::Vector{Int}

    function Stack()
        return new(Vector{TreeNode}(), Vector{Int}())
    end
end

function Base.push!(stack::Stack, node::TreeNode)
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
