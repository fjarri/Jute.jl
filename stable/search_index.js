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
    "text": "The main principles of the library:The test runner include()s all the files named in a certain way (ending in .test.jl by default);\nEvery module-scope variable (including the nested modules) of the Testcase type is interpreted as a testcase;\nTestcases are grouped based on modules they are in, not the files they are coming from;\nTestcases can be parametrized by fixtures, which can be simple iterables, or include a setup/teardown stage right before and after each test, or once before and after all the tests that use it.\nFixtures can be parametrized by other fixtures."
},

{
    "location": "index.html#A-quick-example-1",
    "page": "Home",
    "title": "A quick example",
    "category": "section",
    "text": "Directory structure:test/\n    foo.test.jl # tests are here\n    runtests.jl # the entry pointruntests.jl:using Jute\nexit(runtests())foo.test.jl:using Jute\n\n# constant fixture - any iterable\nfx1 = 1:3\n\n# global fixture - the setup/teardown function is run once\nfx2 = fixture() do produce\n    x = 1\n    y = 2\n    produce([x, y], [\"random1\", \"random2\"]) # must produce a list of values\nend\n\n# local fixture - the setup/teardown function is run for each testcase\n# and each value produced by `fx2`\nfx3 = local_fixture(fx2) do produce, x\n    produce(x + 1) # must produce a single value\nend\n\n# testcase - will be picked up automatically\n# and run for all the combinations of fixture values\ntc = testcase(fx1, fx2, fx3) do x, y, z\n    @test x + y == 2\n    @test x + y + z == z + y + x\nend"
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
    "text": "The entry-point file (commonly called runtests.jl) is simply:using Jute\nexit(runtests())The test runner picks up any file with the name ending in .test.jl in the directory where the entry-point file is located, or in any subdirectories. All those files are included at the same level, and module-scoped variables are extracted. Anything not of the type Testcase is ignored. The testcase name is the name of the variable it was found in, plus the names of the modules it is located in.The exit() call is required to signal about any test failures to the processes that initiate the execution of the test suite, for instance CI tools. runtests() returns 1 if there were failed tests, 0 otherwise.The Testcase objects are returned by testcase(), that takes the testcase function as the first argument:simple_testcase = testcase() do\n    @test 1 == 1\nend"
},

{
    "location": "manual.html#Assertions-1",
    "page": "Manual",
    "title": "Assertions",
    "category": "section",
    "text": "Jute relies on the assertions from Base.Test; @test, @test_throws, @test_skip and @test_broken can be used. In addition, Jute has a @test_result macro allowing one to return a custom result (e.g. the value of a benchmark from a testcase). There can be several assertions per testcase; their results will be reported separately. If the testcase does not call any assertions and does not throw any exceptions, it is considered to be passed."
},

{
    "location": "manual.html#Grouping-tests-1",
    "page": "Manual",
    "title": "Grouping tests",
    "category": "section",
    "text": "Tests are grouped based on the modules in which they are encountered in test files. The names or locations of the files themselves do not affect the grouping. For example, for the following files:# one.test.jl\ntc1 = testcase() do end\n\nmodule Group\ntc2 = testcase() do end\nend\n\n# two.test.jl\nmodule Group2\nmodule Subgroup\ntc3 = testcase() do end\nend\nendthe following testcases will be listed:tc1\nGroup/tc2\nGroup2/Subgroup/tc3For each file the order of Testcase object creation in it is preserved. In other words, the testcases will be executed in the same order in which they were defined."
},

{
    "location": "manual.html#Parametrizing-tests-1",
    "page": "Manual",
    "title": "Parametrizing tests",
    "category": "section",
    "text": ""
},

