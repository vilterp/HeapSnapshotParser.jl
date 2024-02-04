module HeapSnapshotParser

using JSON3
using StructEquality

include("raw-snapshot.jl")

#                    ,8,     4314,   4474241184,    57, 0,            0,               0
const NODE_FIElDS = ["type", "name", "id", "self_size", "edge_count", "trace_node_id", "detachedness"]
const NUM_NODE_FIELDS = length(NODE_FIElDS)

const EDGE_FIELDS = ["type", "name_or_index", "to_node"]
const NUM_EDGE_FIELDS = length(EDGE_FIELDS)

function parse_snapshot(file_path::String)
    contents = Base.read(file_path)
    stream = Stream(contents)
    return pull_snapshot(stream)
end

include("flame-graph.jl")
include("util.jl")
include("pull-json.jl")
include("pull-snapshot.jl")

end # module
