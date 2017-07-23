# Jute, a Py.Test-inspired testing framework

**This project is in the alpha stage.**
It is an experimental project, and I am figuring out whether it is a good idea.
Use at your own risk.

The main principles of the framework:

* The test runner includes all the files named in a certain way (ending in `.test.jl` by default);
* Every module-scope variable (including the nested modules) of the `Testcase` type is interpreted as a testcase;
* Testcases are grouped based on modules they are in, not the files they are coming from;
* Testcases can be parametrized by fixtures, which can be simple iterables, or include a setup/teardown stage right before and after each test, or once before and after all the tests that use it.
* Fixtures can be parametrized by other fixtures.

There is a similar project out there: [`PyTest.jl`](https://github.com/pdobacz/PyTest.jl). `PyTest` integrates with `Base.Test`, so you get a familiar structure of your test suite and can use `PyTest.jl` only in a part of it. On the other hand, the separation of test pick-up and execution stages in `Jute` allows for more sophisticated test run logic, such as asynchronous and multi-process test run, or different fixture lifetimes.


## Defining tests

The entry-point file (commonly called `runtests.jl`) is simply:

```julia
using Jute
exit(runtests())
```

The test runner picks up any file with the name ending in `.test.jl` in the directory where the entry-point file is located, or in any subdirectories.
All those files are included at the same level, and module-scoped variables are extracted.
Anything not of the type `Jute.Testcase` is ignored.
The testcase name is the name of the variable it was found in, plus the names of the modules it is located in.

The `exit()` call is required to signal about any test failures to the processes that initiate the execution of the test suite, for instance CI tools.
`runtests()` returns `1` if there were failed tests, `0` otherwise.

The `Testcase` objects are returned by `Jute.testcase()`, that takes the testcase function as the first argument:

```julia
simple_testcase = testcase() do
    @test 1 == 1
end
```


## Assertions

`Jute` relies on the assertions from `Base.Test`; `@test`, `@test_throws`, `@test_skip` and `@test_broken` can be used.
In addition, `Jute` has a `@test_result` macro allowing one to return a custom result (e.g. the value of a benchmark from a testcase).
There can be several assertions per testcase; their results will be reported separately.
If the testcase does not call any assertions and does not throw any exceptions, it is considered to be passed.


## Grouping tests

Tests are grouped based on the modules in which they are defined in test files.
The names or locations of the files themselves do not affect the grouping.
For example, for the following files:

```julia
# one.test.jl
tc1 = testcase() do end

module Group
tc2 = testcase() do end
end

# two.test.jl
module Group2
module Subgroup
tc3 = testcase() do end
end
end
```

the following testcases will be listed:

```
tc1
Group/tc2
Group2/Subgroup/tc3
```


## Parametrizing tests

### Constant fixtures

The simplest method to parametrize a test is to supply it with an iterable:

```julia
parameterized_testcase = testcase([1, 2, 3]) do x
    @test x == 1
end

# Output:
# parameterized_testcase[1]: [PASS]
# parameterized_testcase[2]: [FAIL]
# parameterized_testcase[3]: [FAIL]
```

By default, `Jute` uses `string()` to convert a fixture value to a string for reporting purposes.
One can assign custom identifiers to fixtures by passing a `Pair` of iterables instead:

```julia
parameterized_testcase = testcase([1, 2, 3] => ["one", "two", "three"]) do x
    @test x == 1
end

# Output:
# parameterized_testcase[one]: [PASS]
# parameterized_testcase[two]: [FAIL]
# parameterized_testcase[three]: [FAIL]
```

A testcase can use several fixtures, in which case `Jute` will run the testcase function will all possible combinations of them:

```julia
parameterized_testcase = testcase([1, 2], [3, 4]) do x, y
    @test x + y == y + x
end

# Output:
# parameterized_testcase[1, 3]: [PASS]
# parameterized_testcase[1, 4]: [PASS]
# parameterized_testcase[2, 3]: [PASS]
# parameterized_testcase[2, 4]: [PASS]
```

### Global fixtures

A global fixture is a more sophisticated variant of the constant fixture that involves a setup and a teardown stage.
For each global fixture, the setup is called before the first testcase that uses it.
As for the teardown, it is either called right away (if the keyword parameter `delayed_teardown` is `false`), or after the last testcase that uses it (if `delayed_teardown=true`).
If no testcases use it (for example, they were filtered out), neither setup nor teardown are called.

The setup and the teardown are defined by use of a single coroutine that produces the fixture iterable:

```julia
db_connection = fixture(; delayed_teardown=true) do produce
    c = db_connect()

    # this call blocks until all the testcases
    # that use the fixture are executed
    produce([c])

    close(c)
end
```

Note that a global fixture musy produce **the whole iterable** in one go.

Similarly to the constant fixture case, one can provide a custom identifier for the fixture via the optional second argument of `produce()`:

```julia
db_connection = fixture(; delayed_teardown=true) do produce
    c = db_connect()

    # this call blocks until all the testcases
    # that use the fixture are executed
    produce([c], ["db_connection"])

    close(c)
end
```

Global fixtures can be parametrized by other constant or global fixtures.
Similarly to the test parametrization, all possible combinations of parameters will be used to produce iterables, which will be chained together:

```julia
fx1 = fixture() do produce
    produce(3:4)
end

fx2 = fixture(1:2, fx1) do produce, x, y
    produce([(x, y)])
end

tc = testcase(fx2) do x
    @test length(x) == 2
end

# Output:
# tc[(1, 3)]: [PASS]
# tc[(1, 4)]: [PASS]
# tc[(2, 3)]: [PASS]
# tc[(2, 4)]: [PASS]
```


### Local fixtures

A local fixture is a fixture whose value is created right before each call of the testcase function and destroyed afterwards.
A simple example is a fixture that provides a temporary directory:

```julia
temporary_dir = local_fixture() do produce
    dir = mktempdir()
    produce(dir) # this call will block while the testcase is being executed
    rm(dir, recursive=true)
end

temdir_test = testcase(temporary_dir) do dir
    open(joinpath(dir, "somefile"), "w")
end
```

Local fixtures can be parametrized by any other type of fixture, including other local fixtures.


## Command-line arguments

`Jute`'s `runtest()` supports a number of command-line arguments:

* `--include-only` (`-i`): takes a regular expression; tests with full names that do not match it will not be executed
* `--exclude` (`-e`): takes a regular expression; tests with full names that match it will not be executed
* `--verbosity` (`-v`): `0`, `1` or `2`, defines the amount of output that will be shown. `1` is the default.
