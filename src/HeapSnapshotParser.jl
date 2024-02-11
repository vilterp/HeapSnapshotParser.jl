module HeapSnapshotParser

import Mmap

include("raw-snapshot.jl")

#                    ,8,     4314,   4474241184,    57, 0,            0,               0
const NODE_FIElDS = ["type", "name", "id", "self_size", "edge_count", "trace_node_id", "detachedness"]
const NUM_NODE_FIELDS = length(NODE_FIElDS)

const EDGE_FIELDS = ["type", "name_or_index", "to_node"]
const NUM_EDGE_FIELDS = length(EDGE_FIELDS)

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
include("sccs.jl")
include("top-tree.jl")
include("sparse-matrix.jl")

function get_out_edges(snapshot::ParsedSnapshot, node::RawNode)
    edges = snapshot.edges[node.edge_indexes]
    return Dict(
        snapshot.strings[edge.name] => snapshot.nodes[edge.to]
        for edge in edges
    )
end

end # module
