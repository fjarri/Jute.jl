using TestUtils

@testgroup "builtin_fixtures" begin

@testcase "run_options" begin
    tc = testcase(run_options) do opts
        @test opts[:test_file_postfix] == ".test2.jl"
    end

    # FIXME: when custom options are available, we will need to use one of those instead.
    # Meanwhile, we will use an option that will not affect the nested test run.
    exitcode = nested_run([tc], Dict(:test_file_postfix => ".test2.jl"))
    @test exitcode == 0
end


@testcase "temporary_dir" begin

    tdir = ""

    tc1 = testcase(temporary_dir) do dir
        @test isdir(dir)
        tdir = dir
        open(joinpath(dir, "testfile"), "w") do f
            write(f, "test")
        end
    end

    tc2 = testcase() do
        @test !isdir(tdir) # check that the directory was deleted
    end

    exitcode = nested_run([tc1, tc2])
    @test exitcode == 0
end

end
