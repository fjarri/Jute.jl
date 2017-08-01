using Jute

run_options = RunOptions(Dict(
    :dont_add_runtests_path => true,
    :test_module_prefix => "",
    :test_file_postfix => ".test.jl",
    :include_only => nothing,
    :exclude => nothing,
    :include_only_tags => [],
    :exclude_tags => [],
    :verbosity => 0))

runtests_dir = Jute.get_runtests_dir()
test_files = [joinpath(runtests_dir, "runtests_benchmark_testcases.jl")]

test_include_only = (ARGS[1] == "test_include_only")

tic()
obj_dict = Jute.include_test_files!(test_files)
if test_include_only
    exitcode = 0
else
    exitcode = Jute.runtests_internal(run_options, obj_dict)
end
println(toq())
exit(exitcode)

