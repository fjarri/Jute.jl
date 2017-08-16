using DataStructures


"""
Testcase type.
"""
struct Testcase
    name :: String
    "Remembered creation order, used for test execution."
    order :: Int
    "Testcase function"
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
    testcase(func, params...)

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

Returns a [`Testcase`](@ref) object.
"""
function testcase(func, name::String, params...)
    # gensym() helps preserve the order of definition of testcases in a single file
    # A bit hacky, but we need an integer, since "9" > "10".
    order = parse(Int, string(gensym())[3:end])
    params = collect(map(normalize_fixture, params))
    deps = union(map(dependencies, params)..., global_fixtures(params))
    Testcase(name, order, func, params, deps, Set())
end

# Temporary stub for testing.
testcase(func, params...) = testcase(func, string(gensym("testcase")), params...)


parameters(tc::Testcase) = tc.parameters


dependencies(tc::Testcase) = tc.dependencies


tags(tc::Testcase) = tc.tags


struct Tagger
    tags :: Array{Pair{Symbol, Bool}, 1}
end


function (tagger::Tagger)(tc::Testcase)
    new_tags = copy(tc.tags)
    for (tag, add) in reverse(tagger.tags)
        if add
            push!(new_tags, tag)
        else
            delete!(new_tags, tag)
        end
    end
    Testcase(tc.name, tc.order, tc.func, parameters(tc), dependencies(tc), new_tags)
end

(tagger::Tagger)(other_tagger::Tagger) = Tagger(vcat(tagger.tags, other_tagger.tags))


"""
    tag(::Symbol)

Returns a function that tags a testcase with the given tag:

    tc = tag(:foo)(testcase() do
        ... something
    end)

Testcases can be filtered in/out using [run options](@ref run_options_manual).
It is convenient to use the [`<|`](@ref) operator:

    tc =
        tag(:foo) <|
        testcase() do
            ... something
        end

Note that [`tag`](@ref) and [`untag`](@ref) commands are applied from inner to outer.
"""
function tag(tag_name::Symbol)
    Tagger([tag_name => true])
end


"""
    untag(::Symbol)

Returns a function that untags a testcase with the given tag.
See [`tag`](@ref) for more details.
"""
function untag(tag_name::Symbol)
    Tagger([tag_name => false])
end


"""
    <|(f, x) === f(x)

A helper operator that makes applying testcase tags slightly more graceful.
See [`tag`](@ref) for an example.
"""
<|(f, x) = f(x)


macro testcase(name, expr)
    if expr.head == :for
        iterators = expr.args[1]
        body = expr.args[2]
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
        body = expr
    end

    vars = map(esc, vars)
    fixtures = map(esc, fixtures)

    res = quote
        push!(
            task_local_storage(:__JUTE_TESTCASES__),
            testcase($(esc(name)), $(fixtures...)) do $(vars...)
                $(esc(body))
            end)
    end

    res
end


struct TestGroup
    name :: String
    func
end


function testgroup(func, name)
    TestGroup(name, func)
end


function get_testcases(group::TestGroup)
    task_local_storage(TESTCASE_ACCUM_ID, Any[]) do
        Base.invokelatest(group.func)
        task_local_storage(TESTCASE_ACCUM_ID)
    end
end


macro testgroup(name, body)
    quote
        push!(
            task_local_storage(TESTCASE_ACCUM_ID),
            testgroup($(esc(name))) do
                $(esc(body))
            end)
    end
end
