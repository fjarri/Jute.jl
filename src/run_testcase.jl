using Test
using Test: @test, @test_throws, @test_broken, @test_skip, @test_warn, @test_nowarn, @inferred


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
            Base.invokelatest(tc.func, args...)
        end
        (time_ns() - t) / 1e9
    end

    if length(results) == 0
        push!(results, Test.Pass(:test, nothing, nothing, nothing))
    end

    TestcaseOutcome(results, elapsed_time, output)
end
