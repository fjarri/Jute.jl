using .TestUtils

@testgroup "runtests" begin


constant_fixture1 = 1:2
constant_fixture2 = ["a", "b"]

global_fixture1_setup = []
global_fixture1_torndown = []
global_fixture1_vals = [10, 20]
global_fixture1 = @global_fixture for val in global_fixture1_vals
    @assert !(val in global_fixture1_setup)
    push!(global_fixture1_setup, val)
    @produce val
    push!(global_fixture1_torndown, val)
end

global_fixture2_setup = []
global_fixture2_torndown = []
global_fixture2_vals = ["x", "y"]
global_fixture2 = @global_fixture for val in global_fixture2_vals
    @assert !(val in global_fixture2_setup)
    push!(global_fixture2_setup, val)
    @produce val
    push!(global_fixture2_torndown, val)
end


# Constant + constant

c12_results = []
@testcase "c12" for x1 in constant_fixture1, x2 in constant_fixture2
    push!(c12_results, (x1, x2))
end

@testcase "check c12" begin
    @test c12_results == collect(Jute.rowmajor_product(constant_fixture1, constant_fixture2))
end


# Only using global fixture 1

g1_results = []

@testcase "check g1 setup" begin
    @test global_fixture1_setup == []
    @test global_fixture1_torndown == []
end

@testcase "g1" for x1 in global_fixture1
    @test global_fixture1_setup == global_fixture1_vals
    push!(g1_results, x1)
end

@testcase "check g1" begin
    @test g1_results == collect(global_fixture1_vals)
end

@testcase "check g1 is still there" begin
    @test global_fixture1_torndown == []
end


# Using global fixtures 1 and 2

g12_results = []

@testcase "check g2 setup" begin
    @test global_fixture2_setup == []
    @test global_fixture2_torndown == []
end

@testcase "g12" for x1 in global_fixture1, x2 in global_fixture2
    @test global_fixture1_setup == global_fixture1_vals
    @test global_fixture2_setup == global_fixture2_vals
    push!(g12_results, (x1, x2))
end

@testcase "check g1 destroyed" begin
    @test global_fixture1_torndown == global_fixture1_vals
end

@testcase "check g2 is still there" begin
    @test global_fixture2_torndown == []
end

@testcase "check g12" begin
    @test g12_results == collect(Jute.rowmajor_product(global_fixture1_vals, global_fixture2_vals))
end


# Using only global fixture 2
g2_results = []

@testcase "g2" for x2 in global_fixture2
    @test global_fixture2_setup == global_fixture2_vals
    push!(g2_results, x2)
end

@testcase "check g2" begin
    @test g2_results == collect(global_fixture2_vals)
end

@testcase "check g2 is destroyed" begin
    @test global_fixture2_torndown == global_fixture2_vals
end


# Check dependent global fixtures

gfs_state = Dict(key => 0 for key in ["a", "b", "c", "d"])

as = ["a1", "a2"]
bs = ["b1", "b2"]
cs = ["c1", "c2"]
combine_ab(a, b) = a * b
combine_ac(a, c) = a * c
combine_bc(b, c) = b * "+" * c

gf_as = @global_fixture for a in as
    gfs_state["a"] += 1
    @produce a
    gfs_state["a"] -= 1
end

gf_bs = @global_fixture for a in gf_as, b in bs
    total_values = 4
    @assert gfs_state["b"] >= 0 && gfs_state["b"] <= total_values - 1
    gfs_state["b"] += 1
    @produce combine_ab(a, b)
    @assert gfs_state["b"] >= 1 && gfs_state["b"] <= total_values
    gfs_state["b"] -= 1
end

gf_cs = @global_fixture for a in gf_as, c in cs
    total_values = 4
    @assert gfs_state["c"] >= 0 && gfs_state["c"] <= total_values - 1
    gfs_state["c"] += 1
    @produce combine_ac(a, c)
    @assert gfs_state["c"] >= 1 && gfs_state["c"] <= total_values
    gfs_state["c"] -= 1
end

