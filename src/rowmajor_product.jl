# Row-major analogue of IterTools.product()
# Piggy-backing with reverse() makes it several times slower.
# FIXME: Review this after some response is given on
# https://github.com/JuliaCollections/IterTools.jl/issues/2

struct RowMajorProduct{T<:Tuple}
    xss::T
end


Base.iteratorsize{T<:RowMajorProduct}(::Type{T}) = Base.SizeUnknown()


Base.eltype{T}(::Type{RowMajorProduct{T}}) = Tuple{map(eltype, T.parameters)...}


Base.length(p::RowMajorProduct) = mapreduce(length, *, 1, p.xss)


rowmajor_product(xss...) = RowMajorProduct(xss)


function Base.start(it::RowMajorProduct)
    n = length(it.xss)
    js = Any[start(xs) for xs in it.xss]
    for i = 1:n
        if done(it.xss[i], js[i])
            return js, nothing
        end
    end
    vs = Vector{Any}(n)
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


Base.done(it::RowMajorProduct, state) = state[2] === nothing
