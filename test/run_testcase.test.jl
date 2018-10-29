@testgroup "run_testcase" begin


function get_outcome(func)
    tcs = Jute.collect_testobjs() do
        @testcase "tc" begin
            func()
        end
    end
    tc = tcs[1]
    Jute.run_testcase(tc, [])
end


function get_results(func)
    return get_outcome(func).results
end


# Check that if a testcase calls no assertions, a single Pass gets added to the results.
@testcase "no assertions" begin
    results = get_results() do
    end
    @test length(results) == 1
    @test isa(results[1], Jute.Test.Pass)
end


@testcase "report value" begin
    results = get_results() do
        @test 1 == 1
        @test_result 1
        @test_result "a"
    end

    @test length(results) == 3
    @test isa(results[1], Jute.Test.Pass)
    @test isa(results[2], Jute.ReturnValue) && results[2].value == 1
    @test isa(results[3], Jute.ReturnValue) && results[3].value == "a"
end


@testcase "multiple fails" begin
    results = get_results() do
        @test 1 == 1
        @test 1 == 2 # first fail, execution should not stop

        # exception thrown, but since it happened inside an assertion,
        # execution should not stop
        @test error("caught")

        error("uncaught") # uncaught exception, execution should stop
        @test 1 == 1
    end

    @test length(results) == 4
    @test isa(results[1], Jute.Test.Pass)
    @test isa(results[2], Jute.Test.Fail)
    @test isa(results[3], Jute.Test.Error)
    @test isa(results[4], Jute.Test.Error)
end


@testcase "@test_throws" begin
    results = get_results() do
        @test 1 == 1
        @test_throws ErrorException error("Caught exception")
        @test 1 == 1
    end

    @test length(results) == 3
    @test isa(results[1], Jute.Test.Pass)
    @test isa(results[2], Jute.Test.Pass)
    @test isa(results[3], Jute.Test.Pass)
end


@testcase "@test_skip" begin
    results = get_results() do
        @test 1 == 1
        @test_skip 1 == 2
        @test 1 == 1
    end

    @test length(results) == 3
    @test isa(results[1], Jute.Test.Pass)
    @test isa(results[2], Jute.Test.Broken)
    @test isa(results[3], Jute.Test.Pass)
end


@testcase "@test_broken" begin
    results = get_results() do
        @test 1 == 1
        @test_broken 1 == 2
        @test 1 == 1
    end

    @test length(results) == 3
    @test isa(results[1], Jute.Test.Pass)
    @test isa(results[2], Jute.Test.Broken)
    @test isa(results[3], Jute.Test.Pass)
end


@testcase "unexpected pass" begin
    results = get_results() do
        @test 1 == 1
        @test_broken 1 == 1 # marked as broken, but succeeds
        @test 1 == 1
    end

    @test length(results) == 3
    @test isa(results[1], Jute.Test.Pass)
    @test isa(results[2], Jute.Test.Error)
    @test isa(results[3], Jute.Test.Pass)
end


@testcase "@inferred" begin

    f(a,b,c) = b > 1 ? 1 : 1.0

    results = get_results() do
        @inferred f(1,2,3)
    end

    @test length(results) == 1
    @test isa(results[1], Jute.Test.Error)

    results = get_results() do
        @inferred max(1, 2)
    end

    @test length(results) == 1
    @test isa(results[1], Jute.Test.Pass)
end


@testcase "@test_warn" begin
    results = get_results() do
        @test_warn "warn" println(stderr, "warn")
        @test_warn "warn" println(stderr, "foo")
    end

    @test length(results) == 2
    @test isa(results[1], Jute.Test.Pass)
    @test isa(results[2], Jute.Test.Fail)
end


@testcase "@test_nowarn" begin
    results = get_results() do
        @test_nowarn println(stderr, "warn")
        @test_nowarn sin(1.0)
    end

    @test length(results) == 2
    @test isa(results[1], Jute.Test.Fail)
    @test isa(results[2], Jute.Test.Pass)
end


function critical_fail()
    i = 1 # to check that an external variable can be used in the assertion
    @critical @test i == 2 # critical failure, execution should stop
end


@testcase "@critical" begin
    results = get_results() do
        @test 1 == 1
        critical_fail() # test that @critical works even inside a function
        @test 1 == 1
    end

    @test length(results) == 2
    @test isa(results[1], Jute.Test.Pass)
    @test isa(results[2], Jute.Test.Fail)
end


@testcase "@critical on an unsupported expression" begin
    @test_throws LoadError eval(:( @critical 1 == 1 ))
end


@testcase "is_failed()" begin
    outcome = get_outcome() do
        @test 1 == 1
        @test 2 == 2
    end
    @test !Jute.is_failed(outcome)

    outcome = get_outcome() do
        @test 1 == 1
        @test 1 == 2
    end
    @test Jute.is_failed(outcome)

    outcome = get_outcome() do
        @test 1 == 1
        error("uncaught")
    end
    @test Jute.is_failed(outcome)

    outcome = get_outcome() do
        @test 1 == 1
        @test_broken 1 == 2
    end
    @test !Jute.is_failed(outcome)

    outcome = get_outcome() do
        @test 1 == 1
        @test_broken 1 == 1
    end
    @test Jute.is_failed(outcome)

    outcome = get_outcome() do
        @test 1 == 1
        @test_result 1
    end
    @test !Jute.is_failed(outcome)
end


end
