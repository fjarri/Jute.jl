import Base.Test: @test, @test_throws, @test_broken, @test_skip
const BT = Base.Test


function round_to_meaningful(s::Float64, meaningful_digits)
    multiplier = 10.0^(meaningful_digits - 1 - convert(Integer, round(log10(s))))
    round(s * multiplier) / multiplier
end


function pprint_time(s::Float64)
    meaningful_digits = 3
    if s >= 1
        return "$(round_to_meaningful(s, meaningful_digits)) s"
    elseif s >= 1e-3
        return "$(round_to_meaningful(s * 1e3, meaningful_digits)) ms"
    elseif s >= 1e-6
        return "$(round_to_meaningful(s * 1e6, meaningful_digits)) us"
    end
end

abstract type TestcaseReturn end


struct TestcaseOutcome
    results :: Array{BT.Result, 1}
    elapsed_time :: Float64
end


struct ReturnValue <: BT.Result
    value :: TestcaseReturn
end


macro test_result(expr)
    quote
        BT.record(BT.get_testset(), ReturnValue($(esc(expr))))
    end
end


result_color(::BT.Pass, verbosity) = verbosity > 1 ? :green : :default
result_color(::BT.Fail, verbosity) = :red
result_color(::BT.Error, verbosity) = :yellow
result_color(::BT.Broken, verbosity) = verbosity > 1 ? :green : :default
result_color(::ReturnValue, verbosity) = verbosity > 1 ? :blue : :default


function result_show(::BT.Pass, verbosity)
    if verbosity == 0
        ""
    elseif verbosity == 1
        "."
    else
        "PASS"
    end
end


function result_show(::BT.Broken, verbosity)
    if verbosity == 0
        ""
    elseif verbosity == 1
        "B"
    else
        "BROKEN"
    end
end


function result_show(result::ReturnValue, verbosity)
    if verbosity == 0
        ""
    elseif verbosity == 1
        "*"
    else
        # Since the `show` method for the result type will probably be defined in the test file,
        # we need to use `invokelatest` here for it to be picked up.
        Base.invokelatest(string, result.value)
    end
end


function result_show(::BT.Fail, verbosity)
    if verbosity == 0
        ""
    elseif verbosity == 1
        "F"
    else
        "FAIL"
    end
end


function result_show(::BT.Error, verbosity)
    if verbosity == 0
        ""
    elseif verbosity == 1
        "E"
    else
        "ERROR"
    end
end


function build_full_tag(name_tuple, ids)
    tc_name = join(name_tuple, "/")
    fixtures_tag = join(ids, ",")
    if length(ids) > 0
        tc_name * "[" * fixtures_tag * "]"
    else
        tc_name
    end
end


mutable struct ProgressReporter
    verbosity
    current_group
end


function progress_reporter(name_tuples, verbosity)
    ProgressReporter(verbosity, nothing)
end


function progress_start_testcases!(progress::ProgressReporter, name_tuple, fixtures_num)
    if progress.verbosity == 1
        tc_group = name_tuple[1:end-1]
        if tc_group != progress.current_group
            if !(progress.current_group === nothing)
                println()
            end
            if length(tc_group) > 0
                print(build_full_tag(tc_group, []), ": ")
            end
            progress.current_group = tc_group
        end
    end
end


function progress_finish_testcase!(progress::ProgressReporter, name_tuple, ids, outcome)
    verbosity = progress.verbosity
    if verbosity == 1
        for result in outcome.results
            print_with_color(result_color(result, verbosity), result_show(result, verbosity))
        end
    elseif progress.verbosity >= 2
        full_tag = build_full_tag(name_tuple, ids)
        elapsed_time = pprint_time(outcome.elapsed_time)

        print("$full_tag ($elapsed_time)")

        for result in outcome.results
            result_str = result_show(result, progress.verbosity)
            print_with_color(result_color(result, verbosity), " [$result_str]")
        end
        println()
    end
end


function progress_finish_testcases!(progress::ProgressReporter, name_tuple)

end



function progress_start!(progress::ProgressReporter)
    tic()
end


function progress_finish!(progress::ProgressReporter, outcomes)

    full_time = toq()

    if progress.verbosity == 1
        println()
    end

    println("-" ^ 80)
    outcome_objs = [outcome for (name_tuple, ids, outcome) in outcomes]

    full_test_time = mapreduce(outcome -> outcome.elapsed_time, +, outcome_objs)

    all_results = mapreduce(outcome -> outcome.results, vcat, outcome_objs)
    num_results = Dict(
        key => length(filter(result -> isa(result, tp), all_results))
        for (key, tp) in [
            (:pass, Union{BT.Pass, ReturnValue}), (:fail, BT.Fail), (:error, BT.Error)])

    println(
        "$(num_results[:pass]) tests passed, " *
        "$(num_results[:fail]) failed, " *
        "$(num_results[:error]) errored " *
        "in $(pprint_time(full_time)) (total test time $(pprint_time(full_test_time)))")


    has_stacktrace(result) = typeof(result) == BT.Fail || typeof(result) == BT.Error

    for (name_tuple, ids, outcome) in outcomes
        if any(map(has_stacktrace, outcome.results))
            println("=" ^ 80)
            println(build_full_tag(name_tuple, ids))
            for result in outcome.results
                tp = typeof(result)
                if tp == BT.Fail || tp == BT.Error || tp == BT.Broken
                    println(result)
                end
            end
        end
    end

    num_results[:fail] + num_results[:error] == 0
end
