import HeapSnapshotParser

using HeapSnapshotParser: node_indexes, edge_indexes
using Test
using JSON

@testset "pull parse" begin
    input = HeapSnapshotParser.PullJson(IOBuffer("""{"a": 1, "b": [1, 2, 3]}"""))
    @test HeapSnapshotParser.get_object_start(input) === nothing
    @test HeapSnapshotParser.get_string(input) == "a"
    @test HeapSnapshotParser.get_colon(input) === nothing
    @test HeapSnapshotParser.get_int(input) == 1
    @test HeapSnapshotParser.get_comma(input) === nothing
    @test HeapSnapshotParser.get_string(input) == "b"
    @test HeapSnapshotParser.get_colon(input) === nothing
    @test HeapSnapshotParser.get_array_start(input) === nothing
    @test HeapSnapshotParser.get_int(input) == 1
    @test HeapSnapshotParser.get_comma(input) === nothing
    @test HeapSnapshotParser.get_int(input) == 2
    @test HeapSnapshotParser.get_comma(input) === nothing
    @test HeapSnapshotParser.get_int(input) == 3
    @test HeapSnapshotParser.get_array_end(input) === nothing
    @test HeapSnapshotParser.get_object_end(input) === nothing
end

@testset "streaming parse" begin
    path = "../testdata/tiny.heapsnapshot"
    file = open(path, "r")
    stream = HeapSnapshotParser.JSONStream(file)
    # TODO: get Base.iterate to work
    tokens = []
    while true
        ret = iterate(stream)
        if ret === nothing
            break
        end
        next, st = ret
        push!(tokens, next)
    end
    @test length(tokens) > 0
    @test tokens[1] == HeapSnapshotParser.JSONObjectStart()
    @test tokens[end] == HeapSnapshotParser.JSONObjectEnd()
end

@testset "tiny" begin
    snapshot = HeapSnapshotParser.parse_snapshot("../testdata/tiny.heapsnapshot")
    @test length(snapshot.nodes) > 0
    @test length(snapshot.edges) > 0

    @info "getting flame graph"

    flame_graph = HeapSnapshotParser.get_flame_graph(snapshot)
    @test length(flame_graph.children) > 0
    @test flame_graph.parent === nothing
    # @test flame_graph.total_value > 0

    dict = HeapSnapshotParser.as_json(flame_graph; max_depth=1)
    @test length(dict["children"]) > 0
    
    println(JSON.json(dict, 4))
    
    expected = (
"""{
    "name": "",
    "num_children": 6,
    "self_value": 0,
    "total_value": 2304,
    "children": [
        {
            "name": "current task: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "root task: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "current task: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "root task: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "current task: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        }
    ]
}
""")
    
    @test JSON.json(dict, 4) == expected
end

@testset "big" begin
    snapshot = HeapSnapshotParser.parse_snapshot("../Snapshot.heapsnapshot")
    @test length(snapshot.nodes) > 0
    @test length(snapshot.edges) > 0
    
    @info "getting flame graph"

    flame_graph = HeapSnapshotParser.get_flame_graph(snapshot)
    @test length(flame_graph.children) > 0
    @test flame_graph.parent === nothing
    # @test flame_graph.total_value > 0
    
    dict = HeapSnapshotParser.as_json(flame_graph; max_depth=1)
    @test length(dict["children"]) > 0
    
    println(JSON.json(dict, 4))
    
    expected = (
"""{
    "name": "",
    "num_children": 4,
    "self_value": 0,
    "total_value": 146190524,
    "children": [
        {
            "name": "root task: Task",
            "num_children": 3,
            "self_value": 384,
            "total_value": 146189345,
            "children": [
                {
                    "name": "stack: (stack frame)",
                    "num_children": 2,
                    "self_value": 1,
                    "total_value": 146188624,
                    "children": []
                },
                {
                    "name": "storage: Base.IdDict{Any, Any}",
                    "num_children": 1,
                    "self_value": 32,
                    "total_value": 336,
                    "children": []
                },
                {
                    "name": "stack: (stack frame)",
                    "num_children": 0,
                    "self_value": 1,
                    "total_value": 1,
                    "children": []
                }
            ]
        },
        {
            "name": "root task: Task",
            "num_children": 1,
            "self_value": 384,
            "total_value": 411,
            "children": [
                {
                    "name": "stack: (stack frame)",
                    "num_children": 2,
                    "self_value": 1,
                    "total_value": 27,
                    "children": []
                }
            ]
        },
        {
            "name": "root task: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "root task: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        }
    ]
}
""")
    
    @test JSON.json(dict, 4) == expected
end
