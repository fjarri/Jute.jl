using Jute

runtests_dir = Jute.get_runtests_dir()
test_files = [joinpath(runtests_dir, "runtests_benchmark_testcases.jl")]

test_include_only = (ARGS[1] == "test_include_only")

run_options = Jute.build_run_options(options=Dict(:verbosity => 0))

tic()
obj_dict = Jute.include_test_files!(test_files)
if test_include_only
    exitcode = 0
else
    exitcode = Jute.runtests_internal(run_options, obj_dict)
end
println(toq())
exit(exitcode)

