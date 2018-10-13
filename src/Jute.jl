__precompile__()

module Jute

using Pkg


include("utils.jl")

include("options.jl")

include("fixture_factory.jl")

include("fixtures.jl")

include("testcases.jl")

include("macros.jl")
export @testcase
export @testgroup
export @global_fixture
export @local_fixture
export @produce

include("inspect.jl")

include("run_testcase.jl")
export @test
export @test_throws
export @test_broken
export @test_skip
export @test_result
export @test_fail
export @inferred
export @test_warn
export @test_nowarn
export @critical

include("reporting.jl")

include("runtests.jl")
export runtests

include("builtin_fixtures.jl")
export run_options
export temporary_dir

end
