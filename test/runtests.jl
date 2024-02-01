using HeapSnapshotParser
using Test

# TODO: make this into an actual unit test
# at the moment just testing that it doesn't explode

snapshot = HeapSnapshotParser.parse_snapshot("../testdata/empty-repl.heapsnapshot")
# snapshot = HeapSnapshotParser.parse_snapshot("Snapshot.heapsnapshot")
@test length(snapshot.nodes) > 0
@test length(snapshot.edges) > 0

flame_graph = HeapSnapshotParser.get_flame_graph(snapshot)
@test length(flame_graph.children) > 0
@test flame_graph.parent === nothing
@test flame_graph.self_value > 0
@test flame_graph.total_value > 0
