using HeapSnapshotParser

# TODO: make this into an actual unit test

open("testdata/empty-repl.heapsnapshot") do f
    HeapSnapshotParser.parse_snapshot(f)
end
