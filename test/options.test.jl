module Options

using Jute


empty_options = testcase() do
    opts = build_run_options()

    # test some default option
    @test opts[:verbosity] == 1
end


command_line_options = testcase() do
    opts = build_run_options(; args=["--verbosity", "2"])

    # test some default option
    @test opts[:verbosity] == 2
end


userdict_options = testcase() do
    opts = build_run_options(; options=Dict(:verbosity => 2))

    # test some default option
    @test opts[:verbosity] == 2
end


userdict_unknown_option = testcase() do
    @test_throws ErrorException build_run_options(; options=Dict(:foobar => 0))
end


end
