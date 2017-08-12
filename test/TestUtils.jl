module TestUtils

using Jute

export run_testcases


strip_colors(s) = replace(s, r"\e\[\d+m", "")


function run_testcases(tcs, options=nothing)
    run_options = build_run_options(options=options)
    obj_dict = Dict(gensym("testcase") => tc for tc in tcs)
    exitcode, output = with_output_capture() do
        Jute.runtests_internal(run_options, obj_dict)
    end
    exitcode, strip_colors(output)
end

end
