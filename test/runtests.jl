using HeapSnapshotParser

# TODO: make this into an actual unit test
# at the moment just testing that it doesn't explode

heap = open("../testdata/empty-repl.heapsnapshot") do f
    HeapSnapshotParser.parse_snapshot(f)
end

graph = HeapSnapshotParser.to_lightgraph(heap)
plot = gplot(graph)
draw(PNG("heap.png"), plot)
