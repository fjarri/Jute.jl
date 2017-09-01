# Jute, a Py.Test-inspired testing framework

The main principles of the library:

* The test runner `include()`s all the files named in a certain way (ending in `.test.jl` by default);
* Every module-scope variable (including the nested modules) of the [`Testcase`](@ref Jute.Testcase) type is interpreted as a testcase;
* Testcases are grouped based on modules they are in, not the files they are coming from;
* Testcases can be parametrized by fixtures, which can be simple iterables, or include a setup/teardown stage right before and after each test, or once before and after all the tests that use it.
* Fixtures can be parametrized by other fixtures.


## A quick example

Directory structure:

```
test/
    foo.test.jl # tests are here
    runtests.jl # the entry point
```

`runtests.jl`:

```julia
using Jute
exit(runtests())
```

`foo.test.jl`:

```julia
using Jute

# constant fixture - any iterable
fx1 = 1:3

# global fixture - the setup/teardown function is run once
# for every produced value
fx2 = fixture(fx1) do produce, x
    # the optional second argument defines a custom label for the value
    produce(x, "value $x")
end

# local fixture - the setup/teardown function is run for each testcase
# and each value produced by `fx2`
fx3 = local_fixture(fx2) do produce, x
    produce(x + 1)
end

# testcase - will be picked up automatically
# and run for all the combinations of fixture values
@testcase "tc" for x in fx1, y in fx2, z in fx3
    @test x + y == 2
    @test x + y + z == z + y + x
end
```
