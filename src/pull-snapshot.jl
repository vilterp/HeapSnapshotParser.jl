function pull_snapshot(io::IO)
    input = HeapSnapshotParser.PullJson(io)
    
    get_object_start(input)
    
    # snapshot
    get_string(input)
    get_colon(input)
    skip_value(input)
    get_comma(input)
    
    # node_count
    get_string(input) == "node_count" || error("expected node_count")
    get_colon(input)
    get_int(input)
    get_comma(input)
    
    # edge_count
    get_string(input) == "edge_count" || error("expected edge_count")
    get_colon(input)
    get_int(input)
    get_comma(input)
    
    # nodes
    get_string(input) == "nodes" || error("expected nodes")
    get_colon(input)
    skip_array(input)
    get_comma(input)
    
    # edges
    get_string(input) == "edges" || error("expected edges")
    get_colon(input)
    skip_array(input)
    get_comma(input)
    
    # strings
    get_string(input) == "strings" || error("expected strings")
    get_colon(input)
    skip_array(input)
    
    get_object_end(input)
    
    return ParsedSnapshot()
end