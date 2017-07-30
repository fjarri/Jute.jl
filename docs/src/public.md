# Public API


## Entry point

```@docs
runtests
```


## Testcases and fixtures

```@docs
testcase
```

```@docs
fixture
```

```@docs
local_fixture
```


## Assertions

The following assertions are re-exported from `Base.Test` and can be used inside `Jute` testcases.

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


## Run options

```@docs
RunOptions
```

See also the builtin fixture [`run_options`](@ref Jute.run_options) if you want to access the options in a testcase.


## Built-in fixtures

```@docs
run_options
```

```@docs
temporary_dir
```


## Utilities

```@docs
rowmajor_product
```

```@docs
pprint_time
```
