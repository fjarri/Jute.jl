"""
Returns a string that represents a given time (in seconds)
as a value scaled to the appropriate unit (minutes, hours, milliseconds etc)
and rounded to a given number of meaningful digits (if it is smaller than a minute).
If the latter is `0`, the result is rounded to an integer at all times.
"""
function pprint_time(s::Number; meaningful_digits::Int=0)
    if s >= 60
        pprint_large_time(s)
    else
        pprint_small_time(s, meaningful_digits)
    end
end


function pprint_large_time(s::Number)
    int_s = convert(Int, round(s))

    limits = [
        (24 * 3600, "d"),
        (3600, "h"),
        (60, "m"),
        (1, "s"),
    ]

    res = []

    for (limit, unit) in limits
        if int_s >= limit
            num_units = convert(Int, floor(int_s / limit))
            int_s -= num_units * limit
            push!(res, "$num_units$unit")
        end
    end

    join(res, " ")
end


"Round a given number to a certain number of meaningful digits."
function round_to_meaningful(s::Number, meaningful_digits::Int)
    multiplier = 10.0^(meaningful_digits - 1 - convert(Integer, floor(log10(s))))
    round(s * multiplier) / multiplier
end


function build_str(s, unit, meaningful_digits)
    if meaningful_digits == 0
        rounded_s = convert(Int, round(s))
    else
        rounded_s = round_to_meaningful(s, meaningful_digits)
    end
    "$rounded_s$unit"
end


function pprint_small_time(s::Number, meaningful_digits::Int)
    limits = [
        (1.0, "s"),
        (1e-3, "ms"),
        (1e-6, "us"),
        (1e-9, "ns")
    ]

    for (limit, unit) in limits[1:end-1]
        if s >= limit
            return build_str(s / limit, unit, meaningful_digits)
        end
    end

    limit, unit = limits[end]
    build_str(s / limit, unit, meaningful_digits)
end
