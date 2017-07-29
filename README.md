# Jute, a Py.Test-inspired testing framework

[![Build Status](https://travis-ci.org/fjarri/Jute.jl.svg?branch=master)](https://travis-ci.org/fjarri/Jute.jl) [![Coverage Status](https://coveralls.io/repos/github/fjarri/Jute.jl/badge.svg?branch=master)](https://coveralls.io/github/fjarri/Jute.jl?branch=master)

**This project is in the alpha stage.**
Use at your own risk.

As opposed to [`Base.Test`](http://docs.julialang.org/en/latest/stdlib/test/) which executes the tests as it compiles the source files, `Jute` collects the testcases first.
This makes it possible to implement many advanced features, such as testcase filtering, testcase parametrization, fixtures with different setup/teardown strategies, and others.
As a bonus, you do not need to manually include the files with tests, since they are picked up automatically.
On the other hand, this approach leads to more execution time overhead, both per-test and global.

A compromise between the two approaches is [`PyTest.jl`](https://github.com/pdobacz/PyTest.jl) which extends `Base.Test` to add more advanced fixture functionality.
