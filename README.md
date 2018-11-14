# Jute, a Py.Test-inspired testing framework

Master branch: [![Travis build status](https://travis-ci.org/fjarri/Jute.jl.svg?branch=master)](https://travis-ci.org/fjarri/Jute.jl) [![Appveyor build status](https://ci.appveyor.com/api/projects/status/3k77mqb4549cwcjg?svg=true)](https://ci.appveyor.com/project/fjarri/jute-jl) [![Coverage Status](https://codecov.io/gh/fjarri/Jute.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/fjarri/Jute.jl)

As opposed to [`Test`](http://docs.julialang.org/en/latest/stdlib/Test/) which executes the tests as it compiles the source files, `Jute` collects the testcases first.
This makes it possible to implement many advanced features, such as testcase filtering, testcase parametrization, fixtures with different setup/teardown strategies, and others.
As a bonus, you do not need to manually include the files with tests, since they are picked up automatically.
On the other hand, this approach leads to more execution time overhead, both per-test and global.

A compromise between the two approaches is [`PyTest.jl`](https://github.com/pdobacz/PyTest.jl) which extends `Test` to add more advanced fixture functionality.

A brief usage example:
```
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
```

When executed, it outputs:
```
Collecting testcases...
Using 1 out of 1 testcase definitions...
================================================================================
Platform: [...], Julia [...], Jute [...]
--------------------------------------------------------------------------------
......................................................
--------------------------------------------------------------------------------
54 tests passed, 0 failed, 0 errored in [...] s (total test time [...] s)
```
