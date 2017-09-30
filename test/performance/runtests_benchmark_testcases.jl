using Jute

f1 = @global_fixture for x in 1:3
    @produce x
end

f2 = @local_fixture begin
    @produce 1
end

f3 = [1, 2, 3]

for i in 1:100
    @testcase "t$i" for x in f1, y in f2, z in f3
        @test 1 == 1
    end
end
