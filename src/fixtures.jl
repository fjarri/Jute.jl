using DataStructures

abstract type Fixture end


make_id(val) = string(val)


is_iterable(val) = applicable(start, val)


is_callable(val) = !isempty(methods(val))


struct ConstantFixture <: Fixture
    name
    val_id_pairs
end


function constant_fixture(vals, ids=nothing)

    if !is_iterable(vals)
        error("`vals` must be an iterable")
    end

    if ids === nothing
        ids = map(make_id, vals)
    end

    ConstantFixture(gensym("constant"), collect(zip(vals, ids)))
end


Base.start(f::ConstantFixture) = start(f.val_id_pairs)
Base.next(f::ConstantFixture, state) = next(f.val_id_pairs, state)
Base.done(f::ConstantFixture, state) = done(f.val_id_pairs, state)
Base.length(f::ConstantFixture) = length(f.val_id_pairs)

struct GlobalFixture <: Fixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{Fixture}
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
    deps = union(
        map(dependencies, parameters)...,
        OrderedSet{Fixture}([p for p in parameters if typeof(p) == GlobalFixture]))
    ff = fixture_factory(producer; delayed_teardown=delayed_teardown, returns_iterable=true)
    GlobalFixture(name, ff, parameters, deps)
end


struct LocalFixture <: Fixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{Fixture}
end


function local_fixture(producer, parameters...; name=nothing)
    if name === nothing
        name = gensym("local_fixture")
    end

    if !is_callable(producer)
        error("Producer must be a callable")
    end

    parameters = collect(map(normalize_fixture, parameters))
    deps = union(
        map(dependencies, parameters)...,
        OrderedSet{Fixture}([p for p in parameters if typeof(p) == GlobalFixture]))
    ff = fixture_factory(producer; delayed_teardown=true, returns_iterable=false)
    LocalFixture(name, ff, parameters, deps)
end



dependencies(fx::ConstantFixture) = OrderedSet{Fixture}()
dependencies(fx::GlobalFixture) = fx.dependencies
dependencies(fx::LocalFixture) = fx.dependencies


normalize_fixture(f::Fixture) = f
normalize_fixture(f::Pair) = constant_fixture(f[1], f[2])
normalize_fixture(f) = constant_fixture(f)


parameters(fixture::LocalFixture) = fixture.parameters
parameters(fixture::GlobalFixture) = fixture.parameters
parameters(fixture::ConstantFixture) = Array{Fixture, 1}()
