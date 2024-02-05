using ProtoBuf
using OrderedCollections
using CodecZlib
import pprof_jll

import PProf.perftools.profiles: Profile, ValueType, Sample, Function,
    Location, Line, Label

"""
    _enter!(dict::OrderedDict{T, Int64}, key::T) where T

Resolves from `key` to the index (zero-based) in the dict.
Useful for the Strings table

NOTE: We must use Int64 throughout this package (regardless of system word-size) b/c the
proto file specifies 64-bit integers.
"""
function _enter!(dict::OrderedDict{T, Int64}, key::T) where T
    return get!(dict, key, Int64(length(dict)))
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
function pprof(flame_graph::FlameNode,
               web::Bool = true,
               webhost::AbstractString = "localhost",
               webport::Integer = 60000,
               out::AbstractString = "profile.pb.gz",
               ui_relative_percentages::Bool = true,
            )

    string_table = OrderedDict{AbstractString, Int64}()
    enter!(string) = _enter!(string_table, string)
    enter!(::Nothing) = _enter!(string_table, "nothing")
    ValueType!(_type, unit) = ValueType(enter!(_type), enter!(unit))
    Label!(key, value, unit) = Label(key = enter!(key), num = value, num_unit = enter!(unit))
    Label!(key, value) = Label(key = enter!(key), str = enter!(string(value)))

    # Setup:
    enter!("")  # NOTE: pprof requires first entry to be ""
    # Functions need a uid, we'll use the pointer for the method instance
    seen_funcs = Set{UInt64}()
    funcs = Dict{UInt64, Function}()

    seen_locs = Set{UInt64}()
    locs  = Dict{UInt64, Location}()
    locs_from_c  = Dict{UInt64, Bool}()
    samples = Vector{Sample}()

    sample_type = [
        ValueType!("events",      "count"), # Mandatory
    ]

    period_type = ValueType!("cpu", "nanoseconds")
    drop_frames = isnothing(drop_frames) ? 0 : enter!(drop_frames)
    keep_frames = isnothing(keep_frames) ? 0 : enter!(keep_frames)
    # start decoding backtraces
    location_id = Vector{eltype(data)}()

    # All samples get the same value for CPU profiles.
    value = [
        1,      # events
    ]

    lastwaszero = true  # (Legacy: used when has_meta = false)

    XXXX

    # If from_c=false funcs and locs should NOT contain C functions
    prof = PProfile(
        sample_type = sample_type,
        sample = samples,
        location =  collect(values(locs)),
        var"#function" = collect(values(funcs)),
        string_table = collect(keys(string_table)),
        drop_frames = drop_frames,
        keep_frames = keep_frames,
        period_type = period_type,
        period = sampling_delay,
        default_sample_type = 1, # events
    )

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

function _escape_name_for_pprof(name)
    # HACK: Apparently proto doesn't escape func names with `"` in them ... >.<
    # TODO: Remove this hack after https://github.com/google/pprof/pull/564
    quoted = repr(string(name))
    quoted = quoted[2:thisind(quoted, end-1)]
    return quoted
end
function method_instance_id(frame)
    # `func_id` - Uniquely identifies this function (a method instance in julia, and
    # a function in C/C++).
    # Note that this should be unique even for several different functions all
    # inlined into the same frame.
    func_id = if frame.linfo !== nothing
        hash(frame.linfo)
    else
        hash((frame.func, frame.file, frame.line, frame.inlined))
    end
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
