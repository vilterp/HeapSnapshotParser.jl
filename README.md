# HeapSnapshotParser.jl

Parse heap snapshots in the Chrome/V8 JSON format, documented here: https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/memory-problems/heap-snapshot-schema

## Usage

In Julia 1.9+:

```julia
# Take snapshot
using Profile
path = "foo.heapsnapshot"
Profile.take_heap_snapshot(path)

# Load snapshot
using HeapSnapshotParser
snapshot = HeapSnapshotParser.parse_snapshot(path)

# Visualize with PProf
spanning_tree = HeapSnapshotParser.get_spanning_tree(snapshot)
# slim down the tree
top_tree = HeapSnapshotParser.top_tree(spanning_tree; top_n=3, max_depth=50)
HeapSnapshotParser.pprof(snapshot, top_tree)
```
