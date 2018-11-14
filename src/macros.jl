# Parse the iterator assignment expression from a for loop.
# It is assumed to either have the form "x = <expr>" or "(x, y, z) = <expr>"
# Returns the list of symbols from the left-hand-side and the expression from the right-hand side.
function parse_iterator(it_expr)
    @assert it_expr.head == :(=)
    v_expr = it_expr.args[1]
    fixture = it_expr.args[2]
    if isa(v_expr, Expr)
        @assert v_expr.head == :tuple
        v = v_expr.args
    else
        v = [v_expr]
    end
    v, fixture
end


function build_tuple_unpacks(var_lists)
    vars = []
    unpacks = []
    for var_list in var_lists
        if length(var_list) == 1
            push!(vars, var_list[1])
        else
            varname = gensym("tuple")
            push!(vars, varname)
            escaped_list = map(esc, var_list)
            push!(unpacks, :( ($(escaped_list...),) = $(esc(varname)) ))
        end
    end

    vars, unpacks
end


# Parse the body of a fixture or a testcase.
# This can be either a begin/end block, or a for loop
function parse_body(body_expr)
    if body_expr.head == :for
        iterators = body_expr.args[1]
        body = body_expr.args[2]
        if iterators.head == :block
            pairs = map(parse_iterator, iterators.args)
            var_lists, fixtures = zip(pairs...)
        else
            v, f = parse_iterator(iterators)
            fixtures = [f]
            var_lists = [v]
        end
    elseif body_expr.head == :block
        fixtures = []
        var_lists = []
        body = body_expr
    else
        error("Incorrect body expression of type $(body_expr.head)")
    end

    vars, unpacks = build_tuple_unpacks(var_lists)

    body = esc(body)
    fixtures = map(esc, fixtures)
    vars = map(esc, vars)

    vars, unpacks, fixtures, body
end


# Taken from Test and simplified
function parse_options(options_expr)
    options = :(Dict{Symbol, Any}())
    for arg in options_expr
        if isa(arg, Expr) && arg.head == :(=)
            # we're building up a Dict literal here
            key = Expr(:quote, arg.args[1])
            push!(options.args, Expr(:call, :(=>), key, esc(arg.args[2])))
        else
            error("Unexpected argument $arg to @testcase")
        end
    end
    options
end


"""
    @testcase [option=val ...] <name> begin ... end
    @testcase [option=val ...] <name> for x in fx1, (y, z) in fx2 ... end

Create a testcase object and add it to the current test group.

Available options:

`tags :: Array{Symbol, 1}`: a list of tags for the testcase.
"""
macro testcase(args...)

    options_expr = args[1:end-2]
    name = esc(args[end-1])
    vars, unpacks, fixtures, body = parse_body(args[end])

    if length(options_expr) > 0
        options = parse_options(options_expr)
        tc_call = quote
            Testcase($name, $(fixtures...); $options...) do $(vars...)
                $(unpacks...)
                $body
            end
        end
    else
        tc_call = quote
            Testcase($name, $(fixtures...)) do $(vars...)
                $(unpacks...)
                $body
            end
        end
    end

    :( register_testobj($tc_call) )
end



"""
    @testgroup <name> begin ... end

Create a test group.
The body can contain other [`@testgroup`](@ref) or [`@testcase`](@ref) declarations.
"""
macro testgroup(args...)

    options_expr = args[1:end-2]
    name = esc(args[end-1])
    body = esc(args[end])

    if length(options_expr) > 0
        options = parse_options(options_expr)
        tg_call = quote
            TestGroup($name; $options...) do
                $body
            end
        end
    else
        tg_call = quote
            TestGroup($name) do
                $body
            end
        end
    end

    :( register_testobj($tg_call) )
end


const PRODUCE_VAR = esc(gensym("produce"))


function _fixture(islocal, args...)
    options_expr = args[1:end-1]
    vars, unpacks, fixtures, body = parse_body(args[end])

    fxname = islocal ? :LocalFixture : :GlobalFixture

    if length(options_expr) > 0
        options = parse_options(options_expr)
        quote
            $fxname($(fixtures...); $options...) do $PRODUCE_VAR, $(vars...)
                $(unpacks...)
                $body
            end
        end
    else
        quote
            $fxname($(fixtures...)) do $PRODUCE_VAR, $(vars...)
                $(unpacks...)
                $body
            end
        end
    end
end


"""
    @global_fixture [option=val ...] <name> begin ... end
    @global_fixture [option=val ...] <name> for x in fx1, (y, z) in fx2 ... end

Create a global fixture (a fixture set up once before all
the testcases that use it and torn down after they finish).

The body must contain a single call to [`@produce`](@ref), producing a single value.

The iterables in the `for` loop are either fixtures (constant of global only),
iterable objects or pairs of two iterables used to parametrize the fixture.

Available options:

`instant_teardown :: Bool`: if `true`, the part of the fixture body after the [`@produce`](@ref)
will be executed immediately.

Returns a [`GlobalFixture`](@ref) object.
"""
macro global_fixture(args...)
    _fixture(false, args...)
end


"""
    @local_fixture <name> begin ... end
    @local_fixture <name> for x in fx1, (y, z) in fx2 ... end

Create a local fixture (a fixture set up before each testcase
that uses it and torn down afterwards).

The body must contain a single call to [`@produce`](@ref), producing a single value.

The iterables in the `for` loop are either fixtures (constant of global only),
iterable objects or pairs of two iterables used to parametrize the fixture.

Returns a [`LocalFixture`](@ref) object.
"""
macro local_fixture(args...)
    _fixture(true, args...)
end


"""
    @produce <val> [<label>]

Produce a fixture value (with an optional label).
Must only be called inside the bodies of [`@local_fixture`](@ref) and [`@global_fixture`](@ref).
"""
macro produce(args...)
    args = map(esc, args)
    :( $PRODUCE_VAR($(args...)) )
end
