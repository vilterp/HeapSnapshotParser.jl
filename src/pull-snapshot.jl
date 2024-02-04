function pull_snapshot(io::IO)
    input = HeapSnapshotParser.PullJson(io)
    
    get_object_start(input)
    
    # snapshot
    expect_string(input, "snapshot")
    get_colon(input)
    skip_value(input)
    get_comma(input)
    
    # nodes
    expect_string(input, "nodes")
    get_colon(input)
    skip_array(input)
    get_comma(input)
    
    # edges
    expect_string(input, "edges")
    get_colon(input)
    skip_array(input)
    get_comma(input)
    
    # strings
    expect_string(input, "strings")
    get_colon(input)
    skip_array(input)
    
    get_object_end(input)
    
    return ParsedSnapshot()
end