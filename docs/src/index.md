# Jute, a Py.Test-inspired testing framework

The main principles of the library:

* The test runner `include()`s all the files named in a certain way (ending in `.test.jl` by default). Alternatively, the files containing testcase definitions can be included manually;
* Testcases are defined using the [`@testcase`](@ref Jute.@testcase) macro and grouped using the [`@testgroup`](@ref Jute.@testgroup) macro;
* Testcases can be parametrized by fixtures, which can be simple iterables, or include a setup/teardown stage right before and after each test, or once before and after all the tests that use it.
* Fixtures can be parametrized by other fixtures.


## A quick example

```@meta
DocTestSetup = quote
    using Jute
    Jute.jute_doctest()
end
```

```jldoctest index
using Jute

# constant fixture - any iterable
fx1 = 1:3

# global fixture - the setup/teardown function is run once
# for every produced value
fx2 = @global_fixture for x in fx1
    # the optional second argument defines a custom label for the value
    @produce x "value $x"
end

# local fixture - the setup/teardown function is run for each testcase
# and each value produced by `fx2`
fx3 = @local_fixture for x in fx2
    @produce (x + 1)
end

# testcase - will be picked up automatically
# and run for all the combinations of fixture values
@testcase "tc" for x in fx1, y in fx2, z in fx3
    @test x + y == y + x
    @test x + y + z == z + y + x
end

runtests()

# output

Collecting testcases...
Using 1 out of 1 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
......................................................
--------------------------------------------------------------------------------
54 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```
