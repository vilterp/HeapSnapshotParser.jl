module HeapSnapshotParser

import Mmap

include("raw-snapshot.jl")

const NODE_FIELDS = ["type", "name", "id", "self_size", "edge_count", "trace_node_id", "detachedness"]
const NUM_NODE_FIELDS = length(NODE_FIELDS)

function parse_snapshot(path::String)
    open(path) do file
        contents = Mmap.mmap(file)
        stream = Stream(contents)
        return pull_snapshot(stream)
    end
end

include("spanning-tree.jl")
include("parse-util.jl")
include("pull-json.jl")
include("pull-snapshot.jl")
include("stack.jl")
include("pprof.jl")
include("json.jl")
include("sccs.jl")
include("top-tree.jl")

function get_out_edges(snapshot::ParsedSnapshot, node::RawNode)
    edges = snapshot.edges[node.edge_indexes]
    return Dict(
        snapshot.strings[edge.name] => snapshot.nodes[edge.to]
        for edge in edges
    )
end

end # module
