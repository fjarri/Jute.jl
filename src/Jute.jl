__precompile__()

module Jute

include("utils.jl")
export pprint_time
export rowmajor_product
export with_output_capture

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
export @testcase
export @testgroup

include("inspect.jl")

include("run_testcase.jl")
export @test
export @test_throws
export @test_broken
export @test_skip
export @test_result

include("reporting.jl")

include("runtests.jl")
export runtests

include("builtin_fixtures.jl")
export run_options
export temporary_dir

end
