using Test


struct Verbosity{T}
end


result_color(::Any, ::Any) = :default
result_color(::Test.Pass, ::Verbosity{2}) = :green
result_color(::Test.Fail, ::Any) = :red
result_color(::Test.Error, ::Any) = :yellow
result_color(::Test.Broken, ::Verbosity{2}) = :green
result_color(::ReturnValue, ::Verbosity{2}) = :blue
result_color(::FailExplanation, ::Any) = :red


result_show(::Test.Pass, ::Verbosity{1}) = "."
result_show(::Test.Pass, ::Verbosity{2}) = "PASS"
result_show(::Test.Broken, ::Verbosity{1}) = "B"
result_show(::Test.Broken, ::Verbosity{2}) = "BROKEN"
result_show(::ReturnValue, ::Verbosity{1}) = "*"
# Since the `show` method for the result type will probably be defined in the test file,
# we need to use `invokelatest` here for it to be picked up.
result_show(result::ReturnValue, ::Verbosity{2}) = Base.invokelatest(string, result.value)
result_show(::Test.Fail, ::Verbosity{1}) = "F"
result_show(::Test.Fail, ::Verbosity{2}) = "FAIL"
result_show(::Test.Error, ::Verbosity{1}) = "E"
result_show(::Test.Error, ::Verbosity{2}) = "ERROR"
result_show(::FailExplanation, ::Verbosity{1}) = "F"
result_show(::FailExplanation, ::Verbosity{2}) = "FAIL"


function Base.show(io::IO, fe::FailExplanation)
    printstyled(io, "Test Failed\n"; color=:red, bold=true)
    descr = replace(fe.description, r"^"m => "  ")
    print(io, descr)
end


mutable struct ProgressReporter
    verbosity :: Int
    just_started :: Bool
    current_group :: Array{String, 1}
    doctest :: Bool
    start_time :: UInt64
end


function progress_reporter(tcinfos, verbosity, doctest)
    ProgressReporter(verbosity, true, String[], doctest, 0)
end


function common_elems_num(l1, l2)
    res = 0
    for i in 1:min(length(l1), length(l2))
        if l1[i] != l2[i]
            return res
        end
        res = i
    end
    return res
end


function progress_start_testcases!(progress::ProgressReporter, tcinfo::TestcaseInfo, fixtures_num)
    path, name = path_pair(tcinfo)
    verbosity = progress.verbosity

    if verbosity > 0 && path != progress.current_group

        if verbosity == 1 && !progress.just_started
            println()
        end

        if length(path) > 0
            cn = common_elems_num(progress.current_group, path)
            for i in cn+1:length(path)
                print("  " ^ (i - 1), path[i], verbosity == 1 ? ":" : "/")
                if verbosity == 1
                    if i != length(path)
                        print("\n")
                    else
                        print(" ")
                    end
                elseif verbosity == 2
                    print("\n")
                end
            end
        end

        progress.current_group = path
    end

    progress.just_started = false
end


function progress_start_testcase!(progress::ProgressReporter, tcinfo::TestcaseInfo, labels)
    if progress.verbosity >= 2
        tctag = tag_string(tcinfo, labels)
        path, name = path_pair(tcinfo)
        print("  " ^ length(path), tctag, " ")
    end
end


function progress_finish_testcase!(
        progress::ProgressReporter, tcinfo::TestcaseInfo, labels, outcome)

    verbosity = progress.verbosity
    if verbosity == 1
        for result in outcome.results
            printstyled(
                result_show(result, Verbosity{verbosity}()),
                color=result_color(result, Verbosity{verbosity}()))
        end
    elseif verbosity >= 2
        if progress.doctest
            elapsed_time = "[...] ms"
        else
            elapsed_time = pprint_time(outcome.elapsed_time)
        end

        print("($elapsed_time)")

        for result in outcome.results
            result_str = result_show(result, Verbosity{verbosity}())
            printstyled(
                " [$result_str]",
                color=result_color(result, Verbosity{verbosity}()))
        end
        println()
    end
end


function progress_finish_testcases!(progress::ProgressReporter, tcinfo::TestcaseInfo)

end


function progress_start!(progress::ProgressReporter)
    if progress.verbosity > 0

        if progress.doctest
            julia_version = "[...]"
            jute_version = "[...]"
        else
            julia_version = string(VERSION)
            # FIXME: at the moment Pkg3 does not allow us to get out own version
            jute_version = "<unknown>"
        end

        println("Platform: Julia $julia_version, Jute $jute_version")
        println("-" ^ 80)
    end

    progress.start_time = time_ns()
end


function progress_finish!(progress::ProgressReporter, outcomes)

    full_time = (time_ns() - progress.start_time) / 1e9

    outcome_objs = [outcome for (tcinfo, labels, outcome) in outcomes]

    all_results = mapreduce(outcome -> outcome.results, vcat, outcome_objs, init=[])
    num_results = Dict(
        key => length(filter(result -> isa(result, tp), all_results))
        for (key, tp) in [
            (:pass, Union{Test.Pass, ReturnValue, Test.Broken}),
            (:fail, Union{Test.Fail, FailExplanation}),
            (:error, Test.Error)])

    all_success = (num_results[:fail] + num_results[:error] == 0)

    if progress.verbosity == 1
        println()
    end

    if progress.verbosity >= 1
        if progress.doctest
            full_time_str = "[...] s"
            full_test_time_str = "[...] s"
        else
            full_test_time = mapreduce(outcome -> outcome.elapsed_time, +, outcome_objs)
            full_time_str = pprint_time(full_time, meaningful_digits=3)
            full_test_time_str = pprint_time(full_test_time, meaningful_digits=3)
        end

        println("-" ^ 80)
        println(
            "$(num_results[:pass]) tests passed, " *
            "$(num_results[:fail]) failed, " *
            "$(num_results[:error]) errored " *
            "in $full_time_str (total test time $full_test_time_str)")
    end

    for (tcinfo, labels, outcome) in outcomes
        if is_failed(outcome)
            println("=" ^ 80)
            println(tag_string(tcinfo, labels; full=true))

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
