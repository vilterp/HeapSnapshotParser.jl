using HeapSnapshotParser
using Test
using JSON

@testset "tiny" begin
    snapshot, indexed = HeapSnapshotParser.parse_snapshot("../testdata/tiny.heapsnapshot")
    @test length(snapshot.nodes) > 0
    @test length(snapshot.edges) > 0

    @info "getting flame graph"

    flame_graph = HeapSnapshotParser.get_flame_graph(snapshot, indexed)
    @test length(flame_graph.children) > 0
    @test flame_graph.parent === nothing
    # @test flame_graph.total_value > 0

    dict = HeapSnapshotParser.as_json(flame_graph; max_depth=1)
    @test length(dict["children"]) > 0
    
    println(JSON.json(dict, 4))
    
    expected = (
"""{
    "name": "",
    "num_children": 5,
    "self_value": 0,
    "total_value": 1920,
    "children": [
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
    snapshot, indexed = HeapSnapshotParser.parse_snapshot("../Snapshot.heapsnapshot")
    @test length(snapshot.nodes) > 0
    @test length(snapshot.edges) > 0
    
    @info "getting flame graph"

    flame_graph = HeapSnapshotParser.get_flame_graph(snapshot, indexed)
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
