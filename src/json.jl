function as_json(snapshot::ParsedSnapshot, node::TreeNode; cur_depth=0, max_depth=10000)
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
function get_relevant_children(node::TreeNode; cur_depth=0, max_depth=10000, top_n=5)
    if cur_depth > max_depth
        return []
    end
    sorted = sort(node.children, by=child -> child.total_value, rev=true)
    return first(sorted, top_n)
end
