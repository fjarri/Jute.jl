var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Jute,-a-Py.Test-inspired-testing-framework-1",
    "page": "Home",
    "title": "Jute, a Py.Test-inspired testing framework",
    "category": "section",
    "text": "The main principles of the library:The test runner include()s all the files named in a certain way (ending in .test.jl by default). Alternatively, the files containing testcase definitions can be included manually;\nTestcases are defined using the @testcase macro and grouped using the @testgroup macro;\nTestcases can be parametrized by fixtures, which can be simple iterables, or include a setup/teardown stage right before and after each test, or once before and after all the tests that use it.\nFixtures can be parametrized by other fixtures."
},

{
    "location": "index.html#A-quick-example-1",
    "page": "Home",
    "title": "A quick example",
    "category": "section",
    "text": "DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nendusing Jute\n\n# constant fixture - any iterable\nfx1 = 1:3\n\n# global fixture - the setup/teardown function is run once\n# for every produced value\nfx2 = @global_fixture for x in fx1\n    # the optional second argument defines a custom label for the value\n    @produce x \"value $x\"\nend\n\n# local fixture - the setup/teardown function is run for each testcase\n# and each value produced by `fx2`\nfx3 = @local_fixture for x in fx2\n    @produce (x + 1)\nend\n\n# testcase - will be picked up automatically\n# and run for all the combinations of fixture values\n@testcase \"tc\" for x in fx1, y in fx2, z in fx3\n    @test x + y == y + x\n    @test x + y + z == z + y + x\nend\n\nruntests()\n\n# output\n\nCollecting testcases...\nUsing 1 out of 1 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\n......................................................\n--------------------------------------------------------------------------------\n54 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)"
},

{
    "location": "manual.html#",
    "page": "Manual",
    "title": "Manual",
    "category": "page",
    "text": ""
},

{
    "location": "manual.html#Manual-1",
    "page": "Manual",
    "title": "Manual",
    "category": "section",
    "text": ""
},

{
    "location": "manual.html#Defining-tests-1",
    "page": "Manual",
    "title": "Defining tests",
    "category": "section",
    "text": "The entry-point file (commonly called runtests.jl) is:using Jute\n\n# Testcase definitions\n\nexit(runtests())If there were no @testcase and @testgroup calls before the call to runtests(), the test runner picks up any file with the name ending in .test.jl (by default; can be changed with the command-line option --test-file-postfix) in the directory where the entry-point file is located, or in any subdirectories. All those files are included at the same level (with using Jute at the start), and all the @testcase and @testgroup definitions are picked up.If some testcase definitions were present before the call to runtests(), they will be used and consumed, so the following calls to runtests() will follow the first scenario (loading testcases from files).The @testgroup definitions can contain other @testgroup definitions and @testcase definitions.The exit() call is required to signal about any test failures to the processes that initiate the execution of the test suite, for instance CI tools. runtests() returns 1 if there were failed tests, 0 otherwise.note: Note\nIn all the following examples the exit() call will be missing because of the limitations of the Documenter\'s doctest runner. Also, using Jute will be implied."
},

{
    "location": "manual.html#Basic-testcases-and-groups-1",
    "page": "Manual",
    "title": "Basic testcases and groups",
    "category": "section",
    "text": "In the simple case of a non-parametrized test, the @testcase macro takes the testcase name and body. Testcases can be grouped using @testgroup definitions. For example:DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nend@testcase \"tc1\" begin\nend\n\n@testgroup \"group\" begin\n    @testcase \"tc2\" begin\n    end\nend\n\n@testgroup \"group2\" begin\n    @testgroup \"subgroup\" begin\n        @testcase \"tc3\" begin\n        end\n    end\nend\n\nruntests(; options=Dict(:verbosity => 2))\n\n# output\n\nCollecting testcases...\nUsing 3 out of 3 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\ntc1 ([...] ms) [PASS]\ngroup/\n  tc2 ([...] ms) [PASS]\ngroup2/\n  subgroup/\n    tc3 ([...] ms) [PASS]\n--------------------------------------------------------------------------------\n3 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)The order of testcase definition is preserved. In other words, the testcases will be executed in the same order in which they were defined."
},

