using DataStructures


abstract type Fixture end
abstract type AbstractGlobalFixture <: Fixture end


function try_collect(val)
    try
        return collect(val)[:]
    catch
        return nothing
    end
end


is_callable(val) = !isempty(methods(val))


"Constant fixture type"
struct ConstantFixture <: AbstractGlobalFixture
    name :: String
    lvals :: Array{LabeledValue, 1}

    """
        ConstantFixture(vals[, labels])

    Create a [`ConstantFixture`](@ref) object.
    Only called to convert a given value to a fixture internally,
    users can just supply iterables directly as testcase or fixture parameters.
    """
    function ConstantFixture(vals, labels=nothing)

        c_vals = try_collect(vals)
        if c_vals === nothing
            error("`vals` must be an iterable")
        end

        if labels === nothing
            labeled_vals = map(LabeledValue, c_vals)
        else
            c_labels = try_collect(labels)
            if c_labels === nothing
                error("`labels` must be an iterable")
            end

            labeled_vals = map(LabeledValue, c_vals, c_labels)
        end

        new(String(gensym("constant")), labeled_vals)
    end
end


setup(fx::ConstantFixture) = fx.lvals


"Global fixture type"
struct GlobalFixture <: AbstractGlobalFixture
    name :: String
    ff :: FixtureFactory
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{AbstractGlobalFixture}

    function GlobalFixture(producer, params...; name=nothing, instant_teardown=false)
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
        new(name, ff, params, deps)
    end
end


function setup(fx::GlobalFixture, args)
    setup(fx.ff, args)
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

    function LocalFixture(producer, params...; name=nothing)
        if name === nothing
            name = String(gensym("local_fixture"))
        end

        if !is_callable(producer)
            error("Producer must be a callable")
        end

        params = collect(map(normalize_fixture, params))
        deps = union(map(dependencies, params)..., global_fixtures(params))
        ff = fixture_factory(producer; instant_teardown=false)
        new(name, ff, params, deps)
    end

end


is_global_fixture(::GlobalFixture) = true
is_global_fixture(::Any) = false


dependencies(::Fixture) = OrderedSet{AbstractGlobalFixture}()
dependencies(fx::RunOptionsFixture) = OrderedSet{AbstractGlobalFixture}([fx])
dependencies(fx::GlobalFixture) = fx.dependencies
dependencies(fx::LocalFixture) = fx.dependencies


global_fixtures(fxs) = OrderedSet{AbstractGlobalFixture}(filter(is_global_fixture, fxs))


normalize_fixture(f::Fixture) = f
normalize_fixture(f::Pair) = ConstantFixture(f[1], f[2])
normalize_fixture(f) = ConstantFixture(f)


parameters(fixture::LocalFixture) = fixture.parameters
parameters(fixture::GlobalFixture) = fixture.parameters
