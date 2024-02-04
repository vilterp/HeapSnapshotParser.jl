using Parsers

struct JSONStream
    input::PeekableStream
end

function JSONStream(input::IO) 
    JSONStream(input)
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

function Base.iterate(stream::JSONStream)
    c = peek(stream.input)
    if c == eof(stream.input)
        return nothing
    end
    return parse_token(stream, c)
end

function parse_token(stream::JSONStream, c::Char)
    if c == 't'
        read(stream.input)
        read(stream.input) == 'r' || error("expected 'r'")
        read(stream.input) == 'u' || error("expected 'u'")
        read(stream.input) == 'e' || error("expected 'e'")
        return JSONBool(true)
    elseif c == 'f'
        read(stream.input)
        read(stream.input) == 'a' || error("expected 'a'")
        read(stream.input) == 'l' || error("expected 'l'")
        read(stream.input) == 's' || error("expected 's'")
        read(stream.input) == 'e' || error("expected 'e'")
        return JSONBool(false)
    elseif c == 'n'
        read(stream.input)
        read(stream.input) == 'u' || error("expected 'u'")
        read(stream.input) == 'l' || error("expected 'l'")
        read(stream.input) == 'l' || error("expected 'l'")
        return JSONNull()
    elseif c == '"'
        return JSONString(read_string(stream))
    elseif c == '['
        read(stream.input)
        return JSONArrayStart()
    elseif c == ']'
        read(stream.input)
        return JSONArrayEnd()
    elseif c == '{'
        read(stream.input)
        return JSONObjectStart()
    elseif c == '}'
        read(stream.input)
        return JSONObjectEnd()
    elseif c == ','
        read(stream.input)
        return JSONComma()
    elseif c == ':'
        read(stream.input)
        return JSONColon()
    elseif c in [' ', '\n', '\t', '\r']
        read(stream.input)
        return iterate(stream)
    else
        return JSONNumber(parse_number(stream, c))
    end
end
