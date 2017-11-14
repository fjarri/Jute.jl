using Compat
using Compat.Test: @test, @test_throws, @test_broken, @test_skip, @test_warn, @test_nowarn, @inferred
const BT = Compat.Test


struct ReturnValue{T} <: BT.Result
    value :: T
end


"""
    @test_result expr

Records a result from the test.
The result of `expr` will be displayed in the report by calling `string()` on it.
"""
macro test_result(expr)
    quote
        BT.record(BT.get_testset(), ReturnValue($(esc(expr))))
    end
end


struct FailExplanation <: BT.Result
    description :: String
end


"""
    @test_fail descr

Report a fail, providing an additional description (must be convertable to `String`).
The description will be displayed in the final report at the end of the test run.
"""
macro test_fail(descr)
    quote
        BT.record(BT.get_testset(), FailExplanation($(esc(descr))))
    end
end


struct TestcaseOutcome
    results :: Array{BT.Result, 1}
    elapsed_time :: Float64
    output :: String
end


is_failed(::Any) = false
is_failed(::BT.Fail) = true
is_failed(::BT.Error) = true
is_failed(::FailExplanation) = true
is_failed(outcome::TestcaseOutcome) = any(map(is_failed, outcome.results))


mutable struct JuteTestSet <: BT.AbstractTestSet
    results :: Array{BT.Result, 1}

    JuteTestSet(descr; results=[]) = new(results)
end


function BT.record(ts::JuteTestSet, res::BT.Result)
    push!(ts.results, res)
end


function BT.finish(ts::JuteTestSet) end


function run_testcase(tc::Testcase, args, capture_output::Bool=false)
    succeeded = true
    results = BT.Result[]

    elapsed_time, output = with_output_capture(!capture_output) do
        t = time_ns()
        BT.@testset JuteTestSet results=:($results) begin
            Base.invokelatest(tc.func, args...)
        end
        (time_ns() - t) / 1e9
    end

    if length(results) == 0
        push!(results, BT.Pass(:test, nothing, nothing, nothing))
    end

    TestcaseOutcome(results, elapsed_time, output)
end
