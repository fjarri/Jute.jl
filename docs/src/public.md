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


## Testcase tags

```@docs
tag
untag
<|
```

## Built-in fixtures

```@docs
temporary_dir
run_options
```


## Utilities

```@docs
rowmajor_product
pprint_time
with_output_capture
```