{
    "location": "manual.html#Assertions-1",
    "page": "Manual",
    "title": "Assertions",
    "category": "section",
    "text": "Jute relies on the assertions from Test; @test, @test_throws, @test_skip, @test_broken, @inferred, @test_warn and @test_nowarn can be used. In addition, Jute has a @test_result macro allowing one to return a custom result (e.g. the value of a benchmark from a testcase), and a @test_fail macro for providing custom information with a fail. There can be several assertions per testcase; their results will be reported separately. If the testcase does not call any assertions and does not throw any exceptions, it is considered to be passed."
},

{
    "location": "manual.html#Parametrizing-testcases-1",
    "page": "Manual",
    "title": "Parametrizing testcases",
    "category": "section",
    "text": ""
},

{
    "location": "manual.html#Constant-fixtures-1",
    "page": "Manual",
    "title": "Constant fixtures",
    "category": "section",
    "text": "The simplest method to parametrize a test is to supply it with an iterable:DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nend@testcase \"parametrized testcase\" for x in [1, 2, 3]\n    @test x == x\nend\n\nruntests(; options=Dict(:verbosity => 2))\n\n# output\n\nCollecting testcases...\nUsing 1 out of 1 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\nparametrized testcase [1] ([...] ms) [PASS]\nparametrized testcase [2] ([...] ms) [PASS]\nparametrized testcase [3] ([...] ms) [PASS]\n--------------------------------------------------------------------------------\n3 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)By default, Jute uses string() to convert a fixture value to a string for reporting purposes. One can assign custom labels to fixtures by passing a Pair of iterables instead:DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nend@testcase \"parametrized testcase\" for x in ([1, 2, 3] => [\"one\", \"two\", \"three\"])\n    @test x == x\nend\n\nruntests(; options=Dict(:verbosity => 2))\n\n# output\n\nCollecting testcases...\nUsing 1 out of 1 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\nparametrized testcase [one] ([...] ms) [PASS]\nparametrized testcase [two] ([...] ms) [PASS]\nparametrized testcase [three] ([...] ms) [PASS]\n--------------------------------------------------------------------------------\n3 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)A testcase can use several fixtures, in which case Jute will run the testcase function with all possible combinations of them:DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nend@testcase \"parametrized testcase\" for x in [1, 2], y in [3, 4]\n    @test x + y == y + x\nend\n\nruntests(; options=Dict(:verbosity => 2))\n\n# output\n\nCollecting testcases...\nUsing 1 out of 1 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\nparametrized testcase [1,3] ([...] ms) [PASS]\nparametrized testcase [1,4] ([...] ms) [PASS]\nparametrized testcase [2,3] ([...] ms) [PASS]\nparametrized testcase [2,4] ([...] ms) [PASS]\n--------------------------------------------------------------------------------\n4 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)Iterable unpacking is also supported:DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nend@testcase \"parametrized testcase\" for (x, y) in [(1, 2), (3, 4)]\n    @test x + y == y + x\nend\n\nruntests(; options=Dict(:verbosity => 2))\n\n# output\n\nCollecting testcases...\nUsing 1 out of 1 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\nparametrized testcase [(1, 2)] ([...] ms) [PASS]\nparametrized testcase [(3, 4)] ([...] ms) [PASS]\n--------------------------------------------------------------------------------\n2 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)Note that the label still refers to the full element of the iterable.note: Note\nIf the iterable expression evaluates to anything other than a fixture object, it will be treated as a constant fixture. In other words, if an expression like for (x, y) in [fixture1, fixture2, fixture3] is used to parametrize a testcase or a fixture, the nested fixtures will not be processed and added to the dependencies."
},

