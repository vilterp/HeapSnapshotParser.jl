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
flame_graph = HeapSnapshotParser.get_flame_graph(snapshot)
HeapSnapshotParser.pprof(snapshot, flame_graph)
```
