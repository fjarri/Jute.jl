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
@inferred
@test_warn
@test_nowarn
```

`Jute` adds several assertions of its own.

```@docs
@test_result
@test_fail
```


## Built-in fixtures

```@docs
temporary_dir
run_options
```
