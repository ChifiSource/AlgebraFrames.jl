"""
Created in December, 2023 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### Algia

"""
module Algia
import Base: (:), getindex, setindex!, vect, Vector, show

abstract type AbstractAlgebra end

mutable struct Algebra{T <: Any, N <: Any} <: AbstractAlgebra
    pipe::Dict{Tuple, Function}
    length::Int64
    Algebra{T}(f::Function, length::Int64, width::Int64) where T <: Any = begin
        funcs::Dict{Tuple, Function} = Dict{Tuple, Function}()
        push!(funcs, (length, width) => f)
        new{T, 1}(funcs, length)
    end
    Algebra{T}(length::Int64 = 1, width::Int64 = 1) where T <: Any = begin
        Algebra{T}(x -> 0, length, width)
    end
    Algebra{T}(f::Function, dim::Tuple) where T <: Any = begin
        if length(dim) == 1
            Algebra{T}(f, dim[1], 1)
        elseif length(dim) == 2
            Algebra{T}(f, dim[2], width)
        end
    end
end
mutable struct AlgebraFrame <: AbstractAlgebra
    Vector{Pair{String, Algebra}}()
    function AlgebraFrame(f::Function)

    end
end
# algebra interface
function (:)(alg::AbstractAlgebra, f::Function)
    push!(alg.pipe, (alg.length, ) => f)
end

function (:)(T::Type, un::Int64, f::Function = x -> 0)
    Algebra{T}(f, un, 1)::Algebra{T, 1}
end

function (:)(T::Type, dim::Tuple, f::Function = x -> 0)
    Algebra{T}(f, dim, dos)::Algebra{T, dos}
end

function setindex!()

end
# generation interface
function Vector(alg::AbstractAlgebra{<:Any, 1})
    gen = alg.pipe[1]
    [gen(e) for e in 1:length(alg)]
    []
end

function vect()

end

function getindex()

end

end # module Algia
