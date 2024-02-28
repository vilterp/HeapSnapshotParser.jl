function pull_snapshot(stream::Stream)
    input = HeapSnapshotParser.PullJson(stream)
    snapshot = ParsedSnapshot()
    
    edge_types = Vector{Symbol}()
    
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
                    push!(edge_types, Symbol(str))
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
    
    get_array(input) do
        str = get_string(input)
        push!(snapshot.strings, str)
    end
    
    get_object_end(input)
    
    return snapshot
end

function pull_edge(edge_types::Vector{Symbol}, input::PullJson)
    kind = get_int(input) + 1
    get_comma(input)
    
    name = get_int(input) + 1
    get_comma(input)
    
    to = div(get_int(input), NUM_NODE_FIELDS) + 1
    
    kind_sym = edge_types[kind]
    
    return RawEdge(kind_sym, name, to)
end

function pull_node(input::PullJson, edge_index::Int)
    kind = get_int(input) + 1
    get_comma(input)
    
    name = get_int(input) + 1
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
    
    # println((kind, name, id, self_size, num_edges, trace_node_id, detatchedness))
    
    range = edge_index:(edge_index + num_edges - 1)

    node = RawNode(kind, name, id, self_size, range)
    
    return node, num_edges
end