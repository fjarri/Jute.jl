using Base.Test: @test, @test_throws, @test_broken, @test_skip
const BT = Base.Test


"Round a given number to a certain number of meaningful digits."
function round_to_meaningful(s::Float64, meaningful_digits)
    multiplier = 10.0^(meaningful_digits - 1 - convert(Integer, floor(log10(s))))
    round(s * multiplier) / multiplier
end


"""
Returns a string that represents a given time (in seconds)
as a value scaled to the appropriate unit (minutes, hours, milliseconds etc)
and rounded to a given number of meaningful digits.
If the latter is `0`, the result is rounded to an integer.
"""
function pprint_time(s::Float64; meaningful_digits::Int=0)
    limits = [
        (24 * 3600.0, "d"),
        (3600.0, "hr"),
        (60.0, "m"),
        (1.0, "s"),
        (1e-3, "ms"),
        (1e-6, "us"),
        (1e-9, "ns")
    ]

    function build_str(s, unit)
        if meaningful_digits == 0
            rounded_s = convert(Int, round(s))
        else
            rounded_s = round_to_meaningful(s, meaningful_digits)
        end
        string(rounded_s) * " " * unit
    end

    for (limit, unit) in limits[1:end-1]
        if s >= limit
            return build_str(s / limit, unit)
        end
    end

    limit, unit = limits[end]
    build_str(limit, unit)
end


struct TestcaseOutcome
    results :: Array{BT.Result, 1}
    elapsed_time :: Float64
end


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


function build_full_tag(tcpath::TestcasePath, labels)
    tc_name = string(tcpath)
    fixtures_tag = join(labels, ",")
    if length(labels) > 0
        tc_name * "[" * fixtures_tag * "]"
    else
        tc_name
    end
end


mutable struct ProgressReporter
    verbosity :: Int
    just_started :: Bool
    current_group :: GroupPath
end


function progress_reporter(tcpaths, verbosity)
    ProgressReporter(verbosity, true, GroupPath())
end


function progress_start_testcases!(progress::ProgressReporter, tcpath::TestcasePath, fixtures_num)
    if progress.verbosity == 1
        tc_group = group_path(tcpath)
        if tc_group != progress.current_group
            if !progress.just_started
                println()
            end
            if !isroot(tc_group)
                print(string(tc_group), ": ")
            end
            progress.current_group = tc_group
        end
        progress.just_started = false
    end
end


function progress_start_testcase!(progress::ProgressReporter, tcpath::TestcasePath, labels)
    if progress.verbosity >= 2
        full_tag = build_full_tag(tcpath, labels)
        print("$full_tag ")
    end
end


function progress_finish_testcase!(
        progress::ProgressReporter, tcpath::TestcasePath, labels, outcome)

    verbosity = progress.verbosity
    if verbosity == 1
        for result in outcome.results
            print_with_color(result_color(result, verbosity), result_show(result, verbosity))
        end
    elseif progress.verbosity >= 2
        elapsed_time = pprint_time(outcome.elapsed_time)

        print("($elapsed_time)")

        for result in outcome.results
            result_str = result_show(result, progress.verbosity)
            print_with_color(result_color(result, verbosity), " [$result_str]")
        end
        println()
    end
end


function progress_finish_testcases!(progress::ProgressReporter, tcpath::TestcasePath)

end



function progress_start!(progress::ProgressReporter)
    if progress.verbosity > 0
        println("Platform: Julia $VERSION, Jute $(Pkg.installed("Jute"))")
        println("-" ^ 80)
    end

    tic()
end


function progress_finish!(progress::ProgressReporter, outcomes)

    full_time = toq()

    outcome_objs = [outcome for (tcpath, labels, outcome) in outcomes]

    full_test_time = mapreduce(outcome -> outcome.elapsed_time, +, outcome_objs)

    all_results = mapreduce(outcome -> outcome.results, vcat, outcome_objs)
    num_results = Dict(
        key => length(filter(result -> isa(result, tp), all_results))
        for (key, tp) in [
            (:pass, Union{BT.Pass, ReturnValue}), (:fail, BT.Fail), (:error, BT.Error)])

    all_success = (num_results[:fail] + num_results[:error] == 0)

    if progress.verbosity == 0
        return all_success
    end

    if progress.verbosity == 1
        println()
    end

    full_time_str = pprint_time(full_time, meaningful_digits=3)
    full_test_time_str = pprint_time(full_test_time, meaningful_digits=3)

    println("-" ^ 80)
    println(
        "$(num_results[:pass]) tests passed, " *
        "$(num_results[:fail]) failed, " *
        "$(num_results[:error]) errored " *
        "in $full_time_str (total test time $full_test_time_str)")


    has_stacktrace(result) = typeof(result) == BT.Fail || typeof(result) == BT.Error

    for (tcpath, labels, outcome) in outcomes
        if any(map(has_stacktrace, outcome.results))
            println("=" ^ 80)
            println(build_full_tag(tcpath, labels))
            for result in outcome.results
                tp = typeof(result)
                if tp == BT.Fail || tp == BT.Error || tp == BT.Broken
                    println(result)
                end
            end
        end
    end

    all_success
end
