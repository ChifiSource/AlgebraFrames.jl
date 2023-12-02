"""
### abstract type **AbstractAlgebra**

### Consistencies
- pipe
- length::Int64
```
"""
abstract type AbstractAlgebra end

length(a::AbstractAlgebra) = a.length::Int64

shape(a::AbstractAlgebra) = (a.length)::Tuple{Int64}

mutable struct Algebra{T <: Any, N <: Any} <: AbstractAlgebra
    pipe::Vector{Function}
    length::Int64
    Algebra{T, N}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where {T <: Any, N <: Any} = begin
        funcs::Vector{Function} = Vector{Function}([f])
        new{T, N}(funcs, length)::AbstractAlgebra
    end 
    Algebra{T}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where T <: Any = begin
        Algebra{T, width}(x -> 0, length)::AbstractAlgebra
    end
    Algebra{T}(f::Function = x -> 0.0, length::Int64 = 1, width::Int64 = 1) where T <: AbstractFloat = begin
        Algebra{T, width}(x -> 0.0, length)::AbstractAlgebra
    end
    Algebra{T}(f::Function = x -> true, length::Int64 = 1, width::Int64 = 1) where T <: Bool = begin
        Algebra{T, width}(x -> true, length)::AbstractAlgebra
    end
    Algebra{T}(f::Function = x -> "nothing", length::Int64 = 1, width::Int64 = 1) where T <: AbstractString = begin
        Algebra{T, width}(x -> "nothing", length)::AbstractAlgebra
    end
    Algebra{T}(f::Function, dim::Tuple) where T <: Any = begin
        if length(dim) == 1
            Algebra{T}(f, dim[1], 1)
        elseif length(dim) == 2
            Algebra{T}(f, dim[1], dim[2])
        end
    end
    function Algebra(vec::Vector{<:Any})
        T = typeof(vec).parameters[1]
        Algebra{T, 1}(length(vec)) do e
            vec[e]
        end::AbstractAlgebra
    end
end

const AlgebraVector{T} = Algia.Algebra{T,1}

function shape(algebra::Algebra{<:Any, <:Any})
    (algebra.length, typeof(algebra).parameters[2])
end

function show(io::IO, algebra::Algebra{<:Any, <:Any})
    cols, rows = typeof(algebra).parameters[2], length(algebra)
    T = typeof(algebra).parameters[1]
    println(io, "$T $(rows)x$cols")
end

function reshape()

end

function (:)(T::Type, un::Int64, f::Function = x -> 0)
    Algebra{T}(f, un, 1)::Algebra{T, 1}
end

function (:)(T::Type, dim::Tuple, f::Function = x -> 0)
    Algebra{T}(f, dim)
end

function (:)(alg::AbstractAlgebra, f::Function)
    push!(alg.pipe, f)
end

function vect(alg::Algebra{<:Any, 1})
    gen = first(alg.pipe)
    generated = [gen(e) for e in 1:length(alg)]
    [begin
        try
            func(generated)
        catch e
            throw("Algebra error todo here")
        end
    end for func in alg.pipe[2:length(alg.pipe)]]
    generated::AbstractArray
end

function vect(alg::AbstractAlgebra)
    gen = first(alg.pipe)
    generated = [gen(e) for e in 1:length(alg)]
    len = length(generated)
    lastlen = length(generated)
    N = typeof(alg).parameters[2]
    [begin
        generated = hcat(generated, [gen(e) for e in lastlen + 1:(lastlen + len)])
        lastlen += len
    end for column in 1:N]
    [begin
        try
            func(generated)
        catch e
            throw("Algebra error todo here")
        end
    end for func in alg.pipe[2:length(alg.pipe)]]
    generated::AbstractArray
end

function getindex(alg::Algebra{<:Any, 1}, row::UnitRange{Int64} = 1:alg.length)
    gen = first(alg.pipe).f
    generated = [gen(e) for e in row]
    for index in alg.pipe[2:length(alg.pipe)]
        ind = index.index
        commons = findall(i -> i in row, Vector(generated))
        if length(commons) == 0
            continue
        end
        ind = minimum(commons):maximum(commons)
        except = generated[ind]
        start = minimum(ind) - 1
        startlen = length(except)
        nd = maximum(ind) + 1
        index.f(except)
        if length(except) != startlen
            difference = startlen - length(except)
            alg.length -= difference
        end
        generated = vcat(generated[1:start], except, generated[nd:length(generated)])
    end
    generated::AbstractArray
end

function getindex(alg::Algebra{<:Any, 1}, dim::Int64)
    generated = first(alg.pipe).f([dim])
    for index in alg.pipe[2:length(alg.pipe)]
        if dim in index.index
            index.f([generated])
        end
    end
    generated
end

function eachrow(alg::AbstractAlgebra)

end

function eachcol(alg::AbstractAlgebra)

end

function getindex(alg::AbstractAlgebra, row::UnitRange{Int64} = 1:alg.length, col::UnitRange{Int64} = 1:typeof(alg).parameters[2])

end

function getindex(alg::AbstractAlgebra, dim::Int64, col::Int64)

end
