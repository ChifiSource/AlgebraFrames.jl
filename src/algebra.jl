#==| Hi friend, welcome to `algebra.jl`. Here is a map.
- Algebra
- Algebra Base
- Algebra creation (:)
- Algebra generation (vect, getindex, eachrow ...)
==#
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
        Algebra{T, width}(f, length)::AbstractAlgebra
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

function reshape(alg::AbstractAlgebra, news::Tuple{Int64, Int64})

end

algebra_initializer(T::Type{Int64}) = x -> 0
algebra_initializer(T::Type{Float64}) = x -> 0.0
algebra_initializer(T::Type{String}) = x -> "null"



# creation
function (:)(T::Type{<:Any}, un::Int64, f::Function = algebra_initializer(T))
    Algebra{T}(f, un, 1)::Algebra{T, 1}
end

function (:)(T::Type{<:Any}, dim::Tuple, f::Function = algebra_initializer(T))
    Algebra{T}(f, dim)::Algebra{T, dim[2]}
end



function (:)(alg::AbstractAlgebra, f::Function)
    push!(alg.pipe, f)
end

# algebraic indexing
function (:)(alg::AbstractAlgebra, dim::Tuple)
    typ = typeof(alg)
    T = typ.parameters[1]
    seconddim = typ.parameters[2]
    if length(dim) == 2
        seconddim = dim[2]
    end
    gen::AbstractArray = alg[dim[1], seconddim]
    Algebra{T}(size(gen)) do e
        gen[e]
    end
end

function (:)(alg::AbstractAlgebra, dim::Int64, col::Int64 = 1)
    T = typeof(alg).parameters[1]
    gen::AbstractArray = alg[dim, col]
    Algebra{T}(1) do e
        gen[e]
    end
end

function (:)(alg::AlgebraVector{<:Any}, dim::UnitRange{Int64})
    T = typeof(alg).parameters[1]
    gen::AbstractArray = alg[dim]
    Algebra{T}(length(gen)) do e
        gen[e]
    end
end

# generation
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
    end for column in 2:N]
    [begin
        try
            func(generated)
        catch e
            throw("Algebra error todo here")
        end
    end for func in alg.pipe[2:length(alg.pipe)]]
    generated::AbstractArray
end

function getindex(alg::Algebra{<:Any, 1}, row::UnitRange{Int64})
    gen = first(alg.pipe)
    generated = [gen(e) for e in row]
    N = typeof(alg).parameters[2]
    [begin
        generated = hcat(generated, [gen(e) for e in lastlen + 1:(lastlen + len)])
        lastlen += len
    end for column in 2:N]
    [begin
        try
            func(generated)
        catch e
            throw("Algebra error todo here")
        end
    end for func in alg.pipe[2:length(alg.pipe)]]
    generated::AbstractArray
end

function getindex(alg::Algebra{<:Any, 1}, dim::Int64)
    generated = first(alg.pipe)([dim])
    N = typeof(alg).parameters[2]
    [begin
        try
            func(generated)
        catch e
            throw("Algebra error todo here")
        end
    end for func in alg.pipe[2:length(alg.pipe)]]
    generated::Any
end

function getindex(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:typeof(alg).parameters[2])
    gen = first(alg.pipe)
    generated = [gen(e) for e in row]
    len = length(generated)
    lastlen = length(generated)
    [begin
        generated = hcat(generated, [gen(e) for e in lastlen + 1:(lastlen + len)])
        lastlen += len
    end for column in col[2:length(col)]]
    [begin
        try
            func(generated)
        catch e
            throw("Algebra error todo here")
        end
    end for func in alg.pipe[2:length(alg.pipe)]]
    generated::AbstractArray
end

function getindex(alg::AbstractAlgebra, dim::Int64, col::Int64)
    println("called single multidim")
end

getindex(alg::AbstractAlgebra, dim::Int64, col::UnitRange{Int64}) = getindex(alg, dim:dim, col)

getindex(alg::AbstractAlgebra, dim::UnitRange{Int64}, col::Int64) = getindex(alg, dim, col:col)

function eachrow(alg::AbstractAlgebra)

end

function eachcol(alg::AbstractAlgebra)

end