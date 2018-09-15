using Base.Iterators: product

"""
    pprint_time(s; meaningful_digits=0)

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


# A simple lazy map function for use with rowmajor_product()

struct LazyMap
    func
    iter
end


lazymap(func, iter) = LazyMap(func, iter)


function Base.iterate(lm::LazyMap, state=nothing)
    if state === nothing
        pair = iterate(lm.iter)
    else
        pair = iterate(lm.iter, state)
    end

    if pair === nothing
        nothing
    else
        val, state = pair
        lm.func(val), state
    end
end


Base.length(lm::LazyMap) = length(lm.iter)


rowmajor_product(xss...) = lazymap(reverse, product(reverse(xss)...))


"""
    with_output_capture(func, pass_through=false)

Execute the callable `func` and capture its output (both `STDOUT` and `STDERR`) in a string.
Returns a tuple of the `func`'s return value and its output.
If `pass_through` is `true`, does not capture anything
and returns an empty string instead of the output.
"""
function with_output_capture(func, pass_through::Bool=false)

    if pass_through
        return func(), ""
    end

    stdout_old = stdout
    stderr_old = stderr

    rd, wr = redirect_stdout()
    redirect_stderr(wr)
    reader = @async read(rd, String)

    ret = nothing
    output = ""
    try
        ret = func()
    finally
        redirect_stdout(stdout_old)
        redirect_stderr(stderr_old)
        close(wr)
        output = fetch(reader)
        close(rd)
    end

    ret, output
end
