struct Verbosity{T}
end


result_color(cs::ReportColorScheme, ::Any, ::Any) = :default
result_color(cs::ReportColorScheme, ::Test.Pass, ::Verbosity{2}) = cs.color_pass
result_color(cs::ReportColorScheme, ::Test.Fail, ::Any) = cs.color_fail
result_color(cs::ReportColorScheme, ::Test.Error, ::Any) = cs.color_error
result_color(cs::ReportColorScheme, ::Test.Broken, ::Verbosity{2}) = cs.color_broken
result_color(cs::ReportColorScheme, ::ReturnValue, ::Verbosity{2}) = cs.color_return
result_color(cs::ReportColorScheme, ::FailExplanation, ::Any) = cs.color_fail


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


struct ExecutedTestcase
    tcinfo :: TestcaseInfo
    labels :: Array{String, 1}
    outcome :: TestcaseOutcome
end


mutable struct ProgressReporter
    verbosity :: Int
    just_started :: Bool
    current_group :: Array{String, 1}
    doctest :: Bool
    start_time :: UInt64
    visited_groups :: Set{Array{String, 1}}
    testcases :: Array{ExecutedTestcase, 1}

    function ProgressReporter(verbosity, doctest)
        new(verbosity, true, String[], doctest, 0, Set{Array{String, 1}}(), ExecutedTestcase[])
    end
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


function _progress_start_testgroup!(progress::ProgressReporter, tcinfo::TestcaseInfo)

    verbosity = progress.verbosity
    path = tcinfo.path

    if verbosity == 1 && !progress.just_started
        println()
    end

    if length(path) > 0
        path_repeated = path in progress.visited_groups

        if path_repeated && verbosity == 1
            cn = 0
        else
            cn = common_elems_num(progress.current_group, path)
        end

        for i in cn+1:length(path)
            postfix = verbosity == 1 ? (path_repeated ? " (cont.):" : ":") : "/"
            print("  " ^ (i - 1), path[i], postfix)
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

end


function progress_start_testcase!(progress::ProgressReporter, tcinfo::TestcaseInfo, labels)

    progress.just_started = false

    path, name = path_pair(tcinfo)
    verbosity = progress.verbosity

    if verbosity > 0 && path != progress.current_group
        _progress_start_testgroup!(progress, tcinfo)
        progress.current_group = path
        push!(progress.visited_groups, path)
    end

    if progress.verbosity >= 2
        tctag = tag_string(tcinfo, labels)
        path, name = path_pair(tcinfo)
        print("  " ^ length(path), tctag, " ")
    end
end


function progress_finish_testcase!(
        progress::ProgressReporter, tcinfo::TestcaseInfo, labels,
        outcome::TestcaseOutcome, color_scheme::ReportColorScheme)

    push!(progress.testcases, ExecutedTestcase(tcinfo, labels, outcome))

    verbosity = progress.verbosity
    if verbosity == 1
        for result in outcome.results
            printstyled(
                result_show(result, Verbosity{verbosity}()),
                color=result_color(color_scheme, result, Verbosity{verbosity}()))
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
                color=result_color(color_scheme, result, Verbosity{verbosity}()))
        end
        println()
    end
end


function progress_start!(progress::ProgressReporter)
    if progress.verbosity > 0

        if progress.doctest
            platform = "[...], Julia [...]"
            jute_version = "[...]"
        else
            kernel = Sys.iswindows() ? "Windows" : Sys.isapple() ? "macOS" : Sys.KERNEL
            platform = "$kernel ($(Sys.MACHINE)), Julia $(string(VERSION))"
            # TODO: when https://github.com/JuliaLang/Pkg.jl/issues/385 is resolved,
            # the correct way of getting the version may change.
            # Currently, `Pkg.installed()` sometimes works, so we try it.
            jute_version = get(Pkg.installed(), "Jute", "<unknown>")
        end

        println("Platform: $platform, Jute $jute_version")
        println("-" ^ 80)
    end

    progress.start_time = time_ns()
end


function _custom_results_present(progress::ProgressReporter)
    for etc in progress.testcases
        if any(isa(result, ReturnValue) for result in etc.outcome.results)
            return true
        end
    end
    false
end


function _print_custom_results(progress::ProgressReporter, color_scheme::ReportColorScheme)
    println("-" ^ 80)
    pr2 = ProgressReporter(2, false)
    for etc in progress.testcases
        return_values = [result for result in etc.outcome.results if isa(result, ReturnValue)]
        if !isempty(return_values)
            filtered_outcome = TestcaseOutcome(
                return_values, etc.outcome.elapsed_time, etc.outcome.output)
            progress_start_testcase!(pr2, etc.tcinfo, etc.labels)
            progress_finish_testcase!(pr2, etc.tcinfo, etc.labels, filtered_outcome, color_scheme)
        end
    end
end


function _print_statistics(progress::ProgressReporter, full_time)

    all_results = mapreduce(etc -> etc.outcome.results, vcat, progress.testcases, init=[])
    stats = Dict(
        key => length(filter(result -> isa(result, tp), all_results))
        for (key, tp) in [
            (:pass, Union{Test.Pass, ReturnValue, Test.Broken}),
            (:fail, Union{Test.Fail, FailExplanation}),
            (:error, Test.Error)])

    if progress.doctest
        full_time_str = "[...] s"
        full_test_time_str = "[...] s"
    else
        full_test_time = mapreduce(etc -> etc.outcome.elapsed_time, +, progress.testcases)
        full_time_str = pprint_time(full_time, meaningful_digits=3)
        full_test_time_str = pprint_time(full_test_time, meaningful_digits=3)
    end

    println("-" ^ 80)
    println(
        "$(stats[:pass]) tests passed, " *
        "$(stats[:fail]) failed, " *
        "$(stats[:error]) errored " *
        "in $full_time_str (total test time $full_test_time_str)")
end


function _print_failures(progress::ProgressReporter)
    for etc in progress.testcases
        if is_failed(etc.outcome)
            println("=" ^ 80)
            println(tag_string(etc.tcinfo, etc.labels; full=true))

            if length(etc.outcome.output) > 0
                println("Captured output:")
                println(etc.outcome.output)
            end

            for result in etc.outcome.results
                if is_failed(result)
                    println(result)
                end
            end
        end
    end
end


function progress_finish!(progress::ProgressReporter, color_scheme::ReportColorScheme)

    full_time = (time_ns() - progress.start_time) / 1e9

    if progress.verbosity == 1
        # Results are displayed with `print()`, so a line break in the end is needed.
        println()
    end

    if progress.verbosity == 1 && _custom_results_present(progress)
        _print_custom_results(progress, color_scheme)
    end

    if progress.verbosity >= 1
        _print_statistics(progress, full_time)
    end

    _print_failures(progress)
end