{
    "location": "manual.html#Constant-fixtures-1",
    "page": "Manual",
    "title": "Constant fixtures",
    "category": "section",
    "text": "The simplest method to parametrize a test is to supply it with an iterable:parameterized_testcase = testcase([1, 2, 3]) do x\n    @test x == 1\nend\n\n# Output:\n# parameterized_testcase[1]: [PASS]\n# parameterized_testcase[2]: [FAIL]\n# parameterized_testcase[3]: [FAIL]By default, Jute uses string() to convert a fixture value to a string for reporting purposes. One can assign custom labels to fixtures by passing a Pair of iterables instead:parameterized_testcase = testcase([1, 2, 3] => [\"one\", \"two\", \"three\"]) do x\n    @test x == 1\nend\n\n# Output:\n# parameterized_testcase[one]: [PASS]\n# parameterized_testcase[two]: [FAIL]\n# parameterized_testcase[three]: [FAIL]A testcase can use several fixtures, in which case Jute will run the testcase function will all possible combinations of them:parameterized_testcase = testcase([1, 2], [3, 4]) do x, y\n    @test x + y == y + x\nend\n\n# Output:\n# parameterized_testcase[1, 3]: [PASS]\n# parameterized_testcase[1, 4]: [PASS]\n# parameterized_testcase[2, 3]: [PASS]\n# parameterized_testcase[2, 4]: [PASS]"
},

{
    "location": "manual.html#Global-fixtures-1",
    "page": "Manual",
    "title": "Global fixtures",
    "category": "section",
    "text": "A global fixture is a more sophisticated variant of a constant fixture that has a setup and a teardown stage. For each global fixture, the setup is called before the first testcase that uses it. As for the teardown, it is either called right away (if the keyword parameter instant_teardown is true), or after the last testcase that uses it (if instant_teardown is false, which is the default). If no testcases use it (for example, they were filtered out), neither setup nor teardown will be called.The setup and the teardown are defined by use of a single coroutine that produces the fixture iterable. The coroutine's first argument is a function that is used to return the fixture values. If instant_teardown is false, the call blocks until it is time to execute the teardown:db_connection = fixture() do produce\n    c = db_connect()\n\n    # this call blocks until all the testcases\n    # that use the fixture are executed\n    produce([c])\n\n    close(c)\nendNote that a global fixture must produce the whole iterable in one go.Similarly to the constant fixture case, one can provide a custom identifier for the fixture via the optional second argument of produce():db_connection = fixture() do produce\n    c = db_connect()\n\n    # this call blocks until all the testcases\n    # that use the fixture are executed\n    produce([c], [\"db_connection\"])\n\n    close(c)\nendGlobal fixtures can be parametrized by other constant or global fixtures. Similarly to the test parametrization, all possible combinations of parameters will be used to produce iterables, which will be chained together:fx1 = fixture() do produce\n    produce(3:4)\nend\n\nfx2 = fixture(1:2, fx1) do produce, x, y\n    produce([(x, y)])\nend\n\ntc = testcase(fx2) do x\n    @test length(x) == 2\nend\n\n# Output:\n# tc[(1, 3)]: [PASS]\n# tc[(1, 4)]: [PASS]\n# tc[(2, 3)]: [PASS]\n# tc[(2, 4)]: [PASS]"
},

{
    "location": "manual.html#Local-fixtures-1",
    "page": "Manual",
    "title": "Local fixtures",
    "category": "section",
    "text": "A local fixture is a fixture whose value is created right before each call to the testcase function and destroyed afterwards. A simple example is a fixture that provides a temporary directory:temporary_dir = local_fixture() do produce\n    dir = mktempdir()\n    produce(dir) # this call will block while the testcase is being executed\n    rm(dir, recursive=true)\nend\n\ntemdir_test = testcase(temporary_dir) do dir\n    open(joinpath(dir, \"somefile\"), \"w\")\nendNote that, unlike a global fixture, a local fixture only produces one value. Local fixtures can be parametrized by any other type of fixture, including other local fixtures."
},

{
    "location": "manual.html#Testcase-tags-1",
    "page": "Manual",
    "title": "Testcase tags",
    "category": "section",
    "text": "Testcases can be assigned tags of the type Symbol. This can be used to establish a secondary grouping, independent of the primary grouping provided by modules. For example, one can tag performance tests, tests that run for a long time, unit/integration tests, tests that require a specific resource and so on. Testcases can be filtered by tags they have or don't have using command-line arguments.The tagging is performed by the function tag() that takes a Symbol and returns a function that tags a testcase:tc = tag(:foo)(testcase() do\n    ... something\nend)It is convenient to use the <| operator:tc =\n    tag(:foo) <|\n    testcase() do\n        ... something\n    endA tag can be removed from a testcase using untag. Note that tagging and untagging commands are applied from inner to outer, so, for example, the following codetc =\n    tag(:foo) <|\n    untag(:bar) <|\n    untag(:foo) <|\n    tag(:bar) <|\n    testcase() do\n        ... something\n    endwill leave tc with the tag :foo, but without the tag :bar."
},

