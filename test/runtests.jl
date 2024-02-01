using HeapSnapshotParser
using Test

# TODO: make this into an actual unit test
# at the moment just testing that it doesn't explode

snapshot = HeapSnapshotParser.parse_snapshot("../testdata/empty-repl.heapsnapshot")
@test length(snapshot.nodes) > 0
@test length(snapshot.edges) > 0