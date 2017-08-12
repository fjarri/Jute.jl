module TestUtils

using Jute

export nested_run


strip_colors(s) = replace(s, r"\e\[\d+m", "")


function _nested_run(tcs, options, output_pass_through)
    run_options = build_run_options(options=options)
    obj_dict = Dict(gensym("testcase") => tc for tc in tcs)
    exitcode, output = with_output_capture(output_pass_through) do
        Jute.runtests_internal(run_options, obj_dict)
    end
    exitcode, strip_colors(output)
end


function nested_run(tcs, options=nothing)
    if options === nothing
        options = Dict{Symbol, Any}()
    else
        options = Dict{Symbol, Any}(options)
    end
    options[:verbosity] = 0
    exitcode, output = _nested_run(tcs, options, true)
    exitcode
end


function nested_run_with_output(tcs, options=nothing)
    _nested_run(tcs, options, false)
end


end
