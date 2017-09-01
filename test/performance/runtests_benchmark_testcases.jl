using Jute

f1 = fixture(1:3) do produce, x
    produce(x)
end

f2 = local_fixture() do produce
    produce(1)
end

f3 = [1, 2, 3]

for i in 1:100
    eval(quote
        @testcase $("t$i") for x in f1, y in f2, z in f3
            @test 1 == 1
        end
    end)
end
