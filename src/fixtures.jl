using DataStructures

abstract type Fixture end


is_iterable(val) = applicable(start, val)


is_callable(val) = !isempty(methods(val))


struct ConstantFixture <: Fixture
    name :: String
    lvals :: Array{LabeledValue, 1}
end


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

struct GlobalFixture <: Fixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{GlobalFixture}
end


function setup(fx::GlobalFixture, args)
    setup(fx.ff, args)
end


delayed_teardown(rff::RunningFixtureFactory) = rff.delayed_teardown


# Global fixture
function fixture(producer, parameters...; name=nothing, delayed_teardown=false)
    if name === nothing
        name = gensym("fixture")
    end

    if !is_callable(producer)
        error("Producer must be a callable")
    end

    parameters = collect(map(normalize_fixture, parameters))
    # TODO: check that it does not depend on any local fixtures
    deps = union(map(dependencies, parameters)..., global_fixtures(parameters))
    ff = fixture_factory(producer; delayed_teardown=delayed_teardown, returns_iterable=true)
    GlobalFixture(name, ff, parameters, deps)
end


struct LocalFixture <: Fixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{GlobalFixture}
end


function local_fixture(producer, parameters...; name=nothing)
    if name === nothing
        name = gensym("local_fixture")
    end

    if !is_callable(producer)
        error("Producer must be a callable")
    end

    parameters = collect(map(normalize_fixture, parameters))
    deps = union(map(dependencies, parameters)..., global_fixtures(parameters))
    ff = fixture_factory(producer; delayed_teardown=true, returns_iterable=false)
    LocalFixture(name, ff, parameters, deps)
end


is_global_fixture(fx::GlobalFixture) = true
is_global_fixture(fx) = false


dependencies(fx::ConstantFixture) = OrderedSet{GlobalFixture}()
dependencies(fx::GlobalFixture) = fx.dependencies
dependencies(fx::LocalFixture) = fx.dependencies


global_fixtures(fxs) = OrderedSet{GlobalFixture}(filter(is_global_fixture, fxs))


normalize_fixture(f::Fixture) = f
normalize_fixture(f::Pair) = constant_fixture(f[1], f[2])
normalize_fixture(f) = constant_fixture(f)


parameters(fixture::LocalFixture) = fixture.parameters
parameters(fixture::GlobalFixture) = fixture.parameters
parameters(fixture::ConstantFixture) = Array{Fixture, 1}()
