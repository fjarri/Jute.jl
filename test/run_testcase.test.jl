@testgroup "run_testcase" begin


function get_results(func)
    tc = testcase(func)
    outcome = Jute.run_testcase(tc, [])
    outcome.results
end


# Check that if a testcase calls no assertions, a single Pass gets added to the results.
no_assertions = testcase() do
    results = get_results() do
    end
    @test length(results) == 1
    @test isa(results[1], Jute.BT.Pass)
end


report_value = testcase() do
    results = get_results() do
        @test 1 == 1
        @test_result 1
        @test_result "a"
    end

    @test length(results) == 3
    @test isa(results[1], Jute.BT.Pass)
    @test isa(results[2], Jute.ReturnValue) && results[2].value == 1
    @test isa(results[3], Jute.ReturnValue) && results[3].value == "a"
end


multiple_fails = testcase() do
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
    @test isa(results[1], Jute.BT.Pass)
    @test isa(results[2], Jute.BT.Fail)
    @test isa(results[3], Jute.BT.Error)
    @test isa(results[4], Jute.BT.Error)
end


check_test_throws = testcase() do
    results = get_results() do
        @test 1 == 1
        @test_throws ErrorException error("Caught exception")
        @test 1 == 1
    end

    @test length(results) == 3
    @test isa(results[1], Jute.BT.Pass)
    @test isa(results[2], Jute.BT.Pass)
    @test isa(results[3], Jute.BT.Pass)
end


check_test_skip = testcase() do
    results = get_results() do
        @test 1 == 1
        @test_skip 1 == 2
        @test 1 == 1
    end

    @test length(results) == 3
    @test isa(results[1], Jute.BT.Pass)
    @test isa(results[2], Jute.BT.Broken)
    @test isa(results[3], Jute.BT.Pass)
end


check_test_broken = testcase() do
    results = get_results() do
        @test 1 == 1
        @test_broken 1 == 2
        @test 1 == 1
    end

    @test length(results) == 3
    @test isa(results[1], Jute.BT.Pass)
    @test isa(results[2], Jute.BT.Broken)
    @test isa(results[3], Jute.BT.Pass)
end


check_unexpected_pass = testcase() do
    results = get_results() do
        @test 1 == 1
        @test_broken 1 == 1 # marked as broken, but succeeds
        @test 1 == 1
    end

    @test length(results) == 3
    @test isa(results[1], Jute.BT.Pass)
    @test isa(results[2], Jute.BT.Error)
    @test isa(results[3], Jute.BT.Pass)
end


check_is_failed = testcase() do
    tc = testcase() do
        @test 1 == 1
        @test 2 == 2
    end
    outcome = Jute.run_testcase(tc, [])
    @test !Jute.is_failed(outcome)

    tc = testcase() do
        @test 1 == 1
        @test 1 == 2
    end
    outcome = Jute.run_testcase(tc, [])
    @test Jute.is_failed(outcome)

    tc = testcase() do
        @test 1 == 1
        error("uncaught")
    end
    outcome = Jute.run_testcase(tc, [])
    @test Jute.is_failed(outcome)

    tc = testcase() do
        @test 1 == 1
        @test_broken 1 == 2
    end
    outcome = Jute.run_testcase(tc, [])
    @test !Jute.is_failed(outcome)

    tc = testcase() do
        @test 1 == 1
        @test_broken 1 == 1
    end
    outcome = Jute.run_testcase(tc, [])
    @test Jute.is_failed(outcome)

    tc = testcase() do
        @test 1 == 1
        @test_result 1
    end
    outcome = Jute.run_testcase(tc, [])
    @test !Jute.is_failed(outcome)
end


end
