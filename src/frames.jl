#==| Hi friend, welcome to `algebraframes.jl`. Here is a map.
- AlgebraFrame
- AlgebraFrame creation (:)
- Algebra generation (vect, getindex, eachrow ...)
- FrameRow (row indexing/filtering)
==#

abstract type AbstractAlgebraFrame <: AbstractAlgebra end

mutable struct AlgebraFrame{T <: Any} <: AbstractAlgebraFrame
    length::Int64
    names::Vector{String}
    T::Vector{Type}
    algebra::Vector{Algebra{<:Any, 1}}
    offsets::Int64
    AlgebraFrame(n::Int64, pairs::Pair{<:Any, DataType} ...; T::Symbol = :a) = begin
        dct = Dict(pairs ...)
        names = [keys(dct) ...]
        types = [values(dct) ...]
        alg = Vector{Algebra{<:Any, 1}}([begin
                    algebra(types[e], n, algebra_initializer(types[e]))
                end for (e, name) in enumerate(names)])
        new{T}(n, names, types, alg, 0)::AlgebraFrame
    end
end

names(af::AbstractAlgebraFrame) = names

length(af::AbstractAlgebraFrame) = n

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

generate(af::AbstractAlgebraFrame) = hcat((generate(alg) for alg in af.algebra) ...)

function getindex(af::AbstractAlgebraFrame, column::String, r::UnitRange{Int64} = 1:af.length)
    colaxis = findfirst(x -> x == column, af.names)
    af.algebra[colaxis][r]
end

vect(af::AbstractAlgebraFrame) = vect(af.algebra)

function show(io::IO, algebra::AbstractAlgebraFrame)
    colnames = join((n for n in algebra.names), " | ")
    println(io, 
        "frame $(algebra.length + algebra.offsets)rows x $(length(algebra.names))columns | $colnames")
end

# Frame API
function deleteat!(af::AlgebraFrame, row_n::Int64)
	for alg in af.algebra
        deleteat!(alg, row_n)
	end
	af.offsets -= 1
	af::AlgebraFrame
end

function drop!(af::AlgebraFrame, axis::Int64)
    deleteat!(af.names, axis)
    deleteat!(af.T, axis)
    deleteat!(af.algebra, axis)
    af::AlgebraFrame
end

function drop!(af::AlgebraFrame, col::String)
    axis = findfirst(x::String -> x == col, af.names)
    if isnothing(axis)
        throw("")
    end
    drop!(af, axis)
end

merge!(f::Function, af::AlgebraFrame, col::Pair{String, DataType}; at::Any = length(af.names)) = begin
    alg = algebra(col[2], af.length)
end

merge!(af::AlgebraFrame, af2::AlgebraFrame; at::Any = length(af.names)) = begin

end

merge(af::AlgebraFrame, af2::AlgebraFrame; at::Any = length(af.names)) = begin

end

# rows
mutable struct FrameRow
    names::Vector{String}
    values::Vector{<:Any}
end

function filter!(f::Function, af::AbstractAlgebraFrame)
    af:vec -> begin

    end
end

eachrow(af::AlgebraFrame) = eachrow()

function pairs(af::AbstractAlgebraFrame)
    cols = eachcol(af.algebra)
    names = af.names
    [begin 
        names[e] => cols[e]
    end for e in 1:length(cols)]
end