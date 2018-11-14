using DataStructures

@testgroup "fixtures" begin


@testcase "testcase with run_options" for ro in run_options
    @test haskey(ro, :verbosity)
end

fx_with_run_options = @global_fixture for ro in run_options
    @produce ro[:verbosity]
end

@testcase "testcase with a fixture with run_options" for v in fx_with_run_options
    @test isa(v, Int)
end


@testcase "constant fixture with non-1D iterable" begin
    fx = Jute.ConstantFixture(1)
    @test Jute.setup(fx) == [Jute.LabeledValue(1)]

    fx = Jute.ConstantFixture([1 2; 3 4])
    @test Jute.setup(fx) == map(Jute.LabeledValue, [1, 3, 2, 4])

    fx = Jute.ConstantFixture([1 2; 3 4], ["one" "two"; "three" "four"])
    @test Jute.setup(fx) == map(Jute.LabeledValue, [1, 3, 2, 4], ["one", "three", "two", "four"])
end


@testcase "constant fixture with labels" begin
    fx = Jute.ConstantFixture([1], ["one"])
    @test Jute.setup(fx) == [Jute.LabeledValue(1, "one")]
end


@testcase "constant fixture checks for iterable" begin
    @test_throws ErrorException Jute.ConstantFixture(:a)
    @test_throws ErrorException Jute.ConstantFixture([1], :a)
end


@testcase "global fixture checks for callable" begin
    @test_throws ErrorException Jute.GlobalFixture(1)
end


@testcase "local fixture checks for callable" begin
    @test_throws ErrorException Jute.LocalFixture(1)
end


@testcase "constant fixture from a pair" begin
    fx = @global_fixture for x in ([1, 2] => ["one", "two"])
        @produce x
    end
    constant_fx = Jute.parameters(fx)[1]
    @test Jute.setup(constant_fx) == map(Jute.LabeledValue, [1, 2], ["one", "two"])
end


testcases_for_custom_label_test = Jute.collect_testobjs() do
    fx_with_custom_label = @global_fixture for x in [1, 2]
        # Try a string and non-string label as a regression test
        # (@produce used to hang if passed a non-string label).
        label = x == 1 ? "one" : 2
        @produce x label
    end

    @testcase "custom label" for x in fx_with_custom_label
        @test 1 == 1
    end
end


@testcase "produce with a custom label" begin
    exitcode, output = nested_run_with_output(
        testcases_for_custom_label_test, Dict(:verbosity => 2))
    @test exitcode == 0

    template = """
        Collecting testcases...
        Using 1 out of 1 testcase definitions...
        ================================================================================
        Platform: <<<platform>>>, Julia <<<julia_version>>>, Jute <<<jute_version>>>
        --------------------------------------------------------------------------------
        custom label [one] (<<<time>>>) [PASS]
        custom label [2] (<<<time>>>) [PASS]
        --------------------------------------------------------------------------------
        2 tests passed, 0 failed, 0 errored in <<<full_time>>> (total test time <<<test_time>>>)
    """

    test_match_text(template, output)
end


@testcase "fixture dependencies" begin
    fx1 = @global_fixture begin
        @produce 1
    end

    fx2 = @global_fixture for x in fx1
        @produce x
    end

    fx3 = @global_fixture for x in fx1
        @produce x
    end

    fx4 = @local_fixture for x in fx3, y in fx2
        @produce x + y
    end

    fx5 = @global_fixture for x in fx3, y in fx2
        @produce x + y
    end

    @test Jute.dependencies(fx4) == OrderedSet([fx1, fx3, fx2])
    @test Jute.parameters(fx4) == [fx3, fx2]

    @test Jute.dependencies(fx5) == OrderedSet([fx1, fx3, fx2])
    @test Jute.parameters(fx5) == [fx3, fx2]
end


end
