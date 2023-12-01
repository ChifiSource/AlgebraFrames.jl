"""
Created in December, 2023 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### Algia

"""
module Algia
import Base: (:), getindex, setindex!, vect, Vector, show, length

abstract type AbstractAlgebra end

length(a::AbstractAlgebra) = a.length::Int64

mutable struct Algebra{T <: Any, N <: Any} <: AbstractAlgebra
    pipe::Dict{Tuple, Function}
    length::Int64
    Algebra{T, N}(f::Function, length::Int64) where {T <: Any, N <: Any} = begin
        funcs::Dict{Tuple, Function} = Dict{Tuple, Function}()
        push!(funcs, (length, N) => f)
        new{T, N}(funcs, length)::AbstractAlgebra
    end 
    Algebra{T}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where T <: Any = begin
        Algebra{T, width}(x -> 0, length)::AbstractAlgebra
    end
    Algebra{T}(f::Function, dim::Tuple) where T <: Any = begin
        if length(dim) == 1
            Algebra{T}(f, dim[1], 1)
        elseif length(dim) == 2
            Algebra{T}(f, dim[2], width)
        end
    end
end

const AlgebraVector{T} = Algia.Algebra{T,1}

mutable struct AlgebraFrame{N <: Any} <: AbstractAlgebra
    pipe::Dict{Tuple, Function}
    names::Vector{String}
    algebra::Algebra{Any, N}
    function AlgebraFrame(f::Function, n_features::Int64, n::Int64)
        algebra = Algebra{Any}(n, n_features)
    end
    function AlgebraFrame(n_features::Int64, n::Int64)
        algebra = Algebra{Any}(n, n_features)
        AlgebraFrame(f)
    end
end

# algebra interface
function (:)(alg::AbstractAlgebra, f::Function)
    w = typeof(alg).parameters[2]
    push!(alg.pipe, (alg.length, w) => f)
end

function (:)(T::Type, un::Int64, f::Function = x -> 0)
    Algebra{T}(f, un, 1)::Algebra{T, 1}
end

function (:)(T::Type, dim::Tuple, f::Function = x -> 0)
    Algebra{T}(f, dim, dos)::Algebra{T, dos}
end
#==
function setindex!()

end
==#
# generation interface
function Vector(alg::Algebra{<:Any, 1})
    gen = first(alg.pipe)[2]
    [gen(e) for e in 1:length(alg)]
end
#==
function vect()

end

function getindex()

end
==#

export AlgebraFrame, Algebra, AlgebraVector
end # module Algia
