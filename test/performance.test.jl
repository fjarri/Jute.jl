module Performance

using Jute


struct TimeReturn <: TestcaseReturn
    seconds
end


Base.show(io::IO, tr::TimeReturn) = print(io, pprint_time(tr.seconds, meaningful_digits=3))


# Usually when testing performance in Julia one makes some
# "warm-up" runs for the JIT to work.
# The thing is that we're only running runtests() once;
# we do not really care how long it takes the second time.
# Same goes for including the test files.
#
# So, to replicate a real test run, we are measuring the time in a newly created process,
# running a bunch of dummy testcases.
function time_test_run(test_include_only::Bool)
    runtests_dir = Jute.get_runtests_dir()
    julia = Base.julia_cmd()
    benchmark = joinpath(runtests_dir, "performance", "runtests_benchmark.jl")
    cmd = `$julia $benchmark $(test_include_only ? "test_include_only" : "")`
    parse(Float64, strip(readstring(cmd)))
end


full_run = testcase() do
    times = [time_test_run(false) for i in 1:5]
    @test_result TimeReturn(minimum(times))
end


# Only measure the time it takes to include the test files.
# TODO: in future we will collect the separate timings in a single run.
include_only = testcase() do
    times = [time_test_run(true) for i in 1:5]
    @test_result TimeReturn(minimum(times))
end


end
