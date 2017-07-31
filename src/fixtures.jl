using DataStructures


abstract type Fixture end


is_iterable(val) = applicable(start, val)


is_callable(val) = !isempty(methods(val))


"Constant fixture type"
struct ConstantFixture <: Fixture
    name :: String
    lvals :: Array{LabeledValue, 1}
end


"""
    constant_fixture(vals[, labels])

Create a [`ConstantFixture`](@ref Jute.ConstantFixture) object.
Only called to convert a given value to a fixture internally,
users can just supply iterables directly as testcase or fixture parameters.
"""
function constant_fixture(vals, labels=nothing)

    if !is_iterable(vals)
        error("`vals` must be an iterable")
    end

    if labels === nothing
        labeled_vals = map(labeled_value, vals)
    else
        labeled_vals = map(labeled_value, vals, labels)
    end

    ConstantFixture(gensym("constant"), labeled_vals)
end


Base.start(f::ConstantFixture) = start(f.lvals)
Base.next(f::ConstantFixture, state) = next(f.lvals, state)
Base.done(f::ConstantFixture, state) = done(f.lvals, state)
Base.length(f::ConstantFixture) = length(f.lvals)


"Global fixture type"
struct GlobalFixture <: Fixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{GlobalFixture}
end


function setup(fx::GlobalFixture, args)
    setup(fx.ff, args)
end


"""
    fixture(func, params...; instant_teardown=false)

Create a global fixture (a fixture set up once before all
the testcases that use it and torn down after they finish).

`func` is a function with `length(params) + 1` parameters.
The first parameter takes a function `produce(values[, labels])`
that is used to return the fixture iterable (with an optional iterable of labels).
The rest take the values of the dependent fixtures from `params`.

`params` are either fixtures (constant of global only),
iterables or pairs of two iterables used to parametrize the fixture.

Returns a [`GlobalFixture`](@ref Jute.GlobalFixture) object.
"""
function fixture(producer, params...; name=nothing, instant_teardown=false)
    if name === nothing
        name = gensym("fixture")
    end

    if !is_callable(producer)
        error("Producer must be a callable")
    end

    params = collect(map(normalize_fixture, params))
    # TODO: check that it does not depend on any local fixtures
    deps = union(map(dependencies, params)..., global_fixtures(params))
    ff = fixture_factory(producer; instant_teardown=instant_teardown, returns_iterable=true)
    GlobalFixture(name, ff, params, deps)
end


"Local fixture type"
struct LocalFixture <: Fixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{GlobalFixture}
end


"""
    local_fixture(func, params...)

Create a local fixture (a fixture set up before each testcase
that uses it and torn down afterwards).

`func` is a function with `length(params) + 1` parameters.
The first parameter takes a function `produce(value[, label])`
that is used to return the fixture value (with an optional label).
The rest take the values of the dependent fixtures from `params`.

`params` are either fixtures (of any type), iterables or pairs of two iterables
used to parametrize the fixture.

Returns a [`LocalFixture`](@ref Jute.LocalFixture) object.
"""
function local_fixture(producer, params...; name=nothing)
    if name === nothing
        name = string(gensym("local_fixture"))
    end

    if !is_callable(producer)
        error("Producer must be a callable")
    end

    params = collect(map(normalize_fixture, params))
    deps = union(map(dependencies, params)..., global_fixtures(params))
    ff = fixture_factory(producer; instant_teardown=false, returns_iterable=false)
    LocalFixture(name, ff, params, deps)
end


is_global_fixture(::GlobalFixture) = true
is_global_fixture(::Any) = false


dependencies(::ConstantFixture) = OrderedSet{GlobalFixture}()
dependencies(fx::GlobalFixture) = fx.dependencies
dependencies(fx::LocalFixture) = fx.dependencies


global_fixtures(fxs) = OrderedSet{GlobalFixture}(filter(is_global_fixture, fxs))


normalize_fixture(f::Fixture) = f
normalize_fixture(f::Pair) = constant_fixture(f[1], f[2])
normalize_fixture(f) = constant_fixture(f)


parameters(fixture::LocalFixture) = fixture.parameters
parameters(fixture::GlobalFixture) = fixture.parameters
parameters(::ConstantFixture) = Array{Fixture, 1}()
