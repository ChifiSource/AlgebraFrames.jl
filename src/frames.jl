#==| Hi friend, welcome to `algebraframes.jl`. Here is a map.
- AlgebraFrame
- AlgebraFrame creation (:)
- Algebra generation (vect, getindex, eachrow ...)
- FrameRow (row indexing/filtering)
==#
mutable struct AlgebraFrame{T <: Any} <: AbstractAlgebra
    n::Int64
    names::Vector{String}
    T::Vector{Type}
    algebra::Vector{Algebra{<:Any, 1}}
    AlgebraFrame(n::Int64, pairs::Pair{<:Any, DataType} ...; T::Symbol = :a) = begin
        dct = Dict(pairs ...)
        names = [keys(dct) ...]
        types = [values(dct) ...]
        alg = Vector{Algebra{<:Any, 1}}([begin
                    algebra(types[e], n, algebra_initializer(types[e]))
                end for (e, name) in enumerate(names)])
        new{T}(n, names, types, alg)::AlgebraFrame
    end
end

length(af::AlgebraFrame{<:Any}) = length(af.algebra[1])

algebra(n::Int64, prs::Pair{<:Any, DataType} ...; keys ...) = AlgebraFrame(n, prs ...; keys ...)

algebra!(f::Function, af::AlgebraFrame) = begin
    data = hcat((generate(alg) for alg in af.algebra) ...)
    f(data)
    [begin
        af.algebra[e].pipe = [x -> data[x, e]]
    end for (e, alg) in enumerate(eachcol(data))]
    nothing::Nothing
end

algebra!(f::Function, af::AlgebraFrame, name::String) = begin
    pos = findfirst(n -> n == name, af.names)
    algebra!(f, af.algebra[pos])
    nothing
end

# generation
function getindex(af::AlgebraFrame{<:Any}, column::String, r::UnitRange{Int64} = 1:af.n)
    colaxis = findfirst(x -> x == column, af.names)
    af.algebra[colaxis][r, colaxis:colaxis]
end

getindex(af::AlgebraFrame{<:Any}, args ...) = getindex(af.algebra, args ...)

vect(af::AlgebraFrame{<:Any}) = vect(af.algebra)

function show(io::IO, algebra::AlgebraFrame{<:Any})
    println(io, "frame")
end

# rows
mutable struct FrameRow
    names::Vector{String}
    values::Vector{<:Any}
end

function filter!(f::Function, af::AlgebraFrame{<:Any})
    af:vec -> begin

    end
end

eachrow(af::AlgebraFrame) = eachrow()


function pairs(af::AlgebraFrame{<:Any})
    cols = eachcol(af.algebra)
    names = af.names
    [begin 
        names[e] => cols[e]
    end for e in 1:length(cols)]
end