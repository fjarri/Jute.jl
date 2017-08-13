# Version history


## Current development version

Under construction.


## v0.0.3 (13 Aug 2017)

* **CHANGED:** the abstract type `TestcaseReturn` was removed, [`@test_result`](@ref Jute.@test_result) can return any value now.
* **CHANGED:** `delayed_teardown` option of [`fixture()`](@ref Jute.fixture) was changed to `instant_teardown` (`false` by default), since delayed teardown is the most common behavior.
* ADDED: documentation
* ADDED: displaying the testcase tag before proceeding to run it; looks a bit better for long-running testcases
* ADDED: testcase tagging (see [`tag()`](@ref Jute.tag)) and filtering by tags.
* ADDED: `--max-fails` command-line option to stop test run after a certain number of failures.
* ADDED: showing the version info for Julia and Jute before the test run.
* ADDED: `--capture-output` command-line option to capture all the output from testcases and only show the output from the failed ones in the end.
* ADDED: `runtests()` now takes an `options` keyword that allows one to supply run options programmatically instead of through the command line.
* ADDED: exporting `with_output_capture()` function (mostly to use in tests).
* FIXED: incorrect handling of the case when all tests are filtered out.
* FIXED: incorrect pretty printing of times smaller than 1 microsecond.

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
