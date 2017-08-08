__precompile__()

module Jute

include("utils.jl")
export pprint_time

include("rowmajor_product.jl")
export rowmajor_product

include("options.jl")
export build_run_options

include("fixture_factory.jl")

include("fixtures.jl")
export fixture
export local_fixture

include("testcases.jl")
export testcase
export tag
export untag
export <|

include("inspect.jl")

include("reporting.jl")
export @test_result

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
