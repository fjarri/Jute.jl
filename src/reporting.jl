const BT = Base.Test


struct Verbosity{T}
end


result_color(::Any, ::Any) = :default
result_color(::BT.Pass, ::Verbosity{2}) = :green
result_color(::BT.Fail, ::Any) = :red
result_color(::BT.Error, ::Any) = :yellow
result_color(::BT.Broken, ::Verbosity{2}) = :green
result_color(::ReturnValue, ::Verbosity{2}) = :blue


result_show(::BT.Pass, ::Verbosity{1}) = "."
result_show(::BT.Pass, ::Verbosity{2}) = "PASS"
result_show(::BT.Broken, ::Verbosity{1}) = "B"
result_show(::BT.Broken, ::Verbosity{2}) = "BROKEN"
result_show(::ReturnValue, ::Verbosity{1}) = "*"
# Since the `show` method for the result type will probably be defined in the test file,
# we need to use `invokelatest` here for it to be picked up.
result_show(result::ReturnValue, ::Verbosity{2}) = Base.invokelatest(string, result.value)
result_show(::BT.Fail, ::Verbosity{1}) = "F"
result_show(::BT.Fail, ::Verbosity{2}) = "FAIL"
result_show(::BT.Error, ::Verbosity{1}) = "E"
result_show(::BT.Error, ::Verbosity{2}) = "ERROR"


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
            print_with_color(
                result_color(result, Verbosity{verbosity}()),
                result_show(result, Verbosity{verbosity}()))
        end
    elseif verbosity >= 2
        elapsed_time = pprint_time(outcome.elapsed_time)

        print("($elapsed_time)")

        for result in outcome.results
            result_str = result_show(result, Verbosity{verbosity}())
            print_with_color(
                result_color(result, Verbosity{verbosity}()),
                " [$result_str]")
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

    all_results = mapreduce(outcome -> outcome.results, vcat, [], outcome_objs)
    num_results = Dict(
        key => length(filter(result -> isa(result, tp), all_results))
        for (key, tp) in [
            (:pass, Union{BT.Pass, ReturnValue}), (:fail, BT.Fail), (:error, BT.Error)])

    all_success = (num_results[:fail] + num_results[:error] == 0)

    if progress.verbosity == 1
        println()
    end

    if progress.verbosity >= 1
        full_test_time = mapreduce(outcome -> outcome.elapsed_time, +, outcome_objs)
        full_time_str = pprint_time(full_time, meaningful_digits=3)
        full_test_time_str = pprint_time(full_test_time, meaningful_digits=3)

        println("-" ^ 80)
        println(
            "$(num_results[:pass]) tests passed, " *
            "$(num_results[:fail]) failed, " *
            "$(num_results[:error]) errored " *
            "in $full_time_str (total test time $full_test_time_str)")
    end

    for (tcpath, labels, outcome) in outcomes
        if is_failed(outcome)
            println("=" ^ 80)
            println(build_full_tag(tcpath, labels))

            if length(outcome.output) > 0
                println("Captured output:")
                println(outcome.output)
            end

            for result in outcome.results
                if is_failed(result)
                    println(result)
                end
            end
        end
    end

    all_success
end
