struct PullJson
    input::IO
end

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

function get_int(input::PullJson)::Int
    munch_whitespace(input.input)
    return parse_int(input.input)
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

function get_comma(input::PullJson)
    munch_whitespace(input.input)
    expect_read(input.input, ',')
    return nothing
end

function get_colon(input::PullJson)
    munch_whitespace(input.input)
    expect_read(input.input, ':')
    return nothing
end
