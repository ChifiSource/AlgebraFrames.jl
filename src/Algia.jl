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

"""
### abstract type **AbstractAlgebra**

### Consistencies
- pipe::Vector{AlgebraIndex}
- length::Int64
```
"""
abstract type AbstractAlgebra end

length(a::AbstractAlgebra) = a.length::Int64

mutable struct AlgebraIndex
    f::Function
    index::UnitRange{Int64}
    columns::UnitRange{Int64}
end

mutable struct Algebra{T <: Any, N <: Any} <: AbstractAlgebra
    pipe::Vector{AlgebraIndex}
    length::Int64
    Algebra{T, N}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where {T <: Any, N <: Any} = begin
        funcs::Vector{AlgebraIndex} = Vector{AlgebraIndex}()
        push!(funcs, AlgebraIndex(f, 1:length, 1:N))
        new{T, N}(funcs, length)::AbstractAlgebra
    end 
    
    Algebra{T}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where T <: Any = begin
        Algebra{T, width}(x -> 0, length)::AbstractAlgebra
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

mutable struct AlgebraFrame{N <: Any} <: AbstractAlgebra
    names::Vector{String}
    algebra::Algebra{Any, N}
    function AlgebraFrame(f::Function, observations::Int64, names::String ...)
        algebra = Algebra{Any}(f, observations, length(names))
        new{length(names)}(names, algebra)::AlgebraFrame{<:Any}
    end
end

# algebra interface

function (:)(T::Type, un::Int64, f::Function = x -> 0)
    Algebra{T}(f, un, 1)::Algebra{T, 1}
end

function (:)(T::Type, dim::Tuple, f::Function = x -> 0)
    Algebra{T}(f, dim)
end

function (:)(alg::AbstractAlgebra, f::Function)
    w = typeof(alg).parameters[2]
    indx = AlgebraIndex(f, 1:alg.length, 1:w)
    push!(alg.pipe, indx)
end

function (:)(alg::AbstractAlgebra, dim::Tuple{UnitRange, UnitRange}, f::Function)
    w = typeof(alg).parameters[2]
    indx = AlgebraIndex(f, dim ...)
    push!(alg.pipe, indx)
end

#==
function setindex!()

end
==#
# generation interface

function vect(alg::Algebra{<:Any, 1})
    gen = first(alg.pipe).f
    generated = [gen(e) for e in 1:length(alg)]
    for index in alg.pipe[2:length(alg.pipe)]
        except = generated[index.index]
        index.f(except)
        generated[index.index] .= except 
    end
    generated::AbstractArray
end

function vect(alg::AbstractAlgebra)
    gen = first(alg.pipe).f
    generated = [gen(e) for e in 1:length(alg)]
    lastlen = length(generated)
    N = typeof(alg).parameters[2]
    [begin
        newcol = [gen(e + lastlen) for e in 1:length(alg)]
        lastlen += length(newcol)
        generated = hcat(generated, newcol)
    end for col in 2:N]
    for index in alg.pipe
        except = generated[index.index, index.columns]
        index.f(except)
        generated[index.index, index.columns] .= except
    end
    generated::AbstractArray
end
==#
function eachrow(alg::AbstractAlgebra)

end

function eachcol(alg::AbstractAlgebra)

end
function getindex(alg::AbstractAlgebra, row::UnitRange{Int64} = 1:alg.length, col::UnitRange{Int64} = 1:typeof(alg).parameters[2])

end

function getindex(alg::Algebra{<:Any, 1}, row::UnitRange{Int64} = 1:alg.length)
    gen = first(alg.pipe).f
    generated = [[gen(e) for e in row for i in w]]
end

export AlgebraFrame, Algebra, AlgebraVector
end # module Algia
