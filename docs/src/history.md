# Version history


## v0.2.2 (25 Apr 2019)

Switching from Attobot to Registrator.jl.


## v0.2.1 (2 Nov 2018)

* ADDED: `@critical` macro to make test assertions terminate the testcase on failure.
* ADDED: for `verbosity=1`, display the results returned by `@test_result` separately.
* ADDED: printing the OS and the kernel info in the report header.
* FIXED: `@produce` hanging when passed a non-string label.
* FIXED: incorrect indentation with `verbosity=1` when a group has some testcases after nested groups.


## v0.2.0 (16 Sep 2018)

* **CHANGED**: support for Julia v0.6 dropped, support for v1.0 added.
* ADDED: command-line arguments (if used) now override the options passed to `runtests()` during the call.
* FIXED: an incorrect description for the `--dont-add-runtests-path` option.
* FIXED: include/exclude filtering for testcases is now correctly performed based on full testcase paths.


## v0.1.0 (1 Oct 2017)

* **CHANGED**: testcase groups are no longer defined by modules; `@testgroup` should be used instead. Consequently, the option `:test_module_prefix` was removed.
* **CHANGED**: testcases must be defined via the `@testgroup` macro instead of the `testcase()` function.
* **CHANGED**: similarly, fixtures are defined with `@global_fixture` and `@local_fixture` macros. `fixture()` and `local_fixture()` are no longer exported.
* **CHANGED**: not exporting `rowmajor_product()`, `pprint_time()`, `with_output_capture()` and `build_run_options()` anymore, since they are only used in self-tests.
* **CHANGED**: global fixtures now produce single values instead of whole lists, same as the local ones.
* ADDED: `@testcase` and `@testgroup` macros.
* ADDED: `@global_fixture` and `@local_fixture` macros.
* ADDED: progress reporting is now more suitable for long group and testcase names.
* ADDED: `@test_fail` macro for providing a custom description to a fail.
* ADDED: re-exporting `Base.Test`'s `@inferred`, `@test_warn` and `@test_nowarn`.
* ADDED: testcases can now be defined directly before the call to `runtests()` instead of in specially named files.
* FIXED: output capture problems in Julia 0.6 on Windows.


## v0.0.3 (13 Aug 2017)

* **CHANGED:** the abstract type `TestcaseReturn` was removed, `@test_result` can return any value now.
* **CHANGED:** `delayed_teardown` option of `fixture()` was changed to `instant_teardown` (`false` by default), since delayed teardown is the most common behavior.
* ADDED: documentation
* ADDED: displaying the testcase tag before proceeding to run it; looks a bit better for long-running testcases
* ADDED: testcase tagging (see `tag()`) and filtering by tags.
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