{
    "location": "manual.html#Global-fixtures-1",
    "page": "Manual",
    "title": "Global fixtures",
    "category": "section",
    "text": "A global fixture is a more sophisticated variant of a constant fixture that has a setup and a teardown stage. For each value produced by the global fixture, the setup is called before the first testcase that uses it. As for the teardown, it is either called right away (if the option instant_teardown is true), or after the last testcase that uses it (if instant_teardown is false, which is the default). If no testcases use it (for example, they were filtered out), neither setup nor teardown will be called.The setup and the teardown are defined by use of a single coroutine that produces the fixture value. The coroutine\'s first argument is a function that is used to return the value. If instant_teardown is false, the call blocks until it is time to execute the teardown:db_connection = @global_fixture begin\n    c = db_connect()\n\n    # this call blocks until all the testcases\n    # that use this value are executed\n    @produce c\n\n    close(c)\nendSimilarly to the constant fixture case, one can provide a custom identifier for the fixture via the optional second argument of @produce:db_connection = @global_fixture begin\n    c = db_connect()\n\n    @produce c \"db_connection\"\n\n    close(c)\nendGlobal fixtures can be parametrized by other constant or global fixtures. Similarly to the test parametrization, all possible combinations of parameters will be used to produce values:DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nendfx1 = @global_fixture for x in 3:4\n    @produce x\nend\n\nfx2 = @global_fixture for x in 1:2, y in fx1\n    @produce (x, y)\nend\n\n@testcase \"tc\" for x in fx2\n    @test length(x) == 2\nend\n\nruntests(; options=Dict(:verbosity => 2))\n\n# output\n\nCollecting testcases...\nUsing 1 out of 1 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\ntc [(1, 3)] ([...] ms) [PASS]\ntc [(1, 4)] ([...] ms) [PASS]\ntc [(2, 3)] ([...] ms) [PASS]\ntc [(2, 4)] ([...] ms) [PASS]\n--------------------------------------------------------------------------------\n4 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)"
},

{
    "location": "manual.html#Local-fixtures-1",
    "page": "Manual",
    "title": "Local fixtures",
    "category": "section",
    "text": "A local fixture is a fixture whose value is created right before each call to the testcase function and destroyed afterwards. A simple example is a fixture that provides a temporary directory:DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nendtemporary_dir = @local_fixture begin\n    dir = mktempdir()\n    @produce dir \"tempdir\" # this call will block while the testcase is being executed\n    rm(dir, recursive=true)\nend\n\n@testcase \"tempdir test\" for dir in temporary_dir\n    @test isdir(dir)\nend\n\nruntests(; options=Dict(:verbosity => 2))\n\n# output\n\nCollecting testcases...\nUsing 1 out of 1 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\ntempdir test [tempdir] ([...] ms) [PASS]\n--------------------------------------------------------------------------------\n1 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)Local fixtures can be parametrized by any other type of fixture, including other local fixtures."
},

{
    "location": "manual.html#Testcase-tags-1",
    "page": "Manual",
    "title": "Testcase tags",
    "category": "section",
    "text": "Testcases can be assigned tags of the type Symbol. This can be used to establish a secondary grouping, independent of the primary grouping provided by modules. For example, one can tag performance tests, tests that run for a long time, unit/integration tests, tests that require a specific resource and so on. Testcases can be filtered by tags they have or don\'t have using command-line arguments.The tagging is performed by the optional paramter tag to the macro @testcase that takes a list of Symbols:DocTestSetup = quote\n    using Jute\n    Jute.jute_doctest()\nend@testcase tags=[:foo] \"foo\" begin\nend\n\n@testcase tags=[:bar, :baz] \"bar and baz\" begin\nend\n\nruntests(; options=Dict(:verbosity => 2, :include_only_tags => [:baz]))\n\n# output\n\nCollecting testcases...\nUsing 1 out of 2 testcase definitions...\n================================================================================\nPlatform: [...], Julia [...], Jute [...]\n--------------------------------------------------------------------------------\nbar and baz ([...] ms) [PASS]\n--------------------------------------------------------------------------------\n1 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)"
},

