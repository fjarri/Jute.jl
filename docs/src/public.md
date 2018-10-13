# Public API


## Entry point

```@docs
runtests
```


## Testcases and fixtures

```@docs
@testcase
@testgroup
@global_fixture
@local_fixture
@produce
```


## Assertions

The following assertions are re-exported from [`Test`](https://docs.julialang.org/en/latest/stdlib/Test/) and can be used inside `Jute` testcases.

```@docs
@test
@test_throws
@test_broken
@test_skip
@inferred
@test_warn
@test_nowarn
```

`Jute` adds several assertions of its own.

```@docs
@test_result
@test_fail
```

Assertions can be made to terminate the testcase on failure.

```@docs
@critical
```


## Built-in fixtures

```@docs
temporary_dir
run_options
```
