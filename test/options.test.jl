@testgroup "options" begin


@testcase "empty options" begin
    opts = build_run_options()

    # test some default option
    @test opts[:verbosity] == 1
end


@testcase "commandline options" begin
    opts = build_run_options(; args=["--verbosity", "2"])

    # test some default option
    @test opts[:verbosity] == 2
end


@testcase "userdict options" begin
    opts = build_run_options(; options=Dict(:verbosity => 2))

    # test some default option
    @test opts[:verbosity] == 2
end


@testcase "unknown option in userdict" begin
    @test_throws ErrorException build_run_options(; options=Dict(:foobar => 0))
end


end
