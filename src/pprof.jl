using ProtoBuf
using OrderedCollections
using CodecZlib
import PProf
import pprof_jll

using PProf.perftools.profiles: Profile, ValueType, Sample,
    Location, Line, Label

const PProfile = Profile
const Func = PProf.perftools.profiles.Function

const proc = Ref{Union{Base.Process, Nothing}}(nothing)

"""
    _enter!(dict::OrderedDict{T, Int64}, key::T) where T

Resolves from `key` to the index (zero-based) in the dict.
Useful for the Strings table

NOTE: We must use Int64 throughout this package (regardless of system word-size) b/c the
proto file specifies 64-bit integers.
"""
function _enter!(dict::OrderedDict{String, Int64}, key::String)
    return get!(dict, key, Int64(length(dict)))
end

function build_pprof(snapshot::ParsedSnapshot, root::FlameNode; sample_denom::Int = 100)
    string_table = OrderedDict{String, Int64}()
    enter!(string) = _enter!(string_table, string)
    enter!(::Nothing) = _enter!(string_table, "nothing")
    ValueType!(_type, unit) = ValueType(enter!(_type), enter!(unit))
    Label!(key, value, unit) = Label(key = enter!(key), num = value, num_unit = enter!(unit))
    Label!(key, value) = Label(key = enter!(key), str = enter!(string(value)))

    # Setup:
    enter!("")  # NOTE: pprof requires first entry to be ""
    # Functions need a uid, we'll use the pointer for the method instance
    funcs = Dict{UInt64, Func}()

    locs = Dict{UInt64, Location}()
    samples = Vector{Sample}()

    sample_type = [
        ValueType!("events", "count"), # Mandatory
        ValueType!("size", "bytes"),
    ]

    period_type = ValueType!("heap", "bytes")

    # All samples get the same value for CPU profiles.
    value = [
        1,      # events
    ]

    lastwaszero = true  # (Legacy: used when has_meta = false)
    
    function enter_function(node::FlameNode)
        return get!(funcs, node.node.id) do
            id = sanitize_id(node.node.id)
            node_name = snapshot.strings[node.node.name]
            name = if node.attr_name === nothing
                node_name
            else
                "$(node.attr_name): $(node_name)"
            end
            return Func(
                id = id,
                name = enter!(name),
            )
        end
    end

    function enter_location(node::FlameNode)
        return get!(locs, node.node.id) do
            id = sanitize_id(node.node.id)
            func = enter_function(node)
            return Location(
                id = id,
                line = [
                    Line(function_id = func.id),
                ],
            )
        end
    end
    
    i = 0
    visit(root) do node, stack
        cur = i
        i += 1
        
        if cur % sample_denom != 0
            return
        end
        
        sample = Sample(
            location_id = [
                enter_location(node).id
                for node in Iterators.reverse(nodes_vector(stack))
            ],
            value = value,
            label = [
                Label!("self", node.self_value, "bytes"),
            ],
        )
        push!(samples, sample)
    end

    # If from_c=false funcs and locs should NOT contain C functions
    prof = PProfile(
        sample_type = sample_type,
        sample = samples,
        location = collect(values(locs)),
        var"#function" = collect(values(funcs)),
        string_table = collect(keys(string_table)),
        default_sample_type = 1, # events
    )
    
    return prof
end

function sanitize_id(id::Int)
    if id == 0
        return 1
    else
        return id
    end
end

"""
    pprof(
        flame_graph::FlameNode;
        web = true, webhost = "localhost", webport = 57599,
        out = "profile.pb.gz"
    )

Fetches the collected `Profile` data, exports to the `pprof` format, and (optionally) opens
a `pprof` web-server for interactively viewing the results.

If `web=true`, the web-server is opened in the background. Re-running `pprof()` will refresh
the web-server to use the new output.

If you manually edit the output file, `PProf.refresh()` will refresh the server without
overwriting the output file. `PProf.kill()` will kill the server.

You can also use `PProf.refresh(file="...")` to open a new file in the server.

# Arguments:
- `flame_graph::FlameNode`

# Keyword Arguments
- `web::Bool`: Whether to launch the `go tool pprof` interactive webserver for viewing results.
- `webhost::AbstractString`: If using `web`, which host to launch the webserver on.
- `webport::Integer`: If using `web`, which port to launch the webserver on.
- `out::String`: Filename for output.
- `ui_relative_percentages`: Passes `-relative_percentages` to pprof. Causes nodes
  ignored/hidden through the web UI to be ignored from totals when computing percentages.
"""
function pprof(
    snapshot::ParsedSnapshot,
    flame_graph::FlameNode;
    web::Bool = true,
    webhost::AbstractString = "localhost",
    webport::Integer = 60000,
    out::AbstractString = "profile.pb.gz",
    ui_relative_percentages::Bool = true,
)
    prof = build_pprof(snapshot, flame_graph)

    # Write to disk
    io = GzipCompressorStream(open(out, "w"))
    try
        ProtoBuf.encode(ProtoBuf.ProtoEncoder(io), prof)
    finally
        close(io)
    end

    if web
        refresh(webhost = webhost, webport = webport, file = out,
            ui_relative_percentages = ui_relative_percentages)
    end

    out
end

"""
    refresh(; webhost = "localhost", webport = 57599, file = "profile.pb.gz",
            ui_relative_percentages = true)

Start or restart the go pprof webserver.

- `webhost::AbstractString`: Which host to launch the webserver on.
- `webport::Integer`: Which port to launch the webserver on.
- `file::String`: Profile file to open.
- `ui_relative_percentages::Bool`: Passes `-relative_percentages` to pprof. Causes nodes
  ignored/hidden through the web UI to be ignored from totals when computing percentages.
"""
function refresh(; webhost::AbstractString = "localhost",
                   webport::Integer = 57599,
                   file::AbstractString = "profile.pb.gz",
                   ui_relative_percentages::Bool = true,
                )

    if proc[] === nothing
        # The first time, register an atexit hook to kill the web server.
        atexit(PProf.kill)
    else
        # On subsequent calls, restart the pprof web server.
        Base.kill(proc[])
    end

    relative_percentages_flag = ui_relative_percentages ? "-relative_percentages" : ""

    proc[] = pprof_jll.pprof() do pprof_path
        open(pipeline(`$pprof_path -http=$webhost:$webport $relative_percentages_flag $file`))
    end
end

"""
    PProf.kill()

Kills the pprof server if running.
"""
function kill()
    if proc[] !== nothing
        Base.kill(proc[])
        proc[] = nothing
    end
end
