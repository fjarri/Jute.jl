#!/usr/bin/env sh
set -e
rm -rf htmlcov
mkdir htmlcov
julia --project=../../Jute  --inline=no --code-coverage=user runtests.jl "$@"
# Not using direct output to .info because it adds standard library files coverage
julia coverage.jl
# genhtml is a part of `lcov` utility package
genhtml htmlcov/coverage.info -o htmlcov
rm ../src/*.cov
rm *.cov
