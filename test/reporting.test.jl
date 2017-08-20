using TestUtils


@testgroup "reporting" begin


TESTCASES = Jute.collect_testobjs() do
    @testcase "multiple tests" begin
        @test 1 == 1
        @test 2 == 2
        @test 3 == 3
    end

    @testcase "returning value" begin
        @test 1 == 1
        @test_result 10
    end

    @testcase "multiple tests and one failure" begin
        @test 1 == 1
        @test 2 == 1
        @test 3 == 3
    end

    @testcase "uncaught exception" begin
        @test 1 == 1
        error("Uncaught exception")
        @test 1 == 1
    end

    @testcase "caught exception" begin
        @test 1 == 1
        @test_throws ErrorException error("Caught exception")
        @test 1 == 1
    end

    @testcase "skip test" begin
        @test 1 == 1
        @test_skip 1 == 2
        @test 1 == 1
    end

    @testcase "expected failure" begin
        @test 1 == 1
        @test_broken 1 == 2
        @test 1 == 1
    end

    @testcase "unexpected pass" begin
        @test 1 == 1
        @test_broken 1 == 1
        @test 1 == 1
    end

    @testcase "with fixtures" for x in [1], y in [2]
    end
end


@testcase "verbosity0" begin
    exitcode, output = nested_run_with_output(TESTCASES, Dict(:verbosity => 0))
    @test exitcode == 1

    template = """
        ================================================================================
        multiple tests and one failure
        Test Failed
          Expression: 2 == 1
           Evaluated: 2 == 1
        ================================================================================
        uncaught exception
        Error During Test
          Got an exception of type ErrorException outside of a @test
          Uncaught exception
          Stacktrace:
        <<<MULTILINE>>>
        ================================================================================
        unexpected pass
        Error During Test
         Unexpected Pass
         Expression: 1 == 1
         Got correct result, please change to @test if no longer broken.
    """

    @test match_text(template, output)
end


@testcase "verbosity1" begin
    exitcode, output = nested_run_with_output(TESTCASES, Dict(:verbosity => 1))
    @test exitcode == 1

    template = """
        Collecting testcases...
        Running 9 out of 9 testcases...
        ================================================================================
        Platform: Julia <<<julia_version>>>, Jute <<<jute_version>>>
        --------------------------------------------------------------------------------
        ....*.F..E....B..B..E..
        --------------------------------------------------------------------------------
        18 tests passed, 1 failed, 2 errored in <<<full_time>>> (total test time <<<test_time>>>)
        ================================================================================
        multiple tests and one failure
        Test Failed
          Expression: 2 == 1
           Evaluated: 2 == 1
        ================================================================================
        uncaught exception
        Error During Test
          Got an exception of type ErrorException outside of a @test
          Uncaught exception
          Stacktrace:
        <<<MULTILINE>>>
        ================================================================================
        unexpected pass
        Error During Test
         Unexpected Pass
         Expression: 1 == 1
         Got correct result, please change to @test if no longer broken.
    """

    @test match_text(template, output)
end


@testcase "verbosity2" begin
    exitcode, output = nested_run_with_output(TESTCASES, Dict(:verbosity => 2))
    @test exitcode == 1

    template = """
        Collecting testcases...
        Running 9 out of 9 testcases...
        ================================================================================
        Platform: Julia <<<julia_version>>>, Jute <<<jute_version>>>
        --------------------------------------------------------------------------------
        multiple tests (<<<time>>>) [PASS] [PASS] [PASS]
        returning value (<<<time>>>) [PASS] [10]
        multiple tests and one failure (<<<time>>>) [PASS] [FAIL] [PASS]
        uncaught exception (<<<time>>>) [PASS] [ERROR]
        caught exception (<<<time>>>) [PASS] [PASS] [PASS]
        skip test (<<<time>>>) [PASS] [BROKEN] [PASS]
        expected failure (<<<time>>>) [PASS] [BROKEN] [PASS]
        unexpected pass (<<<time>>>) [PASS] [ERROR] [PASS]
        with fixtures[1,2] (<<<time>>>) [PASS]
        --------------------------------------------------------------------------------
        18 tests passed, 1 failed, 2 errored in <<<full_time>>> (total test time <<<test_time>>>)
        ================================================================================
        multiple tests and one failure
        Test Failed
          Expression: 2 == 1
           Evaluated: 2 == 1
        ================================================================================
        uncaught exception
        Error During Test
          Got an exception of type ErrorException outside of a @test
          Uncaught exception
          Stacktrace:
        <<<MULTILINE>>>
        ================================================================================
        unexpected pass
        Error During Test
         Unexpected Pass
         Expression: 1 == 1
         Got correct result, please change to @test if no longer broken.
    """

    @test match_text(template, output)
end


@testcase "captured_output" begin
    testcases = Jute.collect_testobjs() do
        @testcase "passing testcase" begin
            println(STDOUT, "stdout from passing testcase")
            println(STDERR, "stderr from passing testcase")
        end

        @testcase "failing testcase" begin
            println(STDOUT, "stdout from failing testcase")
            @test 1 == 2
            println(STDERR, "stderr from failing testcase")
        end
    end

    exitcode, output = nested_run_with_output(
        testcases, Dict(:verbosity => 0, :capture_output => true))

    template = """
        ================================================================================
        failing testcase
        Captured output:
        stdout from failing testcase
        stderr from failing testcase

        Test Failed
          Expression: 1 == 2
           Evaluated: 1 == 2
    """

    @test match_text(template, output)
end


end
