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
    """
    If `true`, this testcase will be executed in the same process
    for all combinations of the fixture values.
    """
    single_process :: Bool

    """
        Testcase(func, params...; tags=[])

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
    function Testcase(
            func, name::String, params...;
            tags::Array{Symbol, 1}=Symbol[], single_process::Bool=false)

        params = collect(map(normalize_fixture, params))
        deps = union(map(dependencies, params)..., global_fixtures(params))
        new(name, func, params, deps, Set(tags), single_process)
    end
end


parameters(tc::Testcase) = tc.parameters


dependencies(tc::Testcase) = tc.dependencies


tags(tc::Testcase) = tc.tags


struct TestGroup
    name :: String
    func
    single_process :: Bool

    function TestGroup(func, name; single_process::Bool=false)
        new(name, func, single_process)
    end
end


function register_testobj(obj)
    if !haskey(task_local_storage(), TESTCASE_ACCUM_ID)
        task_local_storage(TESTCASE_ACCUM_ID, Any[])
    end
    push!(task_local_storage(TESTCASE_ACCUM_ID), obj)
end


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
