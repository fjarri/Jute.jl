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


# Row-major analogue of IterTools.product()
# Piggy-backing with reverse() makes it several times slower.
# FIXME: Review this after some response is given on
# https://github.com/JuliaCollections/IterTools.jl/issues/2

struct RowMajorProduct{T<:Tuple}
    xss::T
end


Base.IteratorSize(::Type{T}) where T<:RowMajorProduct = Base.SizeUnknown()


Base.eltype(::Type{RowMajorProduct{T}}) where T = Tuple{map(eltype, T.parameters)...}


Base.length(p::RowMajorProduct) = mapreduce(length, *, 1, p.xss)


"""
    rowmajor_product(xss...)

Iterate over all combinations in the cartesian product of the inputs.
Similar to `IterTools.product()`, but iterates in row-major order
(that is, the first iterator is iterated the slowest).
"""
rowmajor_product(xss...) = RowMajorProduct(xss)


function Base.start(it::RowMajorProduct)
    n = length(it.xss)
    js = Any[start(xs) for xs in it.xss]
    for i = 1:n
        if done(it.xss[i], js[i])
            return js, nothing
        end
    end
    vs = Vector{Any}(undef, n)
    for i = 1:n
        vs[i], js[i] = next(it.xss[i], js[i])
    end
    return js, vs
end


function Base.next(it::RowMajorProduct, state)
    js = copy(state[1])
    vs = copy(state[2])
    ans = tuple(vs...)

    n = length(it.xss)
    for i in n:-1:1
        if !done(it.xss[i], js[i])
            vs[i], js[i] = next(it.xss[i], js[i])
            return ans, (js, vs)
        end

        js[i] = start(it.xss[i])
        vs[i], js[i] = next(it.xss[i], js[i])
    end
    ans, (js, nothing)
end


Base.done(::RowMajorProduct, state) = state[2] === nothing


function read_stream(s)
    if Base.thisminor(VERSION) <= v"0.6"
        readstring(s)
    else
        read(s, String)
    end
end


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
    reader = @async read_stream(rd)

    ret = nothing
    output = ""
    try
        ret = func()
    finally
        redirect_stdout(stdout_old)
        redirect_stderr(stderr_old)
        close(wr)
        output = compat_fetch(reader)
        close(rd)
    end

    ret, output
end


function compat_fetch(task)
    if Base.thisminor(VERSION) <= v"0.6"
        wait(task)
    else
        fetch(task)
    end
end
