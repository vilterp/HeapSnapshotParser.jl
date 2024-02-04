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

# ==== read ====

function Base.iterate(stream::JSONStream, state=nothing)
    if eof(stream.input)
        return nothing
    end
    c = peek(stream.input, Char)
    token = parse_token(stream, c)
    return (token, nothing)
end

function parse_token(stream::JSONStream, c::Char)
    if c == 't'
        read(stream.input, Char)
        read(stream.input) == 'r' || error("expected 'r'")
        read(stream.input) == 'u' || error("expected 'u'")
        read(stream.input) == 'e' || error("expected 'e'")
        return JSONBool(true)
    elseif c == 'f'
        read(stream.input, Char)
        read(stream.input) == 'a' || error("expected 'a'")
        read(stream.input) == 'l' || error("expected 'l'")
        read(stream.input) == 's' || error("expected 's'")
        read(stream.input) == 'e' || error("expected 'e'")
        return JSONBool(false)
    elseif c == 'n'
        read(stream.input, Char)
        read(stream.input) == 'u' || error("expected 'u'")
        read(stream.input) == 'l' || error("expected 'l'")
        read(stream.input) == 'l' || error("expected 'l'")
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
    elseif c in [' ', '\n', '\t', '\r']
        read(stream.input, Char)
        return iterate(stream)
    else
        val = parse_int(stream.input)
        return JSONNumber(val)
    end
end

function parse_string(input::IO)
    chars = Char[]
    while true
        c = read(input, Char)
        if c == '"'
            return string(chars)
        elseif c == '\\'
            c = read(input, Char)
            if c == 'n'
                push(chars, '\n')
            elseif c == 't'
                push(chars, '\t')
            elseif c == 'r'
                push(chars, '\r')
            elseif c == 'u'
                error("TODO: parse unicode")
            else
                push(chars, c)
            end
        else
            str *= c
        end
    end
end

function parse_int(input::IO)
    val = 0
    while true
        c = read(input, Char)
        if c in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.']
            val *= 10
            val += parse(Int, c)
        else
            return val
        end
    end
end
