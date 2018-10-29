import Test
import Test: @test, @test_throws, @test_broken, @test_skip, @test_warn, @test_nowarn, @inferred


# Re-documenting the assertions from Test manually, because we need Documenter to pick them up.
# We could use their original docs instead of using links, but Documenter tries to
# run doctests on them, which fail.
# TODO: perhaps it is possible to create all these in a loop to avoid repetition.

@doc "See [`Test.@test`](https://docs.julialang.org/en/latest/stdlib/Test/#Test.@test)."
:(@test)

@doc "See [`Test.@test_throws`](https://docs.julialang.org/en/latest/stdlib/Test/#Test.@test_throws)."
:(@test_throws)

@doc "See [`Test.@test_broken`](https://docs.julialang.org/en/latest/stdlib/Test/#Test.@test_broken)."
:(@test_broken)

@doc "See [`Test.@test_skip`](https://docs.julialang.org/en/latest/stdlib/Test/#Test.@test_skip)."
:(@test_skip)

@doc "See [`Test.@test_warn`](https://docs.julialang.org/en/latest/stdlib/Test/#Test.@test_warn)."
:(@test_warn)

@doc "See [`Test.@test_nowarn`](https://docs.julialang.org/en/latest/stdlib/Test/#Test.@test_nowarn)."
:(@test_nowarn)

@doc "See [`Test.@inferred`](https://docs.julialang.org/en/latest/stdlib/Test/#Test.@inferred)."
:(@inferred)


struct ReturnValue{T} <: Test.Result
    value :: T
end


"""
    @test_result expr

Records a result from the test.
The result of `expr` will be displayed in the report by calling `string()` on it.
"""
macro test_result(expr)
    quote
        Test.record(Test.get_testset(), ReturnValue($(esc(expr))))
    end
end


struct FailExplanation <: Test.Result
    description :: String
end


"""
    @test_fail descr

Report a fail, providing an additional description (must be convertable to `String`).
The description will be displayed in the final report at the end of the test run.
"""
macro test_fail(descr)
    quote
        Test.record(Test.get_testset(), FailExplanation($(esc(descr))))
    end
end


struct CriticalFailException <: Exception
end


const _test_macro_symbols = Symbol.([
    "@test",
    "@test_fail",
    "@test_throws",
    "@test_broken",
    "@inferred",
    "@test_warn",
    "@test_nowarn",
    ])


"""
    @critical expr

Terminates the testcase on failure of an assertion `expr`.
`expr` must start from one of [`@test`](@ref), [`@test_fail`](@ref),
[`@test_throws`](@ref), [`@test_broken`](@ref), [`@inferred`](@ref),
[`@test_warn`](@ref), [`@test_nowarn`](@ref).
"""
macro critical(expr)
    if expr.head != :macrocall || !(expr.args[1] in _test_macro_symbols)
        error("@critical must precede an assertion macro that records a result")
    end

    quote
        $(esc(expr))
        if is_failed(Test.get_testset().results[end])
            throw(CriticalFailException())
        end
    end
end


struct TestcaseOutcome
    results :: Array{Test.Result, 1}
    elapsed_time :: Float64
    output :: String
end


is_failed(::Any) = false
is_failed(::Test.Fail) = true
is_failed(::Test.Error) = true
is_failed(::FailExplanation) = true
is_failed(outcome::TestcaseOutcome) = any(map(is_failed, outcome.results))


mutable struct JuteTestSet <: Test.AbstractTestSet
    results :: Array{Test.Result, 1}

    JuteTestSet(descr; results=[]) = new(results)
end


function Test.record(ts::JuteTestSet, res::Test.Result)
    push!(ts.results, res)
end


function Test.finish(ts::JuteTestSet) end


function run_testcase(tc::Testcase, args, capture_output::Bool=false)
    succeeded = true
    results = Test.Result[]

    elapsed_time, output = with_output_capture(!capture_output) do
        t = time_ns()
        Test.@testset JuteTestSet results=:($results) begin
            try
                Base.invokelatest(tc.func, args...)
            catch e
                if typeof(e) == CriticalFailException
                    # Used to terminate the testcase from inside of any number of nested calls
                else
                    rethrow(e)
                end
            end
        end
        (time_ns() - t) / 1e9
    end

    if length(results) == 0
        push!(results, Test.Pass(:test, nothing, nothing, nothing))
    end

    TestcaseOutcome(results, elapsed_time, output)
end
