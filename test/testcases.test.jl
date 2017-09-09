using DataStructures

@testgroup "testcases" begin


@testcase "testcase dependencies" begin

    fx1 = @global_fixture begin
        @produce 1
    end

    fx2 = @global_fixture for x in fx1
        @produce x
    end

    fx3 = @local_fixture for x in fx1
        @produce x
    end

    tcs = Jute.collect_testobjs() do
        @testcase "tc" for x in fx2, y in fx3
            @test 1 == 1
        end
    end
    tc = tcs[1]

    @test Jute.dependencies(tc) == OrderedSet([fx1, fx2])
    @test Jute.parameters(tc) == [fx2, fx3]
end


@testcase "tagging" begin
    tcs = Jute.collect_testobjs() do
        @testcase "no tags" begin
        end

        @testcase tags=[:tag1, :tag2] "some tags" begin
        end
    end

    @test Jute.tags(tcs[1]) == Set([])
    @test Jute.tags(tcs[2]) == Set([:tag1, :tag2])
end


end
