__precompile__()

module Jute

include("rowmajor_product.jl")
export rowmajor_product

include("options.jl")
export RunOptions

include("fixture_factory.jl")

include("fixtures.jl")
export fixture
export local_fixture

include("testcases.jl")
export testcase

include("inspect.jl")

include("reporting.jl")
export TestcaseReturn
export @test_result
export pprint_time

include("runtests.jl")
export @test
export @test_throws
export @test_broken
export @test_skip
export runtests

include("builtin_fixtures.jl")
export run_options
export temporary_dir

end