{
    "location": "manual.html#Jute.build_parser",
    "page": "Manual",
    "title": "Jute.build_parser",
    "category": "Function",
    "text": "For every option, the corresponding command-line argument names are given in parentheses. If supplied via the options keyword argument of runtests(), their type must be as given or convert()-able to it.\n\n:include_only:: Nullable{Regex} (--include-only, -i): takes a regular expression; tests with full names that do not match it will not be executed.\n\n:exclude:: Nullable{Regex} (--exclude, -e): takes a regular expression; tests with full names that match it will not be executed.\n\n:verbosuty:: Int (--verbosity, -v): 0, 1 or 2, defines the amount of output that will be shown. 1 is the default.\n\n:include_only_tags:: Array{Symbol, 1} (--include-only-tags, -t): include only tests with any of the specified tags. You can pass several tags to this option, separated by spaces.\n\n:exclude_tags:: Array{Symbol, 1} (--exclude-tags, -t): exclude tests with any of the specified tags. You can pass several tags to this option, separated by spaces.\n\n:max_fails:: Int (--max-fails): stop after the given amount of failed testcases (a testcase is considered failed, if at least one test in it failed, or an unhandeld exception was thrown).\n\n:capture_output:: Bool (--capture-output): capture all the output from testcases and only show the output of the failed ones in the end of the test run.\n\nwarning: Warning\nAt the moment, output capture does not work in Julia 0.6 on Windows. See Julia issue 23198 for details.\n\n:dont_add_runtests_path::: Bool (`–dont-add-runtests-path): capture testcase output and display only the output from failed testcases after all the testcases are finished.\n\n:test_file_postifx:: String (--test-file-postfix): postfix of the files which will be picked up by the automatic testcase discovery.\n\n:test_module_prefix:: String (--test-module-prefix): prefix of the modules which will be searched for testcases during automatic testcase discovery.\n\n\n\n"
},

{
    "location": "manual.html#run_options_manual-1",
    "page": "Manual",
    "title": "Run options",
    "category": "section",
    "text": "Jute's runtest() picks up the options from the command line by default. Alternatively, they can be set with the options keyword argument of runtests().Jute.build_parserRun options can be accessed from a testcase or a fixture via the built-in fixture run_options."
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
    "category": "Function",
    "text": "runtests(; options=nothing)\n\nRun the test suite.\n\nThis function has several side effects:\n\nit parses the command-line arguments, using them to build the dictionary of run options (see Run options in the manual for the list);\nit picks up and includes the test files, selected according to the options.\n\noptions must be a dictionary with the keys corresponding to some of the options from the above list. If options is given, command-line arguments are not parsed.\n\nReturns 0 if there are no failed tests, 1 otherwise.\n\n\n\n"
},

{
    "location": "public.html#Entry-point-1",
    "page": "Public API",
    "title": "Entry point",
    "category": "section",
    "text": "runtests"
},

{
    "location": "public.html#Jute.testcase",
    "page": "Public API",
    "title": "Jute.testcase",
    "category": "Function",
    "text": "testcase(func, params...)\n\nDefine a testcase.\n\nfunc is a testcase function. The number of function parameters must be equal to the number of parametrizing fixtures given in params. This function will be called with all combinations of values of fixtures from params.\n\nparams are either fixtures, iterables or pairs of two iterables used to parametrize the function. In the latter case, the first iterable will be used to produce the values, and the second one to produce the corresponding labels (for logging).\n\nReturns a Testcase object.\n\n\n\n"
},

