import HeapSnapshotParser

using Test
using JSON

@testset "JSON: pull parse" begin
    str = """{"a": 1, "b": [1, 2, 3]}"""
    stream = HeapSnapshotParser.Stream(Vector{UInt8}(str))
    input = HeapSnapshotParser.PullJson(stream)

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

@testset "pprof" begin
    snapshot = HeapSnapshotParser.parse_snapshot("../empty-2.heapsnapshot")
    flame_graph = HeapSnapshotParser.get_spanning_tree(snapshot)
    @info "making into pprof"
    pprof = HeapSnapshotParser.build_pprof(snapshot, flame_graph)
    @test length(pprof.sample) > 0
    @test length(pprof.location) > 0
end

@testset "tiny" begin
    snapshot = HeapSnapshotParser.parse_snapshot("../testdata/tiny.heapsnapshot")
    @test length(snapshot.nodes) > 0
    @test length(snapshot.edges) > 0

    @info "getting flame graph"

    flame_graph = HeapSnapshotParser.get_spanning_tree(snapshot)
    @test length(flame_graph.children) > 0
    # @test flame_graph.total_value > 0

    dict = HeapSnapshotParser.as_json(snapshot, flame_graph; max_depth=1)
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
            "name": "<internal>: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "<internal>: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "<internal>: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "<internal>: Task",
            "num_children": 0,
            "self_value": 384,
            "total_value": 384,
            "children": []
        },
        {
            "name": "<internal>: Task",
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
    snapshot = HeapSnapshotParser.parse_snapshot("../empty-2.heapsnapshot")
    @test length(snapshot.nodes) > 0
    @test length(snapshot.edges) > 0
    
    @info "getting flame graph"

    flame_graph = HeapSnapshotParser.get_spanning_tree(snapshot)
    @test length(flame_graph.children) > 0
    # @test flame_graph.total_value > 0
    
    dict = HeapSnapshotParser.as_json(snapshot, flame_graph; max_depth=1)
    @test length(dict["children"]) > 0
    
    println(JSON.json(dict, 4))
    
    expected = (
"""{
    "name": "",
    "num_children": 7,
    "self_value": 0,
    "total_value": 146430252,
    "children": [
        {
            "name": "<internal>: Main",
            "num_children": 32,
            "self_value": 624,
            "total_value": 146423677,
            "children": [
                {
                    "name": "<element>: Base",
                    "num_children": 6098,
                    "self_value": 624,
                    "total_value": 141562176,
                    "children": []
                },
                {
                    "name": "<element>: InteractiveUtils",
                    "num_children": 265,
                    "self_value": 624,
                    "total_value": 2298590,
                    "children": []
                },
                {
                    "name": "<element>: Profile",
                    "num_children": 308,
                    "self_value": 624,
                    "total_value": 1577903,
                    "children": []
                },
                {
                    "name": "<element>: Core",
                    "num_children": 337,
                    "self_value": 624,
                    "total_value": 647590,
                    "children": []
                },
                {
                    "name": "<element>: Revise",
                    "num_children": 678,
                    "self_value": 624,
                    "total_value": 331960,
                    "children": []
                }
            ]
        },
        {
            "name": "<internal>: Task",
            "num_children": 3,
            "self_value": 384,
            "total_value": 3514,
            "children": [
                {
                    "name": "<internal>: (stack frame)",
                    "num_children": 2,
                    "self_value": 1,
                    "total_value": 2793,
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
                    "name": "<internal>: (stack frame)",
                    "num_children": 0,
                    "self_value": 1,
                    "total_value": 1,
                    "children": []
                }
            ]
        },
        {
            "name": "<internal>: Task",
            "num_children": 2,
            "self_value": 384,
            "total_value": 941,
            "children": [
                {
                    "name": "donenotify: Base.GenericCondition{Base.Threads.SpinLock}",
                    "num_children": 2,
                    "self_value": 24,
                    "total_value": 528,
                    "children": []
                },
                {
                    "name": "<internal>: (stack frame)",
                    "num_children": 2,
                    "self_value": 1,
                    "total_value": 29,
                    "children": []
                }
            ]
        },
        {
            "name": "<internal>: Task",
            "num_children": 2,
            "self_value": 384,
            "total_value": 941,
            "children": [
                {
                    "name": "donenotify: Base.GenericCondition{Base.Threads.SpinLock}",
                    "num_children": 2,
                    "self_value": 24,
                    "total_value": 528,
                    "children": []
                },
                {
                    "name": "<internal>: (stack frame)",
                    "num_children": 2,
                    "self_value": 1,
                    "total_value": 29,
                    "children": []
                }
            ]
        },
        {
            "name": "<internal>: Task",
            "num_children": 1,
            "self_value": 384,
            "total_value": 411,
            "children": [
                {
                    "name": "<internal>: (stack frame)",
                    "num_children": 2,
                    "self_value": 1,
                    "total_value": 27,
                    "children": []
                }
            ]
        }
    ]
}
""")
    
    @test JSON.json(dict, 4) == expected
end

@testset "sccs" begin
    snapshot = HeapSnapshotParser.parse_snapshot("../empty-2.heapsnapshot")
    lightgraph = HeapSnapshotParser.as_lightgraph(snapshot)
end

