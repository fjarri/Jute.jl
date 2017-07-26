using DataStructures
using IterTools


struct Testcase
    order :: Int
    func
    parameters :: Array{Fixture, 1}
    dependencies :: OrderedSet{GlobalFixture}
end


function testcase(func, params...)
    # gensym() helps preserve the order of definition of testcases in a single file
    # A bit hacky, but we need an integer, since "9" > "10".
    order = parse(Int, string(gensym())[3:end])
    params = collect(map(normalize_fixture, params))
    deps = union(map(dependencies, params)..., global_fixtures(params))
    Testcase(order, func, params, deps)
end


parameters(tc::Testcase) = tc.parameters


dependencies(tc::Testcase) = tc.dependencies