{
    "location": "public.html#Jute.fixture",
    "page": "Public API",
    "title": "Jute.fixture",
    "category": "Function",
    "text": "fixture(func, params...; instant_teardown=false)\n\nCreate a global fixture (a fixture set up once before all the testcases that use it and torn down after they finish).\n\nfunc is a function with length(params) + 1 parameters. The first parameter takes a function produce(values[, labels]) that is used to return the fixture iterable (with an optional iterable of labels). The rest take the values of the dependent fixtures from params.\n\nparams are either fixtures (constant of global only), iterables or pairs of two iterables used to parametrize the fixture.\n\nReturns a GlobalFixture object.\n\n\n\n"
},

{
    "location": "public.html#Jute.local_fixture",
    "page": "Public API",
    "title": "Jute.local_fixture",
    "category": "Function",
    "text": "local_fixture(func, params...)\n\nCreate a local fixture (a fixture set up before each testcase that uses it and torn down afterwards).\n\nfunc is a function with length(params) + 1 parameters. The first parameter takes a function produce(value[, label]) that is used to return the fixture value (with an optional label). The rest take the values of the dependent fixtures from params.\n\nparams are either fixtures (of any type), iterables or pairs of two iterables used to parametrize the fixture.\n\nReturns a LocalFixture object.\n\n\n\n"
},

{
    "location": "public.html#Testcases-and-fixtures-1",
    "page": "Public API",
    "title": "Testcases and fixtures",
    "category": "section",
    "text": "testcasefixturelocal_fixture"
},

{
    "location": "public.html#Base.Test.@test",
    "page": "Public API",
    "title": "Base.Test.@test",
    "category": "Macro",
    "text": "@test ex\n@test f(args...) key=val ...\n\nTests that the expression ex evaluates to true. Returns a Pass Result if it does, a Fail Result if it is false, and an Error Result if it could not be evaluated.\n\nThe @test f(args...) key=val... form is equivalent to writing @test f(args..., key=val...) which can be useful when the expression is a call using infix syntax such as approximate comparisons:\n\n@test a ≈ b atol=ε\n\nThis is equivalent to the uglier test @test ≈(a, b, atol=ε). It is an error to supply more than one expression unless the first is a call expression and the rest are assignments (k=v).\n\n\n\n"
},

{
    "location": "public.html#Base.Test.@test_throws",
    "page": "Public API",
    "title": "Base.Test.@test_throws",
    "category": "Macro",
    "text": "@test_throws exception expr\n\nTests that the expression expr throws exception. The exception may specify either a type, or a value (which will be tested for equality by comparing fields). Note that @test_throws does not support a trailing keyword form.\n\n\n\n"
},

{
    "location": "public.html#Base.Test.@test_broken",
    "page": "Public API",
    "title": "Base.Test.@test_broken",
    "category": "Macro",
    "text": "@test_broken ex\n@test_broken f(args...) key=val ...\n\nIndicates a test that should pass but currently consistently fails. Tests that the expression ex evaluates to false or causes an exception. Returns a Broken Result if it does, or an Error Result if the expression evaluates to true.\n\nThe @test_broken f(args...) key=val... form works as for the @test macro.\n\n\n\n"
},

{
    "location": "public.html#Base.Test.@test_skip",
    "page": "Public API",
    "title": "Base.Test.@test_skip",
    "category": "Macro",
    "text": "@test_skip ex\n@test_skip f(args...) key=val ...\n\nMarks a test that should not be executed but should be included in test summary reporting as Broken. This can be useful for tests that intermittently fail, or tests of not-yet-implemented functionality.\n\nThe @test_skip f(args...) key=val... form works as for the @test macro.\n\n\n\n"
},

{
    "location": "public.html#Jute.@test_result",
    "page": "Public API",
    "title": "Jute.@test_result",
    "category": "Macro",
    "text": "@test_result expr\n\nRecords a result from the test. The result of expr will be displayed in the report by calling string() on it.\n\n\n\n"
},

{
    "location": "public.html#Assertions-1",
    "page": "Public API",
    "title": "Assertions",
    "category": "section",
    "text": "The following assertions are re-exported from Base.Test and can be used inside Jute testcases.@test\n@test_throws\n@test_broken\n@test_skipThis is an additional assertion, allowing one to record an arbitrary value as a test result.@test_result"
},

