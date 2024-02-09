function top_tree(node::TreeNode; top_n=10, cur_depth=0, max_depth=10000)
    if cur_depth > max_depth
        return TreeNode(
            node.node,
            node.retainers,
            node.attr_name,
            node.total_value,
            node.total_value,
            [],
        )
    end
    
    children_by_size = sort(node.children, by=x->x.total_value, rev=true)
    new_children = []
    
    new_total_size = 0
    
    rest_num = 0
    rest_total = 0
    rest_first_id = 0

    for child in children_by_size
        if length(new_children) >= top_n
            if rest_first_id == 0
                rest_first_id = child.node.id
            end
            rest_num += 1
            rest_total += child.total_value
            continue
        end
       
        new_total_size += child.total_value
        new_child = top_tree(child; top_n, cur_depth=cur_depth+1, max_depth)
        push!(new_children, new_child)
    end
    
    if rest_num > 0
        rest = TreeNode(
            RestNode(rest_num, rest_first_id),
            0, # TODO: this only applies to RawNode; shouldn't be required here
            "", # TODO: this only applies to RawNode; shouldn't be required here
            rest_total,
            rest_total,
            Vector{TreeNode}(),
        )
        push!(new_children, rest)
    end
    
    return TreeNode(
        node.node,
        node.retainers,
        node.attr_name,
        node.self_value,
        node.total_value,
        new_children,
    )
end

function size(node::TreeNode)
    i = 0
    visit(node) do node, stack
        i += 1
    end
    return i
end

function leaves(root::TreeNode)
    leaves = Vector{TreeNode}()
    i = 0
    visit(root) do node, stack
        i += 1
        if length(node.node.edge_indexes) == 0
            push!(leaves, node)
        end
    end
    return leaves
end

function max_depth(root::TreeNode)
    max_depth = 0
    visit(root) do node, stack
        max_depth = max(max_depth, length(stack.nodes))
    end
    return max_depth
end