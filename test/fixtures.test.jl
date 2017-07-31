module Fixtures

using Jute


constant_fixture1 = 1:2
constant_fixture2 = ["a", "b"]

global_fixture1_setup = false
global_fixture1_torndown = false
global_fixture1_vals = [10, 20]
global_fixture1 = fixture(; name="global_fixture1") do produce
    global global_fixture1_setup
    @assert !global_fixture1_setup
    global_fixture1_setup = true
    produce(global_fixture1_vals)
    global global_fixture1_torndown
    global_fixture1_setup = false
    global_fixture1_torndown = true
end

global_fixture2_setup = false
global_fixture2_torndown = false
global_fixture2_vals = ["x", "y"]
global_fixture2 = fixture(; name="global_fixture2") do produce
    global global_fixture2_setup
    @assert !global_fixture2_setup
    global_fixture2_setup = true
    produce(global_fixture2_vals)
    global global_fixture2_torndown
    global_fixture2_setup = false
    global_fixture2_torndown = true
end


# Constant + constant

c12_results = []
c12 = testcase(constant_fixture1, constant_fixture2) do x1, x2
    push!(c12_results, (x1, x2))
end

check_c12 = testcase() do
    @test c12_results == collect(rowmajor_product(constant_fixture1, constant_fixture2))
end


# Only using global fixture 1

g1_results = []

check_g1_setup = testcase() do
    @test !global_fixture1_setup
    @test !global_fixture1_torndown
end

g1 = testcase(global_fixture1) do x1
    @test global_fixture1_setup
    push!(g1_results, x1)
end

check_g1 = testcase() do
    @test g1_results == collect(global_fixture1_vals)
end

check_g1_still_there = testcase() do
    @test global_fixture1_setup
    @test !global_fixture1_torndown
end


# Using global fixtures 1 and 2

g12_results = []

check_g2_setup = testcase() do
    @test !global_fixture2_setup
    @test !global_fixture2_torndown
end

g12 = testcase(global_fixture1, global_fixture2) do x1, x2
    @test global_fixture1_setup
    @test global_fixture2_setup
    push!(g12_results, (x1, x2))
end

check_g1_destroyed = testcase() do
    @test !global_fixture1_setup
    @test global_fixture1_torndown
end

check_g2_still_there = testcase() do
    @test global_fixture2_setup
    @test !global_fixture2_torndown
end

check_g12 = testcase() do
    @test g12_results == collect(rowmajor_product(global_fixture1_vals, global_fixture2_vals))
end


# Using only global fixture 2
g2_results = []

g2 = testcase(global_fixture2) do x2
    @test global_fixture2_setup
    push!(g2_results, x2)
end

check_g2 = testcase() do
    @test g2_results == collect(global_fixture2_vals)
end

check_g2_destroyed = testcase() do
    @test !global_fixture2_setup
    @test global_fixture2_torndown
end


# Check dependent global fixtures

gfs_state = Dict(key => 0 for key in ["a", "b", "c", "d"])

as = ["a1", "a2"]
bs = ["b1", "b2"]
cs = ["c1", "c2"]
combine_ab(a, b) = a * b
combine_ac(a, c) = a * c
combine_bc(b, c) = b * "+" * c

gf_as = fixture(; name="gf_as") do produce
    @assert gfs_state["a"] == 0
    gfs_state["a"] = 1
    produce(as)
    @assert gfs_state["a"] == 1
    gfs_state["a"] = 0
end

gf_bs = fixture(gf_as; name="gf_bs") do produce, a
    total_values = 2
    @assert gfs_state["b"] >= 0 && gfs_state["b"] <= total_values - 1
    gfs_state["b"] += 1
    produce([combine_ab(a, b) for b in bs])
    @assert gfs_state["b"] >= 1 && gfs_state["b"] <= total_values
    gfs_state["b"] -= 1
end

gf_cs = fixture(gf_as; name="gf_cs") do produce, a
    total_values = 2
    @assert gfs_state["c"] >= 0 && gfs_state["c"] <= total_values - 1
    gfs_state["c"] += 1
    produce([combine_ac(a, c) for c in cs])
    @assert gfs_state["c"] >= 1 && gfs_state["c"] <= total_values
    gfs_state["c"] -= 1
end

gf_ds = fixture(gf_bs, gf_cs; name="gf_ds") do produce, b, c
    total_values = 16
    @assert gfs_state["d"] >= 0 && gfs_state["d"] <= total_values - 1
    gfs_state["d"] += 1
    produce([combine_bc(b, c)])
    @assert gfs_state["d"] >= 1 && gfs_state["d"] <= total_values
    gfs_state["d"] -= 1
end

combination_results = Array{Tuple{String, String}, 1}()

combination = testcase(gf_ds, gf_bs) do d, b
    push!(combination_results, (d, b))
end

check_combination = testcase() do
    cbs = [combine_ab(a, b) for (a, b) in rowmajor_product(as, bs)]
    ccs = [combine_ac(a, c) for (a, c) in rowmajor_product(as, cs)]
    cds = [combine_bc(b, c) for (b, c) in rowmajor_product(cbs, ccs)]
    @test combination_results == collect(rowmajor_product(cds, cbs))
end

check_all_cleaned = testcase() do
    @test all([gfs_state[key] == 0 for key in keys(gfs_state)])
end


# Check local fixtures


lf_sequence = []

lf_nodeps = local_fixture(; name="lf_nodeps") do produce
    push!(lf_sequence, "setup")
    produce(1)
    push!(lf_sequence, "teardown")
end

lf_nodeps_test = testcase(lf_nodeps) do x
    push!(lf_sequence, "testcase $x")
end

lf_nodeps_check = testcase() do
    @test lf_sequence == ["setup", "testcase 1", "teardown"]
end


lf_sequence2 = []

gf_for_lf = fixture() do produce
    push!(lf_sequence2, "gf setup")
    produce([1, 2])
    push!(lf_sequence2, "gf teardown")
end

lf_nodeps = local_fixture() do produce
    push!(lf_sequence2, "lf_nodeps setup")
    produce("a")
    push!(lf_sequence2, "lf_nodeps teardown")
end

lf_deps = local_fixture(lf_nodeps, 3:4, gf_for_lf; name="lf_deps") do produce, x, y, z
    push!(lf_sequence2, "lf_deps $x $y $z setup")
    produce((x, y, z))
    push!(lf_sequence2, "lf_deps $x $y $z teardown")
end

lf_deps_test = testcase(lf_deps, lf_nodeps) do x, y
    push!(lf_sequence2, "testcase $x $y")
end

lf_deps_check = testcase() do
    lf_sequence_ref = []
    push!(lf_sequence_ref, "gf setup")
    for i in 3:4
        for gf in 1:2
            push!(lf_sequence_ref, "lf_nodeps setup")
            push!(lf_sequence_ref, "lf_deps a $i $gf setup")
            push!(lf_sequence_ref, "lf_nodeps setup")
            push!(lf_sequence_ref, "testcase $(("a", i, gf)) a")
            push!(lf_sequence_ref, "lf_nodeps teardown")
            push!(lf_sequence_ref, "lf_deps a $i $gf teardown")
            push!(lf_sequence_ref, "lf_nodeps teardown")
        end
    end
    push!(lf_sequence_ref, "gf teardown")

    @test lf_sequence2 == lf_sequence_ref
end


end