{
    "location": "manual.html#Jute.build_parser",
    "page": "Manual",
    "title": "Jute.build_parser",
    "category": "function",
    "text": "For every option, the corresponding command-line argument names are given in parentheses. If supplied via the options keyword argument of runtests(), their type must be as given or convert()-able to it.\n\n:include_only:: Union{Nothing, Regex} (--include-only, -i): takes a regular expression; tests with full names that do not match it will not be executed.\n\n:exclude:: Union{Nothing, Regex} (--exclude, -e): takes a regular expression; tests with full names that match it will not be executed.\n\nnote: Note\nThe full name refers to the name of the testcase and all its parent groups, separated by slashes (/). For example, the full name of the testcase \"foo\" in the group \"bar\", which, in turn, is defined in the group \"baz\", will be \"baz/bar/foo\".\n\n:verbosity:: Int (--verbosity, -v): 0, 1 or 2, defines the amount of output that will be shown. 1 is the default.\n\n:include_only_tags:: Array{Symbol, 1} (--include-only-tags, -t): include only tests with any of the specified tags. You can pass several tags to this option, separated by spaces.\n\n:exclude_tags:: Array{Symbol, 1} (--exclude-tags, -n): exclude tests with any of the specified tags. You can pass several tags to this option, separated by spaces.\n\n:max_fails:: Int (--max-fails): stop after the given amount of failed testcases (a testcase is considered failed, if at least one test in it failed, or an unhandeld exception was thrown).\n\n:test_file_postifx:: String (--test-file-postfix): postfix of the files which will be picked up by the automatic testcase discovery.\n\nThe flag arguments are processed in a special way if a non-default value is passed via the options keyword argument of runtests(). In this case, the command-line option is replaced by its inverse (given second in the parentheses), with the corresponding change in the default.\n\n:capture_output:: Bool (--capture-output/--dont-capture-output): capture all the output from testcases and only show the output of the failed ones in the end of the test run.\n\n:dont_add_runtests_path::: Bool (--dont-add-runtests-path/--add-runtests-path): do not push the test root path into LOAD_PATH before including test files\n\n\n\n\n\n"
},

{
    "location": "manual.html#run_options_manual-1",
    "page": "Manual",
    "title": "Run options",
    "category": "section",
    "text": "Jute\'s runtest() picks up the options from the command line by default. Alternatively, they can be set with the options keyword argument of runtests(). Note that command-line arguments override the ones passed via options.Jute.build_parserRun options can be accessed from a testcase or a fixture via the built-in fixture run_options."
},

{
    "location": "public.html#",
    "page": "Public API",
    "title": "Public API",
    "category": "page",
    "text": ""
},

{
    "location": "public.html#Public-API-1",
    "page": "Public API",
    "title": "Public API",
    "category": "section",
    "text": ""
},

{
    "location": "public.html#Jute.runtests",
    "page": "Public API",
    "title": "Jute.runtests",
    "category": "function",
    "text": "runtests(; options=nothing, ignore_commandline=false)\n\nRun the test suite.\n\nThis function has several side effects:\n\nit parses the command-line arguments, using them to build the dictionary of run options (see Run options in the manual for the list);\nit picks up and includes the test files, selected according to the options.\n\noptions must be a dictionary with the keys corresponding to some of the options from the above list. If options is given, command-line arguments are not parsed.\n\nIf ignore_commandline is true, command-line arguments passed to the program will not be used. This option can be helpful if one wants to be sure that the run options used are exactly the ones specified in the call.\n\nReturns 0 if there are no failed tests, 1 otherwise.\n\n\n\n\n\n"
},

{
    "location": "public.html#Entry-point-1",
    "page": "Public API",
    "title": "Entry point",
    "category": "section",
    "text": "runtests"
},

