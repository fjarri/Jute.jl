using DataStructures


abstract type Fixture end
abstract type AbstractGlobalFixture <: Fixture end


is_iterable(val) = applicable(start, val)


is_callable(val) = !isempty(methods(val))


"Constant fixture type"
struct ConstantFixture <: AbstractGlobalFixture
    name :: String
    lvals :: Array{LabeledValue, 1}
end


"""
    constant_fixture(vals[, labels])

Create a [`ConstantFixture`](@ref) object.
Only called to convert a given value to a fixture internally,
users can just supply iterables directly as testcase or fixture parameters.
"""
function constant_fixture(vals, labels=nothing)

    if !is_iterable(vals)
        error("`vals` must be an iterable")
    end

    c_vals = collect(vals)[:]

    if labels === nothing
        labeled_vals = map(labeled_value, c_vals)
    else
        if !is_iterable(labels)
            error("`labels` must be an iterable")
        end
        c_labels = collect(labels)[:]
        labeled_vals = map(labeled_value, c_vals, c_labels)
    end

    ConstantFixture(String(gensym("constant")), labeled_vals)
end


setup(fx::ConstantFixture) = fx.lvals


"Global fixture type"
struct GlobalFixture <: AbstractGlobalFixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{AbstractGlobalFixture}
end


function setup(fx::GlobalFixture, args)
    setup(fx.ff, args)
end


function global_fixture(producer, params...; name=nothing, instant_teardown=false)
    if name === nothing
        name = String(gensym("fixture"))
    end

    if !is_callable(producer)
        error("Producer must be a callable")
    end

    params = collect(map(normalize_fixture, params))
    # TODO: check that it does not depend on any local fixtures
    deps = union(map(dependencies, params)..., global_fixtures(params))
    ff = fixture_factory(producer; instant_teardown=instant_teardown)
    GlobalFixture(name, ff, params, deps)
end


struct RunOptionsFixture <: AbstractGlobalFixture
end


# Shown as non-covered because `__precompile__()` optimizes out the only call
# to this function in `builtin_fixtures.jl`.
function run_options_fixture()
    RunOptionsFixture()
end


"Local fixture type"
struct LocalFixture <: Fixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{AbstractGlobalFixture}
end


function local_fixture(producer, params...; name=nothing)
    if name === nothing
        name = String(gensym("local_fixture"))
    end

    if !is_callable(producer)
        error("Producer must be a callable")
    end

    params = collect(map(normalize_fixture, params))
    deps = union(map(dependencies, params)..., global_fixtures(params))
    ff = fixture_factory(producer; instant_teardown=false)
    LocalFixture(name, ff, params, deps)
end


is_global_fixture(::GlobalFixture) = true
is_global_fixture(::Any) = false


dependencies(::Fixture) = OrderedSet{AbstractGlobalFixture}()
dependencies(fx::RunOptionsFixture) = OrderedSet{AbstractGlobalFixture}([fx])
dependencies(fx::GlobalFixture) = fx.dependencies
dependencies(fx::LocalFixture) = fx.dependencies


global_fixtures(fxs) = OrderedSet{AbstractGlobalFixture}(filter(is_global_fixture, fxs))


normalize_fixture(f::Fixture) = f
normalize_fixture(f::Pair) = constant_fixture(f[1], f[2])
normalize_fixture(f) = constant_fixture(f)


parameters(fixture::LocalFixture) = fixture.parameters
parameters(fixture::GlobalFixture) = fixture.parameters