{
    "location": "public.html#Jute.tag",
    "page": "Public API",
    "title": "Jute.tag",
    "category": "Function",
    "text": "tag(::Symbol)\n\nReturns a function that tags a testcase with the given tag:\n\ntc = tag(:foo)(testcase() do\n    ... something\nend)\n\nTestcases can be filtered in/out using run options. It is convenient to use the <| operator:\n\ntc =\n    tag(:foo) <|\n    testcase() do\n        ... something\n    end\n\nNote that tag and untag commands are applied from inner to outer.\n\n\n\n"
},

{
    "location": "public.html#Jute.untag",
    "page": "Public API",
    "title": "Jute.untag",
    "category": "Function",
    "text": "untag(::Symbol)\n\nReturns a function that untags a testcase with the given tag. See tag for more details.\n\n\n\n"
},

{
    "location": "public.html#Jute.:<|",
    "page": "Public API",
    "title": "Jute.:<|",
    "category": "Function",
    "text": "<|(f, x) === f(x)\n\nA helper operator that makes applying testcase tags slightly more graceful. See tag for an example.\n\n\n\n"
},

{
    "location": "public.html#Testcase-tags-1",
    "page": "Public API",
    "title": "Testcase tags",
    "category": "section",
    "text": "tag\nuntag\n<|"
},

{
    "location": "public.html#Jute.temporary_dir",
    "page": "Public API",
    "title": "Jute.temporary_dir",
    "category": "Constant",
    "text": "A local fixture that creates a temporary directory and returns its name; the directory and all its contents is removed during the teardown.\n\n\n\n"
},

{
    "location": "public.html#Jute.run_options",
    "page": "Public API",
    "title": "Jute.run_options",
    "category": "Constant",
    "text": "A global fixture that returns the dictionary with the current run options (see Run options in the manual for the full list.\n\n\n\n"
},

{
    "location": "public.html#Built-in-fixtures-1",
    "page": "Public API",
    "title": "Built-in fixtures",
    "category": "section",
    "text": "temporary_dir\nrun_options"
},

{
    "location": "public.html#Jute.rowmajor_product",
    "page": "Public API",
    "title": "Jute.rowmajor_product",
    "category": "Function",
    "text": "rowmajor_product(xss...)\n\nIterate over all combinations in the cartesian product of the inputs. Similar to IterTools.product(), but iterates in row-major order (that is, the first iterator is iterated the slowest).\n\n\n\n"
},

{
    "location": "public.html#Jute.pprint_time",
    "page": "Public API",
    "title": "Jute.pprint_time",
    "category": "Function",
    "text": "pprint_time(s; meaningful_digits=0)\n\nReturns a string that represents a given time (in seconds) as a value scaled to the appropriate unit (minutes, hours, milliseconds etc) and rounded to a given number of meaningful digits (if it is smaller than a minute). If the latter is 0, the result is rounded to an integer at all times.\n\n\n\n"
},

{
    "location": "public.html#Jute.with_output_capture",
    "page": "Public API",
    "title": "Jute.with_output_capture",
    "category": "Function",
    "text": "with_output_capture(func, pass_through=false)\n\nExecute the callable func and capture its output (both STDOUT and STDERR) in a string. Returns a tuple of the func's return value and its output. If pass_through is true, does not capture anything and returns an empty string instead of the output.\n\n\n\n"
},

{
    "location": "public.html#Utilities-1",
    "page": "Public API",
    "title": "Utilities",
    "category": "section",
    "text": "rowmajor_product\npprint_time\nwith_output_capture"
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
    "category": "Type",
    "text": "Testcase type.\n\n\n\n"
},

{
    "location": "internals.html#Jute.GlobalFixture",
    "page": "Internals",
    "title": "Jute.GlobalFixture",
    "category": "Type",
    "text": "Global fixture type\n\n\n\n"
},

{
    "location": "internals.html#Jute.LocalFixture",
    "page": "Internals",
    "title": "Jute.LocalFixture",
    "category": "Type",
    "text": "Local fixture type\n\n\n\n"
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
    "location": "history.html#Current-development-version-1",
    "page": "Version history",
    "title": "Current development version",
    "category": "section",
    "text": "Under construction."
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
