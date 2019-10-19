@testgroup "options" begin


@testcase "empty options" begin
    opts = Jute.build_run_options()

    # test some default option
    @test opts[:verbosity] == 1
end


@testcase "commandline options" begin
    opts = Jute.build_run_options(; args=["--verbosity=2"])
    @test opts[:verbosity] == 2
end


@testcase "userdict options" begin
    opts = Jute.build_run_options(; options=Dict(:verbosity => 2))
    @test opts[:verbosity] == 2
end


@testcase "commandline overrides userdict options" begin
    opts = Jute.build_run_options(; options=Dict(:verbosity => 2), args=["--verbosity=0"])
    @test opts[:verbosity] == 0
end


@testcase "commandline option name change" begin

    # Confirm the default option
    opts = Jute.build_run_options()
    @test !opts[:dont_add_runtests_path]

    # When the default value of a flag is set to true by userdict,
    # the flag is replaced by its inverse in the possible commandline options,
    # so that it could be disabled via commandline
    opts = Jute.build_run_options(;
        options=Dict(:dont_add_runtests_path => true),
        args=["--add-runtests-path"])
    @test !opts[:dont_add_runtests_path]

    opts = Jute.build_run_options(;
        options=Dict(:dont_add_runtests_path => false),
        args=["--dont-add-runtests-path"])
    @test opts[:dont_add_runtests_path]

end


@testcase "unknown option in userdict" begin
    @test_throws ErrorException Jute.build_run_options(; options=Dict(:foobar => 0))
end


@testcase "tag options processing" begin
    opts = Jute.build_run_options(; options=Dict(:include_only_tags => [:tag1, :tag2]))
    @test opts[:include_only_tags] == [:tag1, :tag2]

    opts = Jute.build_run_options(; args=["-t", "tag1", "tag2"])
    @test opts[:include_only_tags] == [:tag1, :tag2]

    opts = Jute.build_run_options(; options=Dict(:exclude_tags => [:tag1, :tag2]))
    @test opts[:exclude_tags] == [:tag1, :tag2]

    opts = Jute.build_run_options(; args=["-n", "tag1", "tag2"])
    @test opts[:exclude_tags] == [:tag1, :tag2]
end


@testcase "color options processing" begin
    opts = Jute.build_run_options(; options=Dict(:color_pass => :blue))
    @test opts[:report_color_scheme].color_pass == :blue

    opts = Jute.build_run_options(; args=["--color-pass=blue"])
    @test opts[:report_color_scheme].color_pass == :blue
end


end
