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

function parse_int(input::IO)::Int
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
