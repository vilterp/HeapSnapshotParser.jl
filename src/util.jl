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

@inline function peek(stream::Stream, T)
    return Char(stream.data[stream.pos])
end

@inline function read(stream::Stream, T)
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
    start, finish = get_string_extent(input)
    
    return String(input.data[start+1:finish-1])
end

function get_string_extent(input::Stream)
    start = input.pos
    expect_read(input, '"')
    while true
        c = read(input, Char)
        if c == '"'
            return (start, input.pos-1)
        elseif c == '\\'
            read(input, Char)
        end
    end
end

# return the digit, or nothing if it's not a digit
function get_digit(char::Char)::Union{UInt8,Nothing}
    if '0' <= char <= '9'
        return UInt8(char) - UInt8('0')
    else
        return nothing
    end
end

function parse_int(input::Stream)::Int
    val = 0
    while true
        c = peek(input, Char)
        digit = get_digit(c)
        if digit === nothing
            return val
        else
            read(input, Char)
            val *= 10
            val += digit
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
