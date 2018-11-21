# Manual


## Defining tests

The entry-point file (commonly called `runtests.jl`) is:

```julia
using Jute

# Testcase definitions

exit(runtests())
```

If there were no [`@testcase`](@ref Jute.@testcase) and [`@testgroup`](@ref Jute.@testgroup) calls before the call to [`runtests()`](@ref Jute.runtests), the test runner picks up any file with the name ending in `.test.jl` (by default; can be changed with the command-line option `--test-file-postfix`) in the directory where the entry-point file is located, or in any subdirectories.
All those files are included at the same level (with `using Jute` at the start), and all the [`@testcase`](@ref Jute.@testcase) and [`@testgroup`](@ref Jute.@testgroup) definitions are picked up.

If some testcase definitions were present before the call to [`runtests()`](@ref Jute.runtests), they will be used and **consumed**, so the following calls to [`runtests()`](@ref Jute.runtests) will follow the first scenario (loading testcases from files).

The [`@testgroup`](@ref Jute.@testgroup) definitions can contain other [`@testgroup`](@ref Jute.@testgroup) definitions and [`@testcase`](@ref Jute.@testcase) definitions.

The `exit()` call is required to signal about any test failures to the processes that initiate the execution of the test suite, for instance, CI tools.
[`runtests()`](@ref Jute.runtests) returns `1` if there were failed tests, `0` otherwise.

!!! note

    In all the following examples the `exit()` call will be missing because of the limitations of the `Documenter`'s doctest runner.
    Also, `using Jute` will be implied.


## Basic testcases and groups

In the simple case of a non-parametrized test, the [`@testcase`](@ref Jute.@testcase) macro takes the testcase name and body.
Testcases can be grouped using [`@testgroup`](@ref Jute.@testgroup) definitions.
For example:

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest grouping
@testcase "tc1" begin
end

@testgroup "group" begin
    @testcase "tc2" begin
    end
end

@testgroup "group2" begin
    @testgroup "subgroup" begin
        @testcase "tc3" begin
        end
    end
end

runtests(; options=Dict(:verbosity => 2))

# output

Collecting testcases...
Using 3 out of 3 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
tc1 ([...] ms) [PASS]
group/
  tc2 ([...] ms) [PASS]
group2/
  subgroup/
    tc3 ([...] ms) [PASS]
--------------------------------------------------------------------------------
3 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```

The order of testcase definition is preserved.
In other words, the testcases will be executed in the same order in which they were defined.


## Assertions

`Jute` relies on the assertions from [`Test`](https://docs.julialang.org/en/latest/stdlib/Test/); [`@test`](@ref Jute.@test), [`@test_throws`](@ref Jute.@test_throws), [`@test_skip`](@ref Jute.@test_skip), [`@test_broken`](@ref Jute.@test_broken), [`@inferred`](@ref Jute.@inferred), [`@test_warn`](@ref Jute.@test_warn) and [`@test_nowarn`](@ref Jute.@test_nowarn) can be used.
In addition, `Jute` has a [`@test_result`](@ref Jute.@test_result) macro allowing one to return a custom result (e.g. the value of a benchmark from a testcase), and a [`@test_fail`](@ref Jute.@test_fail) macro for providing custom information with a fail.
There can be several assertions per testcase; their results will be reported separately.
If the testcase does not call any assertions and does not throw any exceptions, it is considered to be passed.


## Parametrizing testcases


### Constant fixtures

The simplest method to parametrize a test is to supply it with an iterable:

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest parametrize_simple
@testcase "parametrized testcase" for x in [1, 2, 3]
    @test x == x
end

runtests(; options=Dict(:verbosity => 2))

# output

Collecting testcases...
Using 1 out of 1 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
parametrized testcase [1] ([...] ms) [PASS]
parametrized testcase [2] ([...] ms) [PASS]
parametrized testcase [3] ([...] ms) [PASS]
--------------------------------------------------------------------------------
3 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```

By default, `Jute` uses `string()` to convert a fixture value to a string for reporting purposes.
One can assign custom labels to fixtures by passing a `Pair` of iterables instead:

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest custom_labels
@testcase "parametrized testcase" for x in ([1, 2, 3] => ["one", "two", "three"])
    @test x == x
end

runtests(; options=Dict(:verbosity => 2))

# output

Collecting testcases...
Using 1 out of 1 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
parametrized testcase [one] ([...] ms) [PASS]
parametrized testcase [two] ([...] ms) [PASS]
parametrized testcase [three] ([...] ms) [PASS]
--------------------------------------------------------------------------------
3 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```

A testcase can use several fixtures, in which case `Jute` will run the testcase function with all possible combinations of them:

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest several_fixtures
@testcase "parametrized testcase" for x in [1, 2], y in [3, 4]
    @test x + y == y + x
end

runtests(; options=Dict(:verbosity => 2))

# output

Collecting testcases...
Using 1 out of 1 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
parametrized testcase [1,3] ([...] ms) [PASS]
parametrized testcase [1,4] ([...] ms) [PASS]
parametrized testcase [2,3] ([...] ms) [PASS]
parametrized testcase [2,4] ([...] ms) [PASS]
--------------------------------------------------------------------------------
4 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```

