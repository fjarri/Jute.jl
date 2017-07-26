using Jute

f1 = fixture() do produce
    produce(1:3)
end

f2 = local_fixture() do produce
    produce(1)
end

f3 = [1, 2, 3]

for i in 1:100
    eval(quote
        $(Symbol("t", i)) = testcase(f1, f2, f3) do x, y, z
            @test 1 == 1
        end
    end)
end
