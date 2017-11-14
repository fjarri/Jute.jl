using Jute

runtests_dir = Jute.get_runtests_dir()
test_files = [joinpath(runtests_dir, "runtests_benchmark_testcases.jl")]

test_include_only = (ARGS[1] == "test_include_only")

run_options = Jute.build_run_options(options=Dict(:verbosity => 0))

t = time_ns()
Jute.include_test_files!(test_files)
tcs = task_local_storage(Jute.TESTCASE_ACCUM_ID)
if test_include_only
    exitcode = 0
else
    exitcode = Jute.runtests_internal(run_options, tcs)
end
println((time_ns() - t) / 1e9)
exit(exitcode)

