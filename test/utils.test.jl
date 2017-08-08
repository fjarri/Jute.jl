module Utils

using Jute


pprint_time_test = testcase() do
    # normal operation for large times
    @test pprint_time(32 * 24 * 3600 + 12 * 3600 + 6 * 60 + 7) == "32d 12h 6m 7s"
    @test pprint_time(12 * 3600 + 6 * 60 + 7) == "12h 6m 7s"
    @test pprint_time(6 * 60 + 7) == "6m 7s"
    @test pprint_time(7) == "7s"

    # some units are skipped
    @test pprint_time(32 * 24 * 3600 + 6 * 60) == "32d 6m"

    # exact time below 1 minute
    @test pprint_time(55.345, meaningful_digits=3) == "55.3s"
    @test pprint_time(55, meaningful_digits=3) == "55.0s"

    # exact time above 1 minute - falls back to large times
    @test pprint_time(65, meaningful_digits=3) == "1m 5s"

    # normal operation for small times
    @test pprint_time(55.345 * 1e-3, meaningful_digits=3) == "55.3ms"
    @test pprint_time(55.345 * 1e-6, meaningful_digits=3) == "55.3us"
    @test pprint_time(55.345 * 1e-9, meaningful_digits=3) == "55.3ns"
    @test pprint_time(55.345 * 1e-12, meaningful_digits=3) == "0.0553ns"

    # small times with meaningful_digts==0 (default)
    @test pprint_time(55.345 * 1e-3) == "55ms"
end


rowmajor_product_test = testcase() do
    @test collect(rowmajor_product()) == [()]
    @test collect(rowmajor_product(1:2)) == [(1,), (2,)]
    @test collect(rowmajor_product(1:2, [])) == []
    @test collect(rowmajor_product(1:2, 3:4)) == [(1, 3), (1, 4), (2, 3), (2, 4)]
end


end
