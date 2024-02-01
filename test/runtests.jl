using HeapSnapshotParser
using Test
using JSON

@testset "tiny" begin
    # snapshot = HeapSnapshotParser.parse_snapshot("../testdata/empty-repl.heapsnapshot")
    snapshot = HeapSnapshotParser.parse_snapshot("../testdata/tiny.heapsnapshot")
    @test length(snapshot.nodes) > 0
    @test length(snapshot.edges) > 0

    @info "getting flame graph"

    flame_graph = HeapSnapshotParser.get_flame_graph(snapshot)
    @test length(flame_graph.children) > 0
    @test flame_graph.parent === nothing
    # @test flame_graph.total_value > 0

    dict = HeapSnapshotParser.as_json(flame_graph; threshold=1)
    @test length(dict["children"]) > 0
    
    expected = (
"""{
    "name": "",
    "num_children": 6,
    "self_value": 0,
    "total_value": 0,
    "children": {
        "4: root task": {
            "name": "Task",
            "num_children": 0,
            "self_value": 0,
            "total_value": 0,
            "children": {}
        },
        "3: current task": {
            "name": "Task",
            "num_children": 0,
            "self_value": 0,
            "total_value": 0,
            "children": {}
        },
        "0: root task": {
            "name": "Task",
            "num_children": 0,
            "self_value": 0,
            "total_value": 0,
            "children": {}
        },
        "2: root task": {
            "name": "Task",
            "num_children": 0,
            "self_value": 0,
            "total_value": 0,
            "children": {}
        },
        "1: current task": {
            "name": "Task",
            "num_children": 0,
            "self_value": 0,
            "total_value": 0,
            "children": {}
        },
        "5: current task": {
            "name": "Task",
            "num_children": 0,
            "self_value": 0,
            "total_value": 0,
            "children": {}
        }
    }
}
""")
    
    @test JSON.json(dict, 4) == expected
end
