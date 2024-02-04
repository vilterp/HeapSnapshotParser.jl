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
    open(file_path) do f
        return parse_snapshot(f)
    end
end

function parse_snapshot(input::IOStream)
    @info "parsing JSON"
    
    parsed = JSON3.read(input, RawSnapshot)
    indexed = assemble_snapshot(parsed)
    
    return indexed
end

function assemble_snapshot(raw::RawSnapshot)
    # TODO: preallocate node and edge arrays
    snapshot = ParsedSnapshot()

    @info "assembling nodes"
    
    node_kind_enum = raw.snapshot.meta.node_types[1]
    edge_kind_enum = raw.snapshot.meta.edge_types[1]

    nodes = raw.nodes
    strings = raw.strings
    num_nodes = convert(Int, length(nodes)/NUM_NODE_FIELDS)
    edge_idx = 1
    for node_idx = 0:(num_nodes-1)
        kind_key = nodes[node_idx*NUM_NODE_FIELDS + 1]
        name_key = nodes[node_idx*NUM_NODE_FIELDS + 2]
        id = nodes[node_idx*NUM_NODE_FIELDS + 3]
        self_size = nodes[node_idx*NUM_NODE_FIELDS + 4]
        num_edges = nodes[node_idx*NUM_NODE_FIELDS + 5]
        
        edges_range = if num_edges == 0
            1:0 # empty range
        else
            edge_idx:(edge_idx + num_edges)
        end

        node = RawNode(
            Symbol(node_kind_enum[kind_key + 1]),
            strings[name_key + 1],
            id,
            self_size,
            edges_range,
        )
        edge_idx += num_edges

        push!(snapshot.nodes, node)
    end
    
    @info "assembling edges"
    
    edges = raw.edges
    for (node_idx, from_node) in enumerate(snapshot.nodes)
        # @info "edges" from_node.edge_indexes
        for edge_idx in from_node.edge_indexes
            kind_key_idx = edge_idx*NUM_EDGE_FIELDS + 1
            if kind_key_idx > length(edges)
                @info(
                    "edge_idx out of range",
                    from_node.edge_indexes,
                    kind_key_idx,
                    node_idx,
                    length(snapshot.nodes),
                    length(snapshot.edges),
                )
                break
            end
            
            kind_key = edges[edge_idx*NUM_EDGE_FIELDS + 1]
            name_key = edges[edge_idx*NUM_EDGE_FIELDS + 2]
            to_key = edges[edge_idx*NUM_EDGE_FIELDS + 3]

            to_node_idx = div(to_key, NUM_NODE_FIELDS) + 1
            # @info "edge" from_node.id edge_idx to_node_idx

            kind = Symbol(edge_kind_enum[kind_key + 1])

            # name = if kind == :internal
            #     "<internal>"
            # elseif kind == :element
            #     "<element>"
            # else
            #     strings[name_key+1]
            # end
            name = strings[name_key+1]

            edge = RawEdge(
                kind,
                name,
                to_node_idx,
            )

            push!(snapshot.edges, edge)
        end
    end
    
    return snapshot
end

include("flame-graph.jl")
include("util.jl")
include("pull-json.jl")
include("streaming-json.jl")

end # module
