#==| Hi friend, welcome to `algebra.jl`. Here is a map.
- Algebra
- Algebra Base
- Algebra creation (:)
- Algebra generation (vect, getindex, eachrow ...)
==#
"""
```julia
abstract type **AbstractAlgebra**
```
Consistencies
- pipe::Vector{Function}
- length::Int64
- `offsets`::Any
```
`AbstractAlgebra` is an algebraic type that holds data outside of memory. These types can be generated using 
`AlgebraFrames.generate` or `generate`, they also have a `length` and a pipeline of functions stored within them. 
`offsets` is used to measure any changes in dimensionality that come from certain operations -- such as using 
the `deleteat!` function directly on the `Algebra` itself.
"""
abstract type AbstractAlgebra end

length(a::AbstractAlgebra) = (a.length::Int64 + a.offsets[1])

size(a::AbstractAlgebra) = (a.length + a.offsets[1], typeof(a).parameters[2] + a.offsets[2])::Tuple{Int64, Int64}

mutable struct Algebra{T <: Any, N <: Any} <: AbstractAlgebra
    pipe::Vector{Function}
    length::Int64
    offsets::Pair{Int64, Int64}
    Algebra{T, N}(pipe::Vector{Function}, length::Int64, offsets::Pair{Int64, Int64}) where {T <: Any, N <: Any}= new{T, N}(pipe, 
        length, offsets)
    Algebra{T, N}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where {T <: Any, N <: Any} = begin
        funcs::Vector{Function} = Vector{Function}([f])
        new{T, N}(funcs, length, 0 => 0)::AbstractAlgebra
    end
    function Algebra{T}(algebra::Algebra{<:Any, <:Any}) where T <: Any
        new{T, typeof(algebra).parameters[2]}(algebra.pipe, algebra.length, 0 => 0)
    end

end

function copy(alg::AbstractAlgebra)
    params = typeof(alg).parameters
    Algebra{params[1], params[2]}(alg.pipe, alg.length, alg.offsets)
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

function Algebra(vec::AbstractArray)
    T = typeof(vec).parameters[1]
    Algebra{T, 1}(length(vec)) do e
        vec[e]
    end::AbstractAlgebra
end

const AlgebraVector{T} = Algebra{T,1}

function show(io::IO, algebra::Algebra{<:Any, <:Any})
    cols, rows = typeof(algebra).parameters[2], length(algebra)
    T = typeof(algebra).parameters[1]
    println(io, "$T $(rows)x$cols")
end

function reshape(alg::AbstractAlgebra, news::Tuple{Int64, Int64})
    current_rows = typeof(alg).parameters[2]
    current_len = length(alg)

end

algebra_initializer(T::Type{<:Integer}) = x -> T(0)
algebra_initializer(T::Type{Int64}) = x -> 0
algebra_initializer(T::Type{<:AbstractFloat}) = x -> T(0.0)
algebra_initializer(T::Type{Float64}) = x -> 0.0
algebra_initializer(T::Type{String}) = x -> "null"

deleteat!(alg::AlgebraVector{<:Any}, n::Int64) = begin
    algebra!(alg) do res
        deleteat!(res, n)
    end
    alg.offsets = alg.offsets[1] - 1 => alg.offsets[2]
end

set_generator!(f::Function, alg::AbstractAlgebra) = alg.pipe[1] = f

# creation
algebra(T::Type{<:Any}, n::Int64, f::Function = algebra_initializer(T)) = Algebra{T}(f, n, 1)::Algebra{T, 1}

function algebra(T::Type{<:Any}, dim::Tuple, f::Function = algebra_initializer(T))
    Algebra{T}(f, dim)::Algebra{T, dim[2]}
end

algebra(vec::AbstractArray) = Algebra(vec)

function algebra(f::Function, T::Type{<:Any}, dim::Tuple)
    Algebra{T}(f, dim)::Algebra{T, dim[2]}
end

function algebra(f::Function, T::Type{<:Any} = methods(f)[1].sig.parameters[1], dim::Int64 = 1)
    Algebra{T}(f, dim, 1)::Algebra{T, 1}
end

algebra(vec::Vector{<:Any}) = Algebra(vec)

algebra!(f::Function, alg::AbstractAlgebra) = push!(alg.pipe, f)

function generate(alg::Algebra{<:Any, <:Any})
    gen = first(alg.pipe)
    params = methods(gen)[1].sig.parameters
    generated = if length(params) > 1
        [gen(dim) for dim in 1:length(alg)]
    else
        gen()
    end
    N = typeof(alg).parameters[2]
    if N > 1
        len = length(generated)
        lastlen = length(generated)
        [begin
            generated = hcat(generated, [gen(e) for e in lastlen + 1:(lastlen + len)])
            lastlen += len
        end for column in 2:N]
     end
    return(generated)
end

function generate(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:1)
    gen = first(alg.pipe)
    N_COLS = typeof(alg).parameters[2]
    params = methods(gen)[1].sig.parameters
    if maximum(col) > N_COLS

    elseif maximum(row) > alg.length
        throw("indexing too big of a value for the length")
    end
    col_length = Int64(round(N_COLS / alg.length))
    generated = if length(params) > 1
        vals = (vcat(fill(0, minimum(row) - 1), [gen(Int64(round(dim + colrange * col_length))) for dim in row], 
        fill(0, length(alg) - maximum(row))) for colrange in N_COLS)
        hcat(vals ...)
    else
        gen()
    end
    generated
end

getindex(alg::AbstractAlgebra, dim::Int64) = getindex(alg, dim:dim, 1:1)[dim]

getindex(alg::AbstractAlgebra, dim::Int64, dim2::Int64) = getindex(alg, dim:dim, dim2:dim2)[dim, dim2]

function getindex(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:typeof(alg).parameters[2])
    generated = generate(alg, row, col)
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
    [begin
        try
            func(generated)
        catch e
            throw(e)
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

function vcat(origin::AbstractAlgebra, algebra::AbstractAlgebra ...)
    T = typeof(origin)
    dim = T.parameters[2]
    total_len = origin.length
    offsets = origin.offsets
    pipe = origin.pipe
    T = T.parameters[1]
    for alg in algebra
        alg_type = typeof(alg)
        if alg_type.parameters[2] != dim
            throw("future bounds error")
        end
        total_len += alg.length
        offsets[1] += alg.offsets[1]
        offsets[2] += alg.offsets[2]
        push!(origin.pipe, alg.pipe ...)
    end
    Algebra{T, dim}(pipe, total_len, offsets)::Algebra{T, dim}
end

function hcat(origin::AbstractAlgebra, algebra::AbstractAlgebra ...)
    T = typeof(origin)
    dim = T.parameters[2]
    total_len = origin.length
    offsets = origin.offsets
    pipe = origin.pipe
    T = T.parameters[1]
    for alg in algebra
        push!(pipe, alg.pipe ...)
        dim += 1
        offsets[1] += alg.offsets[1]
        offsets[2] += alg.offsets[2]
    end
    Algebra{T, dim}(pipe, total_len, offsets)
end