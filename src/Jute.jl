__precompile__()

module Jute

include("utils.jl")

include("options.jl")

include("fixture_factory.jl")

include("fixtures.jl")
export fixture
export local_fixture

include("testcases.jl")
export @testcase
export @testgroup

include("inspect.jl")

include("run_testcase.jl")
export @test
export @test_throws
export @test_broken
export @test_skip
export @test_result
export @test_fail

include("reporting.jl")

include("runtests.jl")
export runtests

include("builtin_fixtures.jl")
export run_options
export temporary_dir

end
