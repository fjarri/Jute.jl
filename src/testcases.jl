using DataStructures


"""
Testcase type.
"""
struct Testcase
    name :: String
    "Remembered creation order, used for test execution."
    func
    "Testcase parameters"
    parameters :: Array{Fixture, 1}
    """
    All leaf global dependencies of parameters
    (that is, the global fixtures in the dependency tree
    that are not parametrized themselves).
    """
    dependencies :: OrderedSet{AbstractGlobalFixture}
    "Testcase tags"
    tags :: Set{Symbol}
end


"""
    testcase(func, params...; tags=[])

Define a testcase.

`func` is a testcase function.
The number of function parameters must be equal to the number
of parametrizing fixtures given in `params`.
This function will be called with all combinations of values
of fixtures from `params`.

`params` are either fixtures, iterables or pairs of two iterables
used to parametrize the function.
In the latter case, the first iterable will be used to produce the values,
and the second one to produce the corresponding labels (for logging).

`tags` is an array of `Symbol`s.
Testcases can be filtered in or out by tags,
see [run options](@ref run_options_manual) for details.

Returns a [`Testcase`](@ref) object.
"""
function testcase(func, name::String, params...; tags::Array{Symbol, 1}=Symbol[])
    params = collect(map(normalize_fixture, params))
    deps = union(map(dependencies, params)..., global_fixtures(params))
    Testcase(name, func, params, deps, Set(tags))
end


parameters(tc::Testcase) = tc.parameters


dependencies(tc::Testcase) = tc.dependencies


tags(tc::Testcase) = tc.tags


struct TestGroup
    name :: String
    func
end


function testgroup(func, name)
    TestGroup(name, func)
end


register_testobj(obj) = push!(task_local_storage(TESTCASE_ACCUM_ID), obj)


function collect_testobjs(func)
    task_local_storage(TESTCASE_ACCUM_ID, Any[]) do
        func()
        task_local_storage(TESTCASE_ACCUM_ID)
    end
end


function get_testcases(group::TestGroup)
    collect_testobjs() do
        Base.invokelatest(group.func)
    end
end


"""
    @testcase [option=val ...] <name> begin ... end
    @testcase [option=val ...] <name> for x in fx1, y in fx2 ... end

Create a testcase object and add it to the current test group.

Available options:

`tags :: Array{Symbol, 1}`: a list of tags for the testcase.
"""
macro testcase(args...)

    options_expr = args[1:end-2]
    name = esc(args[end-1])
    vars, fixtures, body = parse_body(args[end])

    if length(options_expr) > 0
        options = parse_options(options_expr)
        tc_call = quote
            testcase($name, $(fixtures...); $options...) do $(vars...)
                $body
            end
        end
    else
        tc_call = quote
            testcase($name, $(fixtures...)) do $(vars...)
                $body
            end
        end
    end

    :( register_testobj($tc_call) )
end


function parse_body(body_expr)
    if body_expr.head == :for
        iterators = body_expr.args[1]
        body = body_expr.args[2]
        if iterators.head == :block
            fixtures = [assignment.args[2] for assignment in iterators.args]
            vars = [assignment.args[1] for assignment in iterators.args]
        else
            fixtures = [iterators.args[2]]
            vars = [iterators.args[1]]
        end
    else
        fixtures = []
        vars = []
        body = body_expr
    end

    body = esc(body)
    vars = map(esc, vars)
    fixtures = map(esc, fixtures)

    vars, fixtures, body
end


# Taken from Base.Test and simplified
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
    @testgroup <name> begin ... end

Create a test group.
The body can contain other [`@testgroup`](@ref) or [`@testcase`](@ref) declarations.
"""
macro testgroup(name, body)
    quote
        register_testobj(
            testgroup($(esc(name))) do
                $(esc(body))
            end)
    end
end
