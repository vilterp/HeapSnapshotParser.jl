using HeapSnapshotParser

# TODO: make this into an actual unit test
# at the moment just testing that it doesn't explode

open("../testdata/empty-repl.heapsnapshot") do f
    HeapSnapshotParser.parse_snapshot(f)
end
