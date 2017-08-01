# Version history


## Current development version

* **CHANGED:** the abstract type `TestcaseReturn` was removed, [`@test_result`](@ref Jute.@test_result) can return any value now.
* **CHANGED:** `delayed_teardown` option of [`fixture()`](@ref Jute.fixture) was changed to `instant_teardown` (`false` by default), since delayed teardown is the most common behavior.
* ADDED: documentation
* ADDED: displaying the testcase tag before proceeding to run it; looks a bit better for long-running testcases

Internals:

* Removed the unused dependency on `IterTools`


## v0.0.2 (27 Jul 2017)

* FIXED: time rounding logic
* FIXED: multiple performance improvements (both for test pick-up and execution)

Internals:

* ADDED: some performance tests
* FIXED: deprecated syntax in `rowmajor_product.jl`
* FIXED: extending an external function on external types


## v0.0.1 (23 Jul 2017)

Initial version.
