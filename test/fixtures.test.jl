module Fixtures

using Jute


tc_with_run_options = testcase(run_options) do ro
    @test haskey(ro, :verbosity)
end

fx_with_run_options = fixture(run_options) do produce, ro
    produce([ro[:verbosity]])
end

tc_with_fx_with_run_options = testcase(fx_with_run_options) do v
    @test isa(v, Int)
end


constant_fx_non_1D_iterable = testcase() do
    fx = Jute.constant_fixture(1)
    @test Jute.setup(fx) == [Jute.labeled_value(1)]

    fx = Jute.constant_fixture([1 2; 3 4])
    @test Jute.setup(fx) == map(Jute.labeled_value, [1, 3, 2, 4])

    fx = Jute.constant_fixture([1 2; 3 4], ["one" "two"; "three" "four"])
    @test Jute.setup(fx) == map(Jute.labeled_value, [1, 3, 2, 4], ["one", "three", "two", "four"])
end


constant_fx_labels = testcase() do
    fx = Jute.constant_fixture([1], ["one"])
    @test Jute.setup(fx) == [Jute.labeled_value(1, "one")]
end


constant_fx_checks_for_iterable = testcase() do
    @test_throws ErrorException Jute.constant_fixture(:a)
    @test_throws ErrorException Jute.constant_fixture([1], :a)
end


global_fx_checks_for_callable = testcase() do
    @test_throws ErrorException fixture(1)
end


local_fx_checks_for_callable = testcase() do
    @test_throws ErrorException local_fixture(1)
end


constant_fx_from_pair = testcase() do
    fx = fixture([1, 2] => ["one", "two"]) do produce, x
        produce(x)
    end
    constant_fx = Jute.parameters(fx)[1]
    @test Jute.setup(constant_fx) == map(Jute.labeled_value, [1, 2], ["one", "two"])
end


end
