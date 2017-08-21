# Public API


## Entry point

```@docs
runtests
```


## Testcases and fixtures

```@docs
@testcase
@testgroup
fixture
local_fixture
```


## Assertions

The following assertions are re-exported from [`Base.Test`](https://docs.julialang.org/en/stable/stdlib/test/) and can be used inside `Jute` testcases.

```@docs
@test
@test_throws
@test_broken
@test_skip
```

This is an additional assertion, allowing one to record an arbitrary value as a test result.

```@docs
@test_result
```


## Built-in fixtures

```@docs
temporary_dir
run_options
```