gf_ds = @global_fixture for b in gf_bs, c in gf_cs
    total_values = 16
    @assert gfs_state["d"] >= 0 && gfs_state["d"] <= total_values - 1
    gfs_state["d"] += 1
    @produce combine_bc(b, c)
    @assert gfs_state["d"] >= 1 && gfs_state["d"] <= total_values
    gfs_state["d"] -= 1
end

combination_results = Array{Tuple{String, String}, 1}()

@testcase "combination" for d in gf_ds, b in gf_bs
    push!(combination_results, (d, b))
end

@testcase "check combination" begin
    cbs = [combine_ab(a, b) for (a, b) in Jute.rowmajor_product(as, bs)]
    ccs = [combine_ac(a, c) for (a, c) in Jute.rowmajor_product(as, cs)]
    cds = [combine_bc(b, c) for (b, c) in Jute.rowmajor_product(cbs, ccs)]
    @test combination_results == collect(Jute.rowmajor_product(cds, cbs))
end

@testcase "check all cleaned" begin
    @test all([gfs_state[key] == 0 for key in keys(gfs_state)])
end


# Check local fixtures


lf_sequence = []

lf_nodeps = @local_fixture begin
    push!(lf_sequence, "setup")
    @produce 1
    push!(lf_sequence, "teardown")
end

@testcase "lf nodeps test" for x in lf_nodeps
    push!(lf_sequence, "testcase $x")
end

@testcase "lf nodeps check" begin
    @test lf_sequence == ["setup", "testcase 1", "teardown"]
end


lf_sequence2 = []

gf_for_lf = @global_fixture for val in [1, 2]
    push!(lf_sequence2, "gf setup $val")
    @produce val
    push!(lf_sequence2, "gf teardown $val")
end

lf_nodeps = @local_fixture begin
    push!(lf_sequence2, "lf_nodeps setup")
    @produce "a"
    push!(lf_sequence2, "lf_nodeps teardown")
end

lf_deps = @local_fixture for x in lf_nodeps, y in 3:4, z in gf_for_lf
    push!(lf_sequence2, "lf_deps $x $y $z setup")
    @produce (x, y, z)
    push!(lf_sequence2, "lf_deps $x $y $z teardown")
end

@testcase "lf deps test" for x in lf_deps, y in lf_nodeps
    push!(lf_sequence2, "testcase $x $y")
end

@testcase "lf deps check" begin
    lf_sequence_ref = []
    push!(lf_sequence_ref, "gf setup 1")
    push!(lf_sequence_ref, "gf setup 2")
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
    push!(lf_sequence_ref, "gf teardown 1")
    push!(lf_sequence_ref, "gf teardown 2")

    @test lf_sequence2 == lf_sequence_ref
end


# Checks that the max_fails option works.
# Also checks that all remaining teardowns are called
# if runtests exists prematurely because max_fails was reached.
@testcase "test max fails" begin

    teardown_called = false
    tc1_executed = false
    tc3_executed = false

    gfx = @global_fixture begin
        @produce 1
        teardown_called = true
    end

    tcs = Jute.collect_testobjs() do
        @testcase "tc1" for x in gfx
            tc1_executed = true
        end

        @testcase "tc2" begin
            @test 1 == 2
        end

        @testcase "tc3" for x in gfx
            tc3_executed = true
        end
    end

    exitcode, output = nested_run_with_output(tcs, Dict(:max_fails => 1))
    @test tc1_executed
    @test teardown_called
    @test !tc3_executed
    @test exitcode == 1
end


# Checks that the instant teardown global fixture
# is actually torn down right after instantiation.
@testcase "test instant teardown" begin
    teardown_called = false
    tc1_executed = false

    gfx = @global_fixture instant_teardown=true begin
        @produce 1
        teardown_called = true
    end

    tcs = Jute.collect_testobjs() do
        @testcase "tc1" for x in gfx
            @test teardown_called
            tc1_executed = true
        end
    end

    exitcode = nested_run(tcs)
    @test teardown_called
    @test tc1_executed
    @test exitcode == 0
end


# Checks that the case of no testcases to run is handled appropriately.
@testcase "test no testcases" begin
    exitcode = nested_run([])
    @test exitcode == 0
end


end