{
    "location": "public.html#Jute.@testcase",
    "page": "Public API",
    "title": "Jute.@testcase",
    "category": "macro",
    "text": "@testcase [option=val ...] <name> begin ... end\n@testcase [option=val ...] <name> for x in fx1, (y, z) in fx2 ... end\n\nCreate a testcase object and add it to the current test group.\n\nAvailable options:\n\ntags :: Array{Symbol, 1}: a list of tags for the testcase.\n\n\n\n\n\n"
},

{
    "location": "public.html#Jute.@testgroup",
    "page": "Public API",
    "title": "Jute.@testgroup",
    "category": "macro",
    "text": "@testgroup <name> begin ... end\n\nCreate a test group. The body can contain other @testgroup or @testcase declarations.\n\n\n\n\n\n"
},

{
    "location": "public.html#Jute.@global_fixture",
    "page": "Public API",
    "title": "Jute.@global_fixture",
    "category": "macro",
    "text": "@global_fixture [option=val ...] <name> begin ... end\n@global_fixture [option=val ...] <name> for x in fx1, (y, z) in fx2 ... end\n\nCreate a global fixture (a fixture set up once before all the testcases that use it and torn down after they finish).\n\nThe body must contain a single call to @produce, producing a single value.\n\nThe iterables in the for loop are either fixtures (constant of global only), iterable objects or pairs of two iterables used to parametrize the fixture.\n\nAvailable options:\n\ninstant_teardown :: Bool: if true, the part of the fixture body after the @produce will be executed immediately.\n\nReturns a GlobalFixture object.\n\n\n\n\n\n"
},

{
    "location": "public.html#Jute.@local_fixture",
    "page": "Public API",
    "title": "Jute.@local_fixture",
    "category": "macro",
    "text": "@local_fixture <name> begin ... end\n@local_fixture <name> for x in fx1, (y, z) in fx2 ... end\n\nCreate a local fixture (a fixture set up before each testcase that uses it and torn down afterwards).\n\nThe body must contain a single call to @produce, producing a single value.\n\nThe iterables in the for loop are either fixtures (constant of global only), iterable objects or pairs of two iterables used to parametrize the fixture.\n\nReturns a LocalFixture object.\n\n\n\n\n\n"
},

{
    "location": "public.html#Jute.@produce",
    "page": "Public API",
    "title": "Jute.@produce",
    "category": "macro",
    "text": "@produce <val> [<label>]\n\nProduce a fixture value (with an optional label). Must only be called inside the bodies of @local_fixture and @global_fixture.\n\n\n\n\n\n"
},

{
    "location": "public.html#Testcases-and-fixtures-1",
    "page": "Public API",
    "title": "Testcases and fixtures",
    "category": "section",
    "text": "@testcase\n@testgroup\n@global_fixture\n@local_fixture\n@produce"
},

{
    "location": "public.html#Test.@test",
    "page": "Public API",
    "title": "Test.@test",
    "category": "macro",
    "text": "See Test.@test.\n\n\n\n\n\n"
},

{
    "location": "public.html#Test.@test_throws",
    "page": "Public API",
    "title": "Test.@test_throws",
    "category": "macro",
    "text": "See Test.@test_throws.\n\n\n\n\n\n"
},

{
    "location": "public.html#Test.@test_broken",
    "page": "Public API",
    "title": "Test.@test_broken",
    "category": "macro",
    "text": "See Test.@test_broken.\n\n\n\n\n\n"
},

{
    "location": "public.html#Test.@test_skip",
    "page": "Public API",
    "title": "Test.@test_skip",
    "category": "macro",
    "text": "See Test.@test_skip.\n\n\n\n\n\n"
},

{
    "location": "public.html#Test.@inferred",
    "page": "Public API",
    "title": "Test.@inferred",
    "category": "macro",
    "text": "See Test.@inferred.\n\n\n\n\n\n"
},

{
    "location": "public.html#Test.@test_warn",
    "page": "Public API",
    "title": "Test.@test_warn",
    "category": "macro",
    "text": "See Test.@test_warn.\n\n\n\n\n\n"
},

