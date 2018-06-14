using Jute

include("TestUtils.jl")

include("builtin_fixtures.test.jl")
include("fixture_factory.test.jl")
include("fixtures.test.jl")
include("options.test.jl")
include("performance.test.jl")
include("reporting.test.jl")
include("run_testcase.test.jl")
include("runtests.test.jl")
include("testcases.test.jl")
include("utils.test.jl")

exit(runtests())
