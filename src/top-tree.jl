function top_tree(node::FlameNode, top_pct::Float64=0.75)
    children_by_size = sort(node.children, by=x->x.total_value, rev=true)
    new_children = []
    
    goal_size = node.total_value * top_pct
    new_total_size = 0
    for child in children_by_size
        if new_total_size >= goal_size
            break
        end
       
        new_total_size += child.total_value
        new_child = top_tree(child, top_pct)
        push!(new_children, new_child)
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