{
    "location": "public.html#Test.@test_nowarn",
    "page": "Public API",
    "title": "Test.@test_nowarn",
    "category": "macro",
    "text": "See Test.@test_nowarn.\n\n\n\n\n\n"
},

{
    "location": "public.html#Jute.@test_result",
    "page": "Public API",
    "title": "Jute.@test_result",
    "category": "macro",
    "text": "@test_result expr\n\nRecords a result from the test. The result of expr will be displayed in the report by calling string() on it.\n\n\n\n\n\n"
},

{
    "location": "public.html#Jute.@test_fail",
    "page": "Public API",
    "title": "Jute.@test_fail",
    "category": "macro",
    "text": "@test_fail descr\n\nReport a fail, providing an additional description (must be convertable to String). The description will be displayed in the final report at the end of the test run.\n\n\n\n\n\n"
},

{
    "location": "public.html#Jute.@critical",
    "page": "Public API",
    "title": "Jute.@critical",
    "category": "macro",
    "text": "@critical expr\n\nTerminates the testcase on failure of an assertion expr. expr must start from one of @test, @test_fail, @test_throws, @test_broken, @inferred, @test_warn, @test_nowarn.\n\n\n\n\n\n"
},

{
    "location": "public.html#Assertions-1",
    "page": "Public API",
    "title": "Assertions",
    "category": "section",
    "text": "The following assertions are re-exported from Test and can be used inside Jute testcases.@test\n@test_throws\n@test_broken\n@test_skip\n@inferred\n@test_warn\n@test_nowarnJute adds several assertions of its own.@test_result\n@test_failAssertions can be made to terminate the testcase on failure.@critical"
},

{
    "location": "public.html#Jute.temporary_dir",
    "page": "Public API",
    "title": "Jute.temporary_dir",
    "category": "constant",
    "text": "A local fixture that creates a temporary directory and returns its name; the directory and all its contents is removed during the teardown.\n\n\n\n\n\n"
},

{
    "location": "public.html#Jute.run_options",
    "page": "Public API",
    "title": "Jute.run_options",
    "category": "constant",
    "text": "A global fixture that returns the dictionary with the current run options (see Run options in the manual for the full list.\n\n\n\n\n\n"
},

{
    "location": "public.html#Built-in-fixtures-1",
    "page": "Public API",
    "title": "Built-in fixtures",
    "category": "section",
    "text": "temporary_dir\nrun_options"
},

{
    "location": "internals.html#",
    "page": "Internals",
    "title": "Internals",
    "category": "page",
    "text": ""
},

{
    "location": "internals.html#Jute.Testcase",
    "page": "Internals",
    "title": "Jute.Testcase",
    "category": "type",
    "text": "Testcase type.\n\n\n\n\n\n"
},

{
    "location": "internals.html#Jute.GlobalFixture",
    "page": "Internals",
    "title": "Jute.GlobalFixture",
    "category": "type",
    "text": "Global fixture type\n\n\n\n\n\n"
},

{
    "location": "internals.html#Jute.LocalFixture",
    "page": "Internals",
    "title": "Jute.LocalFixture",
    "category": "type",
    "text": "Local fixture type\n\n\n\n\n\n"
},

{
    "location": "internals.html#Internals-1",
    "page": "Internals",
    "title": "Internals",
    "category": "section",
    "text": "Some non-exported entities.Jute.Testcase\nJute.GlobalFixture\nJute.LocalFixture"
},

{
    "location": "history.html#",
    "page": "Version history",
    "title": "Version history",
    "category": "page",
    "text": ""
},

{
    "location": "history.html#Version-history-1",
    "page": "Version history",
    "title": "Version history",
    "category": "section",
    "text": ""
},

