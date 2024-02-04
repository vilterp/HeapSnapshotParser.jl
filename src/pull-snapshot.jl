function pull_snapshot(stream::Stream)
    input = HeapSnapshotParser.PullJson(stream)
    snapshot = ParsedSnapshot()
    
    get_object_start(input)
    
    # snapshot
    expect_string(input, "snapshot")
    get_colon(input)
    skip_value(input)
    get_comma(input)
    
    # nodes
    @info "nodes"
    expect_string(input, "nodes")
    get_colon(input)
    get_array_start(input)
    edge_index = 1
    while true
        node, num_edges = pull_node(input, edge_index)
        push!(snapshot.nodes, node)
        
        edge_index += num_edges

        munch_whitespace(input.input)        
        char = peek(input.input, Char)
        if char == ']'
            break
        end
        if char == ','
            get_comma(input)
        end
    end
    get_array_end(input)

    get_comma(input)
    
    # edges
    @info "edges"
    expect_string(input, "edges")
    get_colon(input)
    get_array_start(input)
    while true
        edge = pull_edge(input)
        push!(snapshot.edges, edge)

        munch_whitespace(input.input)        
        char = peek(input.input, Char)
        if char == ']'
            break
        end
        if char == ','
            get_comma(input)
        end
    end
    get_array_end(input)
    get_comma(input)
    
    # strings
    expect_string(input, "strings")
    get_colon(input)
    get_array_start(input)
    while true
        str = get_string(input)
        push!(snapshot.strings, str)

        munch_whitespace(input.input)        
        char = peek(input.input, Char)
        if char == ']'
            break
        end
        if char == ','
            get_comma(input)
        end
    end
    get_array_end(input)
    
    get_object_end(input)
    
    return snapshot
end

function pull_edge(input::PullJson)
    kind = get_int(input, whitespace=false)
    get_comma(input, whitespace=false)
    
    name = get_int(input, whitespace=false)
    get_comma(input, whitespace=false)
    
    to = get_int(input)
    
    return RawEdge(kind, name, to)
end

function pull_node(input::PullJson, edge_index::Int)
    kind = get_int(input, whitespace=false)
    get_comma(input, whitespace=false)
    
    name = get_int(input, whitespace=false)
    get_comma(input, whitespace=false)
    
    id = get_int(input, whitespace=false)
    get_comma(input, whitespace=false)
    
    self_size = get_int(input, whitespace=false)
    get_comma(input, whitespace=false)
    
    num_edges = get_int(input, whitespace=false)
    get_comma(input, whitespace=false)
    
    trace_node_id = get_int(input, whitespace=false)
    get_comma(input, whitespace=false)
    
    detatchedness = get_int(input, whitespace=false)
    
    range = if num_edges == 0
        1:0
    else
        edge_index:(edge_index + num_edges)
    end
    
    node = RawNode(kind, name, id, self_size, range)
    
    return node, num_edges
end