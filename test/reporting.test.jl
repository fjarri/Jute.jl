module Reporting

using Jute
using TestUtils


TESTCASES = Dict(
    :multiple_tests => testcase() do
        @test 1 == 1
        @test 2 == 2
        @test 3 == 3
    end,

    :returning_value => testcase() do
        @test 1 == 1
        @test_result 10
    end,

    :multiple_tests_and_one_failure => testcase() do
        @test 1 == 1
        @test 2 == 1
        @test 3 == 3
    end,

    :uncaught_exception => testcase() do
        @test 1 == 1
        error("Uncaught exception")
        @test 1 == 1
    end,

    :caught_exception => testcase() do
        @test 1 == 1
        @test_throws ErrorException error("Caught exception")
        @test 1 == 1
    end,

    :skip_test => testcase() do
        @test 1 == 1
        @test_skip 1 == 2
        @test 1 == 1
    end,

    :expected_failure => testcase() do
        @test 1 == 1
        @test_broken 1 == 2
        @test 1 == 1
    end,

    :unexpected_pass => testcase() do
        @test 1 == 1
        @test_broken 1 == 1
        @test 1 == 1
    end,

    :with_fixtures => testcase([1], [2]) do x, y
    end
    )

# Output redirection hangs on Windows and Julia 0.6, see Julia issue 23198
# Temporarily disabling these tests.
if !(Sys.is_windows() && VERSION == v"0.6.0")

verbosity0 = testcase() do
    exitcode, output = nested_run_with_output(TESTCASES, Dict(:verbosity => 0))
    @test exitcode == 1

    template = """
        ================================================================================
        multiple_tests_and_one_failure
        Test Failed
          Expression: 2 == 1
           Evaluated: 2 == 1
        ================================================================================
        uncaught_exception
        Error During Test
          Got an exception of type ErrorException outside of a @test
          Uncaught exception
          Stacktrace:
        <<<MULTILINE>>>
        ================================================================================
        unexpected_pass
        Error During Test
         Unexpected Pass
         Expression: 1 == 1
         Got correct result, please change to @test if no longer broken.
    """

    @test match_text(template, output)
end


verbosity1 = testcase() do
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
        multiple_tests_and_one_failure
        Test Failed
          Expression: 2 == 1
           Evaluated: 2 == 1
        ================================================================================
        uncaught_exception
        Error During Test
          Got an exception of type ErrorException outside of a @test
          Uncaught exception
          Stacktrace:
        <<<MULTILINE>>>
        ================================================================================
        unexpected_pass
        Error During Test
         Unexpected Pass
         Expression: 1 == 1
         Got correct result, please change to @test if no longer broken.
    """

    @test match_text(template, output)
end


verbosity2 = testcase() do
    exitcode, output = nested_run_with_output(TESTCASES, Dict(:verbosity => 2))
    @test exitcode == 1

    template = """
        Collecting testcases...
        Running 9 out of 9 testcases...
        ================================================================================
        Platform: Julia <<<julia_version>>>, Jute <<<jute_version>>>
        --------------------------------------------------------------------------------
        multiple_tests (<<<time>>>) [PASS] [PASS] [PASS]
        returning_value (<<<time>>>) [PASS] [10]
        multiple_tests_and_one_failure (<<<time>>>) [PASS] [FAIL] [PASS]
        uncaught_exception (<<<time>>>) [PASS] [ERROR]
        caught_exception (<<<time>>>) [PASS] [PASS] [PASS]
        skip_test (<<<time>>>) [PASS] [BROKEN] [PASS]
        expected_failure (<<<time>>>) [PASS] [BROKEN] [PASS]
        unexpected_pass (<<<time>>>) [PASS] [ERROR] [PASS]
        with_fixtures[1,2] (<<<time>>>) [PASS]
        --------------------------------------------------------------------------------
        18 tests passed, 1 failed, 2 errored in <<<full_time>>> (total test time <<<test_time>>>)
        ================================================================================
        multiple_tests_and_one_failure
        Test Failed
          Expression: 2 == 1
           Evaluated: 2 == 1
        ================================================================================
        uncaught_exception
        Error During Test
          Got an exception of type ErrorException outside of a @test
          Uncaught exception
          Stacktrace:
        <<<MULTILINE>>>
        ================================================================================
        unexpected_pass
        Error During Test
         Unexpected Pass
         Expression: 1 == 1
         Got correct result, please change to @test if no longer broken.
    """

    @test match_text(template, output)
end


captured_output = testcase() do
    testcases = Dict(
        :passing_tc => testcase() do
            println(STDOUT, "stdout from passing testcase")
            println(STDERR, "stderr from passing testcase")
        end,

        :failing_tc => testcase() do
            println(STDOUT, "stdout from failing testcase")
            @test 1 == 2
            println(STDERR, "stderr from failing testcase")
        end,
        )

    exitcode, output = nested_run_with_output(
        testcases, Dict(:verbosity => 0, :capture_output => true))

    template = """
        ================================================================================
        failing_tc
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

end