Iterable unpacking is also supported:

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest fixture_unpacking
@testcase "parametrized testcase" for (x, y) in [(1, 2), (3, 4)]
    @test x + y == y + x
end

runtests(; options=Dict(:verbosity => 2))

# output

Collecting testcases...
Using 1 out of 1 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
parametrized testcase [(1, 2)] ([...] ms) [PASS]
parametrized testcase [(3, 4)] ([...] ms) [PASS]
--------------------------------------------------------------------------------
2 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```

Note that the label still refers to the full element of the iterable.

!!! note

    If the iterable expression evaluates to anything other than a fixture object, it will be treated as a constant fixture.
    In other words, if an expression like `for (x, y) in [fixture1, fixture2, fixture3]` is used to parametrize a testcase or a fixture, the nested fixtures will not be processed and added to the dependencies.


### Global fixtures

A global fixture is a more sophisticated variant of a constant fixture that has a setup and a teardown stage.
For each value produced by the global fixture, the setup is called before the first testcase that uses it.
As for the teardown, it is either called right away (if the option `instant_teardown` is `true`) or after the last testcase that uses it (if `instant_teardown` is `false`, which is the default).
If no testcases use it (for example, they were filtered out), neither setup nor teardown will be called.

The setup and the teardown are defined by use of a single coroutine that produces the fixture value.
The coroutine's first argument is a function that is used to return the value.
If `instant_teardown` is `false`, the call blocks until it is time to execute the teardown:

```julia
db_connection = @global_fixture begin
    c = db_connect()

    # this call blocks until all the testcases
    # that use this value are executed
    @produce c

    close(c)
end
```

Similarly to the constant fixture case, one can provide a custom identifier for the fixture via the optional second argument of [`@produce`](@ref Jute.@produce):

```julia
db_connection = @global_fixture begin
    c = db_connect()

    @produce c "db_connection"

    close(c)
end
```

Global fixtures can be parametrized by other constant or global fixtures.
Similarly to the test parametrization, all possible combinations of parameters will be used to produce values:

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest global_fixtures
fx1 = @global_fixture for x in 3:4
    @produce x
end

fx2 = @global_fixture for x in 1:2, y in fx1
    @produce (x, y)
end

@testcase "tc" for x in fx2
    @test length(x) == 2
end

runtests(; options=Dict(:verbosity => 2))

# output

Collecting testcases...
Using 1 out of 1 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
tc [(1, 3)] ([...] ms) [PASS]
tc [(1, 4)] ([...] ms) [PASS]
tc [(2, 3)] ([...] ms) [PASS]
tc [(2, 4)] ([...] ms) [PASS]
--------------------------------------------------------------------------------
4 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```


### Local fixtures

A local fixture is a fixture whose value is created right before each call to the testcase function and destroyed afterwards.
A simple example is a fixture that provides a temporary directory:

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest local_fixtures
temporary_dir = @local_fixture begin
    dir = mktempdir()
    @produce dir "tempdir" # this call will block while the testcase is being executed
    rm(dir, recursive=true)
end

@testcase "tempdir test" for dir in temporary_dir
    @test isdir(dir)
end

runtests(; options=Dict(:verbosity => 2))

# output

Collecting testcases...
Using 1 out of 1 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
tempdir test [tempdir] ([...] ms) [PASS]
--------------------------------------------------------------------------------
1 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```

Local fixtures can be parametrized by any other type of fixture, including other local fixtures.


## Testcase tags

Testcases can be assigned tags of the type `Symbol`.
This can be used to establish a secondary grouping, independent of the primary grouping provided by modules.
For example, one can tag performance tests, tests that run for a long time, unit/integration tests, tests that require a specific resource and so on.
Testcases can be filtered by tags they have or don't have using [command-line arguments](@ref run_options_manual).

The tagging is performed by the optional parameter `tag` to the macro [`@testcase`](@ref Jute.@testcase) that takes a list of `Symbol`s:

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest tags
@testcase tags=[:foo] "foo" begin
end

@testcase tags=[:bar, :baz] "bar and baz" begin
end

runtests(; options=Dict(:verbosity => 2, :include_only_tags => [:baz]))

# output

Collecting testcases...
Using 1 out of 2 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
bar and baz ([...] ms) [PASS]
--------------------------------------------------------------------------------
1 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```


## [Run options](@id run_options_manual)

`Jute`'s [`runtest()`](@ref Jute.runtests) picks up the options from the command line by default.
Alternatively, they can be set with the `options` keyword argument of [`runtests()`](@ref Jute.runtests).
Note that command-line arguments override the ones passed via `options`.

```@docs
Jute.build_parser
```

Run options can be accessed from a testcase or a fixture via the built-in fixture [`run_options`](@ref Jute.run_options).
