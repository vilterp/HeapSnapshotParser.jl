using HeapSnapshotParser

# TODO: make this into an actual unit test
# at the moment just testing that it doesn't explode

HeapSnapshotParser.parse_snapshot("../testdata/empty-repl.heapsnapshot")

