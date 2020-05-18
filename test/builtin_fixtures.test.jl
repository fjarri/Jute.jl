using .TestUtils

@testgroup "builtin_fixtures" begin

@testcase "run_options" begin
    tcs = Jute.collect_testobjs() do
        @testcase "tc" for opts in run_options
            @test opts[:test_file_postfix] == ".test2.jl"
        end
    end

    # FIXME: when custom options are available, we will need to use one of those instead.
    # Meanwhile, we will use an option that will not affect the nested test run.
    exitcode = nested_run(tcs, Dict(:test_file_postfix => ".test2.jl"))
    @test exitcode == 0
end


@testcase "temporary_dir" begin

    tcs = Jute.collect_testobjs() do
        tdir = "---"

        @testcase "tc1" for dir in temporary_dir
            @test isdir(dir)
            tdir = dir
            open(joinpath(dir, "testfile"), "w") do f
                write(f, "test")
            end
        end

        @testcase "tc2" begin
            @test tdir != "---"
            @test !isdir(tdir) # check that the directory was deleted
        end
    end

    exitcode = nested_run(tcs)
    @test exitcode == 0
end



@testcase "fixed_rng" begin

    rand_ints = [-1, -1, -1]

    tcs = Jute.collect_testobjs() do
        @testcase "tc1" for rng in fixed_rng("abc")
            rand_ints[1] = rand(rng, 1:1000000)
        end
        @testcase "tc2" for rng in fixed_rng("abc")
            rand_ints[2] = rand(rng, 1:1000000)
        end
        @testcase "tc3" for rng in fixed_rng("def")
            rand_ints[3] = rand(rng, 1:1000000)
        end
    end

    exitcode = nested_run(tcs)
    @test exitcode == 0

    @test rand_ints[1] == rand_ints[2]
    @test rand_ints[1] != rand_ints[3]
end


end
