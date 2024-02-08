function pull_snapshot(stream::Stream)
    input = HeapSnapshotParser.PullJson(stream)
    snapshot = ParsedSnapshot()
    
    edge_types = Vector{String}()
    
    get_object_start(input)
    
    # snapshot
    expect_string(input, "snapshot")
    get_colon(input)
    get_object_start(input)
    begin
        expect_string(input, "meta")
        get_colon(input)
        get_object_start(input)
        begin
            expect_string(input, "node_fields")
            get_colon(input)
            skip_value(input)
            get_comma(input)
            
            expect_string(input, "node_types")
            get_colon(input)
            skip_value(input)
            get_comma(input)

            expect_string(input, "edge_fields")
            get_colon(input)
            skip_value(input)
            get_comma(input)
            
            expect_string(input, "edge_types")
            get_colon(input)
            get_array_start(input)
            begin
                get_array(input) do
                    str = get_string(input)
                    push!(edge_types, str)
                end
                get_comma(input)

                skip_value(input)
                get_comma(input)
                skip_value(input)
            end
            get_array_end(input)
        end
        get_object_end(input)
        
        get_comma(input)
        expect_string(input, "node_count")
        get_colon(input)
        node_count = get_int(input)
        
        get_comma(input)
        expect_string(input, "edge_count")
        get_colon(input)
        edge_count = get_int(input)
    end
    get_object_end(input)
    get_comma(input)
    
    # nodes
    @info "nodes"
    expect_string(input, "nodes")
    get_colon(input)
    
    edge_index = 1
    get_array(input) do
        node, num_edges = pull_node(input, edge_index)
        push!(snapshot.nodes, node)
        
        edge_index += num_edges
    end
    get_comma(input)
    
    # edges
    @info "edges"
    expect_string(input, "edges")
    get_colon(input)
    
    get_array(input) do
        edge = pull_edge(edge_types, input)
        push!(snapshot.edges, edge)
    end
    get_comma(input)
    
    # strings
    @info "strings"
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

function pull_edge(edge_types::Vector{String}, input::PullJson)
    kind = get_int(input, whitespace=false) + 1
    get_comma(input, whitespace=false)
    
    name = get_int(input, whitespace=false) + 1
    get_comma(input, whitespace=false)
    
    to = div(get_int(input), NUM_NODE_FIELDS) + 1
    
    kind_sym = Symbol(edge_types[kind])
    
    return RawEdge(kind_sym, name, to)
end

function pull_node(input::PullJson, edge_index::Int)
    kind = get_int(input, whitespace=false) + 1
    get_comma(input, whitespace=false)
    
    name = get_int(input, whitespace=false) + 1
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