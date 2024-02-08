function top_tree(node::FlameNode; top_pct::Float64=0.75)
    children_by_size = sort(node.children, by=x->x.total_value, rev=true)
    new_children = []
    
    goal_size = node.total_value * top_pct
    new_total_size = 0
    
    rest_num = 0
    rest_total = 0
    rest_first_id = 0

    for child in children_by_size
        if new_total_size >= goal_size
            if rest_first_id == 0
                rest_first_id = child.node.id
            end
            rest_num += 1
            rest_total += child.total_value
            continue
        end
       
        new_total_size += child.total_value
        new_child = top_tree(child; top_pct)
        push!(new_children, new_child)
    end
    
    if rest_num > 0
        rest = FlameNode(
            RestNode(rest_num, rest_first_id),
            "", # TODO: refactor this away
            rest_total,
            rest_total,
            node,
            Vector{FlameNode}(),
        )
        push!(new_children, rest)
    end
    
    return FlameNode(
        node.node,
        node.attr_name,
        node.self_value,
        node.total_value,
        node.parent,
        new_children,
    )
end

function size(node::FlameNode)
    i = 0
    visit(node) do node, stack
        i += 1
    end
    return i
end

function leaves(root::FlameNode)
    leaves = Vector{FlameNode}()
    i = 0
    visit(root) do node, stack
        i += 1
        if length(node.node.edge_indexes) == 0
            push!(leaves, node)
        end
    end
    return leaves
end
