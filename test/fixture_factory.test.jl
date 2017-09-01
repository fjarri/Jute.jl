struct MyType
    x :: Int
end

Base.show(io::IO, val::MyType) = print(io, "MyType($(val.x))")


@testgroup "fixture_factory" begin


# Return one value, create label automatically
@testcase "return a value" begin
    ff = Jute.fixture_factory(; instant_teardown=true) do produce, v
        produce(v)
    end
    val = MyType(1)
    lval, rff = Jute.setup(ff, [val])
    @test Jute.unwrap_value(lval) == val
    @test Jute.unwrap_label(lval) == string(val)
end


# Return one value with a custom label
@testcase "return a value and a label" begin
    ff = Jute.fixture_factory(; instant_teardown=true) do produce, v
        produce(v, "one")
    end
    val = MyType(1)
    lval, rff = Jute.setup(ff, [val])
    @test Jute.unwrap_value(lval) == val
    @test Jute.unwrap_label(lval) == "one"
end


# Check that if delayed_teardown=true, teardown is not called right away
@testcase "delayed teardown" begin
    teardown_started = false
    ff = Jute.fixture_factory() do produce, v
        produce(v)
        teardown_started = true
    end
    lval, rff = Jute.setup(ff, [MyType(1)])

    @test !teardown_started
    Jute.teardown(rff)
    @test teardown_started
end


# Check that if delayed_teardown=true, and the teardown part takes a long time,
# teardown() waits for it to finish.
@testcase "long delayed teardown" begin
    teardown_ended = false
    ff = Jute.fixture_factory() do produce, v
        produce(v)
        sleep(2)
        teardown_ended = true
    end
    lval, rff = Jute.setup(ff, [MyType(1)])

    @test !teardown_ended
    Jute.teardown(rff)
    @test teardown_ended
end


end
