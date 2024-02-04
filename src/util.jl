mutable struct Stream
    data::Vector{UInt8}
    pos::Int
    
    function Stream(data::Vector{UInt8})
        return new(data, 1)
    end
end

function Base.show(io::IO, s::Stream)
    print(io, "Stream($(length(s.data)) chars, pos $(s.pos))")
end

function peek(stream::Stream, T)
    return Char(stream.data[stream.pos])
end

function read(stream::Stream, T)
    c = stream.data[stream.pos]
    stream.pos += 1
    return Char(c)
end

# === expect ===

function expect_read(input::Stream, expected::Char)
    got = read(input, Char)
    if got != expected
        error("expected $expected; got $got")
    end
end

# === parse ===

function parse_string(input::Stream)
    expect_read(input, '"')
    chars = Char[]
    while true
        c = read(input, Char)
        if c == '"'
            return String(chars)
        elseif c == '\\'
            c = read(input, Char)
            if c == 'n'
                push!(chars, '\n')
            elseif c == 't'
                push!(chars, '\t')
            elseif c == 'r'
                push!(chars, '\r')
            elseif c == 'u'
                hex = Char[]
                for i = 1:4
                    push!(hex, read(input, Char))
                end
                push!(chars, Char(parse(Int, String(hex), base=16)))
            else
                push!(chars, c)
            end
        else
            push!(chars, c)
        end
    end
end

function parse_int(input::Stream)::Int
    val = 0
    while true
        c = peek(input, Char)
        if isdigit(c)
            read(input, Char)
            val *= 10
            val += parse(Int, c)
        else
            return val
        end
    end
end

function munch_whitespace(input::Stream)
    while true
        c = peek(input, Char)
        if isspace(c)
            read(input, Char)
        else
            return
        end
    end
end
