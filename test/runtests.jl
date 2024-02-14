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
    "num_children": 6,
    "self_value": 0,
    "total_value": 2304,
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
    "num_children": 8,
    "self_value": 0,
    "total_value": 14658045,
    "children": [
        {
            "name": "<internal>: Main",
            "num_children": 28,
            "self_value": 624,
            "total_value": 14655740,
            "children": [
                {
                    "name": "<native>: Base",
                    "num_children": 2,
                    "self_value": 48,
                    "total_value": 14586244,
                    "children": []
                },
                {
                    "name": "<hidden>: <inline>",
                    "num_children": 0,
                    "self_value": 65536,
                    "total_value": 65536,
                    "children": []
                },
                {
                    "name": "<native>: Revise",
                    "num_children": 1,
                    "self_value": 48,
                    "total_value": 1712,
                    "children": []
                },
                {
                    "name": "<native>: #1#2",
                    "num_children": 1,
                    "self_value": 48,
                    "total_value": 351,
                    "children": []
                },
                {
                    "name": "<native>: time_ns",
                    "num_children": 1,
                    "self_value": 48,
                    "total_value": 80,
                    "children": []
                }
            ]
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

@testset "sccs" begin
    snapshot = HeapSnapshotParser.parse_snapshot("../empty-2.heapsnapshot")
    lightgraph = HeapSnapshotParser.as_lightgraph(snapshot)
end

