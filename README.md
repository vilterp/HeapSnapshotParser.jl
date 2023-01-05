# HeapSnapshotParser.jl

Parse heap snapshots in the Chrome/V8 JSON format, documented here: https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/memory-problems/heap-snapshot-schema

## Usage

In Julia 1.9+:

```julia
using Profile
Profile.take_heap_snapshot("foo.heapsnapshot")

using HeapSnapshotParser
s = HeapSnapshotParser.parse_snapshot("foo.heapsnapshot")
```
