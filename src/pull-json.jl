# === json ===

struct PullJson
    input::Stream
end

# === skip ===

function skip_value(input::PullJson)
    munch_whitespace(input.input)
    c = peek(input.input, Char)
    if c == '{'
        return skip_object(input)
    elseif c == '['
        return skip_array(input)
    elseif c == '"'
        return get_string(input)
    elseif c == 't' || c == 'f'
        return get_bool(input)
    elseif c == 'n'
        return get_null(input)
    elseif isdigit(c) || c == '-'
        return get_int(input)
    else
        error("unexpected character: $c")
    end
end

function skip_object(input::PullJson)
    get_object_start(input)
    while true
        get_string(input)
        get_colon(input)
        skip_value(input)
        c = read(input.input, Char)
        if c == '}'
            return
        elseif c != ','
            error("expected , or } but got $c")
        end
    end
end

function skip_array(input::PullJson)
    get_array_start(input)
    while true
        skip_value(input)
        munch_whitespace(input.input)
        c = read(input.input, Char)
        if c == ']'
            return
        elseif c != ','
            error("expected , or ] but got $c")
        end
    end
end

# === get ===

function get_bool(input::PullJson)::Bool
    munch_whitespace(input.input)
    c = read(input.input, Char)
    if c == 't'
        expect_read(input.input, 'r')
        expect_read(input.input, 'u')
        expect_read(input.input, 'e')
        return true
    elseif c == 'f'
        expect_read(input.input, 'a')
        expect_read(input.input, 'l')
        expect_read(input.input, 's')
        expect_read(input.input, 'e')
        return false
    else
        error("expected t or f; got $c")
    end
end

function get_null(input::PullJson)
    munch_whitespace(input.input)
    expect_read(input.input, 'n')
    expect_read(input.input, 'u')
    expect_read(input.input, 'l')
    expect_read(input.input, 'l')
    return nothing
end

function get_string(input::PullJson)::String
    munch_whitespace(input.input)
    parse_string(input.input)
end

function get_int(input::PullJson; whitespace=true)::Int
    if whitespace
        munch_whitespace(input.input)
    end
    i = parse_int(input.input)
    return i
end

function get_array_start(input::PullJson)
    munch_whitespace(input.input)
    expect_read(input.input, '[')
    return nothing
end

function get_array_end(input::PullJson)
    munch_whitespace(input.input)
    expect_read(input.input, ']')
    return nothing
end

function get_object_start(input::PullJson)
    munch_whitespace(input.input)
    expect_read(input.input, '{')
    return nothing
end

function get_object_end(input::PullJson)
    munch_whitespace(input.input)
    expect_read(input.input, '}')
    return nothing
end

function get_comma(input::PullJson; whitespace=true)
    if whitespace
        munch_whitespace(input.input)
    end
    expect_read(input.input, ',')
    return nothing
end

function get_colon(input::PullJson)
    munch_whitespace(input.input)
    expect_read(input.input, ':')
    return nothing
end

# === expect ===

function expect_string(input::PullJson, expected::String)
    got = get_string(input)
    if got != expected
        error("expected $expected; got $got")
    end
end