{
    "location": "history.html#v0.2.1-(2-Nov-2018)-1",
    "page": "Version history",
    "title": "v0.2.1 (2 Nov 2018)",
    "category": "section",
    "text": "ADDED: @critical macro to make test assertions terminate the testcase on failure.\nADDED: for verbosity=1, display the results returned by @test_result separately.\nADDED: printing the OS and the kernel info in the report header.\nFIXED: @produce hanging when passed a non-string label.\nFIXED: incorrect indentation with verbosity=1 when a group has some testcases after nested groups."
},

{
    "location": "history.html#v0.2.0-(16-Sep-2018)-1",
    "page": "Version history",
    "title": "v0.2.0 (16 Sep 2018)",
    "category": "section",
    "text": "CHANGED: support for Julia v0.6 dropped, support for v1.0 added.\nADDED: command-line arguments (if used) now override the options passed to runtests() during the call.\nFIXED: an incorrect description for the --dont-add-runtests-path option.\nFIXED: include/exclude filtering for testcases is now correctly performed based on full testcase paths."
},

{
    "location": "history.html#v0.1.0-(1-Oct-2017)-1",
    "page": "Version history",
    "title": "v0.1.0 (1 Oct 2017)",
    "category": "section",
    "text": "CHANGED: testcase groups are no longer defined by modules; @testgroup should be used instead. Consequently, the option :test_module_prefix was removed.\nCHANGED: testcases must be defined via the @testgroup macro instead of the testcase() function.\nCHANGED: similarly, fixtures are defined with @global_fixture and @local_fixture macros. fixture() and local_fixture() are no longer exported.\nCHANGED: not exporting rowmajor_product(), pprint_time(), with_output_capture() and build_run_options() anymore, since they are only used in self-tests.\nCHANGED: global fixtures now produce single values instead of whole lists, same as the local ones.\nADDED: @testcase and @testgroup macros.\nADDED: @global_fixture and @local_fixture macros.\nADDED: progress reporting is now more suitable for long group and testcase names.\nADDED: @test_fail macro for providing a custom description to a fail.\nADDED: re-exporting Base.Test\'s @inferred, @test_warn and @test_nowarn.\nADDED: testcases can now be defined directly before the call to runtests() instead of in specially named files.\nFIXED: output capture problems in Julia 0.6 on Windows."
},

{
    "location": "history.html#v0.0.3-(13-Aug-2017)-1",
    "page": "Version history",
    "title": "v0.0.3 (13 Aug 2017)",
    "category": "section",
    "text": "CHANGED: the abstract type TestcaseReturn was removed, @test_result can return any value now.\nCHANGED: delayed_teardown option of fixture() was changed to instant_teardown (false by default), since delayed teardown is the most common behavior.\nADDED: documentation\nADDED: displaying the testcase tag before proceeding to run it; looks a bit better for long-running testcases\nADDED: testcase tagging (see tag()) and filtering by tags.\nADDED: --max-fails command-line option to stop test run after a certain number of failures.\nADDED: showing the version info for Julia and Jute before the test run.\nADDED: --capture-output command-line option to capture all the output from testcases and only show the output from the failed ones in the end.\nADDED: runtests() now takes an options keyword that allows one to supply run options programmatically instead of through the command line.\nADDED: exporting with_output_capture() function (mostly to use in tests).\nFIXED: incorrect handling of the case when all tests are filtered out.\nFIXED: incorrect pretty printing of times smaller than 1 microsecond.Internals:Removed the unused dependency on IterTools"
},

{
    "location": "history.html#v0.0.2-(27-Jul-2017)-1",
    "page": "Version history",
    "title": "v0.0.2 (27 Jul 2017)",
    "category": "section",
    "text": "FIXED: time rounding logic\nFIXED: multiple performance improvements (both for test pick-up and execution)Internals:ADDED: some performance tests\nFIXED: deprecated syntax in rowmajor_product.jl\nFIXED: extending an external function on external types"
},

{
    "location": "history.html#v0.0.1-(23-Jul-2017)-1",
    "page": "Version history",
    "title": "v0.0.1 (23 Jul 2017)",
    "category": "section",
    "text": "Initial version."
},

]}
