# Jute, a Py.Test-inspired testing framework

Master branch: [![Travis build status](https://travis-ci.org/fjarri/Jute.jl.svg?branch=master)](https://travis-ci.org/fjarri/Jute.jl) [![Appveyor build status](https://ci.appveyor.com/api/projects/status/3k77mqb4549cwcjg?svg=true)](https://ci.appveyor.com/project/fjarri/jute-jl) [![Coverage Status](https://codecov.io/gh/fjarri/Jute.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/fjarri/Jute.jl)

Package status: [![Jute](http://pkg.julialang.org/badges/Jute_0.6.svg)](http://pkg.julialang.org/detail/Jute)

**This project is in the alpha stage.**
Use at your own risk.

As opposed to [`Test`](http://docs.julialang.org/en/latest/stdlib/Test/) which executes the tests as it compiles the source files, `Jute` collects the testcases first.
This makes it possible to implement many advanced features, such as testcase filtering, testcase parametrization, fixtures with different setup/teardown strategies, and others.
As a bonus, you do not need to manually include the files with tests, since they are picked up automatically.
On the other hand, this approach leads to more execution time overhead, both per-test and global.

A compromise between the two approaches is [`PyTest.jl`](https://github.com/pdobacz/PyTest.jl) which extends `Test` to add more advanced fixture functionality.
