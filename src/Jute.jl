__precompile__()

module Jute

include("rowmajor_product.jl")
export rowmajor_product

include("options.jl")
export RunOptions

include("fixture_factory.jl")

include("fixtures.jl")
export fixture, local_fixture

include("testcases.jl")
export testcase

include("inspect.jl")

include("reporting.jl")
export TestcaseReturn, @test_result

include("runtests.jl")
export @test, @test_throws, @test_broken, @test_skip
export runtests

include("builtin_fixtures.jl")
export run_options

end
