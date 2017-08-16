using DataStructures

@testgroup "testcases" begin


@testcase "testcase dependencies" begin
    fx1 = fixture() do produce
        produce([1])
    end

    fx2 = fixture(fx1) do produce, x
        produce([x])
    end

    fx3 = local_fixture(fx1) do produce, x
        produce(x)
    end

    tc = testcase(fx2, fx3) do
        @test 1 == 1
    end

    @test Jute.dependencies(tc) == OrderedSet([fx1, fx2])
    @test Jute.parameters(tc) == [fx2, fx3]
end


@testcase "simple tagging" begin
    tc = testcase() do
    end

    @test Jute.tags(tc) == Set([])

    tc =
        tag(:tag1) <|
        tag(:tag2) <|
        tag(:tag1) <|
        tc
    @test Jute.tags(tc) == Set([:tag1, :tag2])

    tc =
        untag(:tag1) <|
        tc
    @test Jute.tags(tc) == Set([:tag2])
end


@testcase "tag-untag mixture" begin
    tc = testcase() do
    end

    # tagging commands are applied from inner to outer
    tc =
        tag(:tag1) <|
        untag(:tag2) <|
        untag(:tag1) <|
        tag(:tag2) <|
        tc

    @test Jute.tags(tc) == Set([:tag1])
end


end
