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

shape(a::AbstractAlgebra) = (a.length, typeof(a).parameters[2])::Tuple{Int64, Int64}

mutable struct Algebra{T <: Any, N <: Any} <: AbstractAlgebra
    pipe::Vector{Function}
    length::Int64
    Algebra{T, N}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where {T <: Any, N <: Any} = begin
        funcs::Vector{Function} = Vector{Function}([f])
        new{T, N}(funcs, length)::AbstractAlgebra
    end
    function Algebra{T}(algebra::Algebra{<:Any, <:Any}) where T <: Any
        new{T, typeof(algebra).parameters[2]}(algebra.pipe, algebra.length)
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

const AlgebraVector{T} = Algebra{T,1}

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

algebra_initializer(T::Type{<:Integer}) = x -> T(0)
algebra_initializer(T::Type{Int64}) = x -> 0
algebra_initializer(T::Type{<:AbstractFloat}) = x -> T(0.0)
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

(:)(f::Function, alg::AbstractAlgebra) = push!(alg.pipe, f)

# generation

function generate(alg::Algebra{<:Any, <:Any}, row::UnitRange{Int64})
    gen = first(alg.pipe)
    params = methods(gen)[1].sig.parameters
    if length(params) > 1 && params[2] == Int64
        [gen(e) for e in row]
    else
        gen()[row]
    end
end

function getindex(alg::Algebra{<:Any, 1}, row::UnitRange{Int64})
    generated = generate(alg, row)
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

function generate(alg::Algebra{<:Any, <:Any}, dim::Int64)
    gen = first(alg.pipe)
    params = methods(gen)[1].sig.parameters
    if length(params) > 1 && params[2] == Int64
        gen(dim)
    else
        gen()[dim]
    end
end


function getindex(alg::Algebra{<:Any, 1}, dim::Int64)
    generated = generate(alg, dim)
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
    if col == 1
        alg[dim]
    else
        throw("Algebra error TODO here")
    end
end

getindex(alg::AbstractAlgebra, dim::Int64, col::UnitRange{Int64}) = getindex(alg, dim:dim, col)

getindex(alg::AbstractAlgebra, dim::UnitRange{Int64}, col::Int64) = getindex(alg, dim, col:col)

function generate(alg::Algebra{<:Any, <:Any})
    gen = first(alg.pipe)
    params = methods(gen)[1].sig.parameters
    if length(params) > 1 && params[2] == Int64
        [gen(dim) for dim in 1:length(alg)]
    else
        gen()
    end
end

function vect(alg::Algebra{<:Any, 1})
    generated = generate(alg)
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
    generated = generate(alg)
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


function eachrow(alg::AbstractAlgebra)
    eachrow([alg])
end

function eachcol(alg::AbstractAlgebra)
    eachcol([alg])
end