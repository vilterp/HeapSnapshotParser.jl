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
    while true
        node = pull_node(input)
        push!(snapshot.nodes, node)

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
    kind = get_int(input)
    get_comma(input)
    
    name = get_int(input)
    get_comma(input)
    
    to = get_int(input)
    
    return RawEdge(kind, name, to)
end

function pull_node(input::PullJson)
    kind = get_int(input)
    get_comma(input)
    
    name = get_int(input)
    get_comma(input)
    
    id = get_int(input)
    get_comma(input)
    
    self_size = get_int(input)
    get_comma(input)
    
    num_edges = get_int(input)
    get_comma(input)
    
    trace_node_id = get_int(input)
    get_comma(input)
    
    detatchedness = get_int(input)
    
    return RawNode(kind, name, id, self_size, num_edges)
end