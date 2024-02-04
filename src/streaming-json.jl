import Parsers

struct JSONStream
    input::IO
end

# ==== tokens ===

abstract type JSONToken end

struct JSONBool <: JSONToken
    value::Bool
end

struct JSONNull <: JSONToken end

struct JSONNumber <: JSONToken
    value::Float64
end

struct JSONString <: JSONToken
    value::String
end

struct JSONArrayStart <: JSONToken
end

struct JSONArrayEnd <: JSONToken
end

struct JSONObjectStart <: JSONToken
end

struct JSONObjectEnd <: JSONToken
end

struct JSONComma <: JSONToken
end

struct JSONColon <: JSONToken
end

# ==== iterator ====

function Base.iterate(stream::JSONStream, state=nothing)
    if eof(stream.input)
        return nothing
    end
    munch_whitespace(stream.input)
    c = peek(stream.input, Char)
    token = parse_token(stream, c)
    ret = (token, nothing)
    return ret
end

Base.IteratorSize(::Type{JSONStream}) = Base.SizeUnknown()

Base.IteratorEltype(::Type{JSONStream}) = Base.HasEltype()

Base.eltype(::Type{JSONStream}) = JSONToken

# ==== parse ====

function parse_token(stream::JSONStream, c::Char)
    if c == 't'
        read(stream.input, Char)
        expect_read(stream.input, 'r')
        expect_read(stream.input, 'u')
        expect_read(stream.input, 'e')
        return JSONBool(true)
    elseif c == 'f'
        read(stream.input, Char)
        expect_read(stream.input, 'a')
        expect_read(stream.input, 'l')
        expect_read(stream.input, 's')
        expect_read(stream.input, 'e')
        return JSONBool(false)
    elseif c == 'n'
        read(stream.input, Char)
        expect_read(stream.input, 'u')
        expect_read(stream.input, 'l')
        expect_read(stream.input, 'l')
        return JSONNull()
    elseif c == '"'
        str = parse_string(stream.input)
        return JSONString(str)
    elseif c == '['
        read(stream.input, Char)
        return JSONArrayStart()
    elseif c == ']'
        read(stream.input, Char)
        return JSONArrayEnd()
    elseif c == '{'
        read(stream.input, Char)
        return JSONObjectStart()
    elseif c == '}'
        read(stream.input, Char)
        return JSONObjectEnd()
    elseif c == ','
        read(stream.input, Char)
        return JSONComma()
    elseif c == ':'
        read(stream.input, Char)
        return JSONColon()
    else
        val = parse_int(stream.input)
        return JSONNumber(val)
    end
end

const WHITESPACE = [' ', '\n', '\t', '\r']

function munch_whitespace(input::IO)
    while true
        c = peek(input, Char)
        if c in WHITESPACE
            read(input, Char)
        else
            return
        end
    end
end

function expect_read(input::IO, expected::Char)
    got = read(input, Char)
    if got != expected
        error("expected $expected; got $got")
    end
end

function parse_string(input::IO)
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
                error("TODO: parse unicode")
            else
                push!(chars, c)
            end
        else
            push!(chars, c)
        end
    end
end

function parse_int(input::IO)::Int
    val = 0
    while true
        c = read(input, Char)
        if isdigit(c)
            val *= 10
            val += parse(Int, c)
        else
            return val
        end
    end
end
