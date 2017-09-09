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
    fx = Jute.constant_fixture(1)
    @test Jute.setup(fx) == [Jute.labeled_value(1)]

    fx = Jute.constant_fixture([1 2; 3 4])
    @test Jute.setup(fx) == map(Jute.labeled_value, [1, 3, 2, 4])

    fx = Jute.constant_fixture([1 2; 3 4], ["one" "two"; "three" "four"])
    @test Jute.setup(fx) == map(Jute.labeled_value, [1, 3, 2, 4], ["one", "three", "two", "four"])
end


@testcase "constant fixture with labels" begin
    fx = Jute.constant_fixture([1], ["one"])
    @test Jute.setup(fx) == [Jute.labeled_value(1, "one")]
end


@testcase "constant fixture checks for iterable" begin
    @test_throws ErrorException Jute.constant_fixture(:a)
    @test_throws ErrorException Jute.constant_fixture([1], :a)
end


@testcase "global fixture checks for callable" begin
    @test_throws ErrorException Jute.global_fixture(1)
end


@testcase "local fixture checks for callable" begin
    @test_throws ErrorException Jute.local_fixture(1)
end


@testcase "constant fixture from a pair" begin
    fx = @global_fixture for x in ([1, 2] => ["one", "two"])
        @produce x
    end
    constant_fx = Jute.parameters(fx)[1]
    @test Jute.setup(constant_fx) == map(Jute.labeled_value, [1, 2], ["one", "two"])
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
