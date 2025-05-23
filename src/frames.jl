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

length(af::AbstractAlgebraFrame) = n + offsets

algebra(n::Int64, prs::Pair{<:Any, DataType} ...; keys ...) = AlgebraFrame(n, prs ...; keys ...)

algebra!(f::Function, af::AlgebraFrame) = begin
    data = generate(af)
    f(data)
    [begin
        af.algebra[e].pipe = [x -> data[x, e]]
    end for (e, alg) in enumerate(data.values)]
    nothing::Nothing
end

algebra!(f::Function, af::AlgebraFrame, name::String) = begin
    pos = findfirst(n -> n == name, af.names)
    algebra!(f, af.algebra[pos])
    nothing
end

abstract type AbstractFrame end

mutable struct FrameRow <: AbstractFrame
    names::Vector{String}
    values::Vector{Any}
end

abstract type AbstractDataFrame <: AbstractFrame end

mutable struct Frame <: AbstractDataFrame
    names::Vector{String}
    types::Vector{Type}
    values::Vector{Vector{<:Any}}
end

getindex(f::AbstractFrame, name::String) = begin
    position = findfirst(n::String -> n == name, f.names)
    f.values[position]
end

getindex(f::AbstractFrame, ind::Integer) = begin
    f.values[ind]
end

getindex(f::AbstractFrame, ind::Integer, ind2::Integer) = begin
    f.values[ind2][ind]
end

getindex(f::AbstractFrame, ind::Integer, col::String) = begin
    ind2 = findfirst(n::String -> n == col, f.names)
    f.values[ind2][ind]
end

getindex(f::Frame, ind::Integer, observations::UnitRange{Int64} = 1:length(f.values[1])) = begin
    f.values[ind][observations]
end

getindex(f::Frame, name::String, observations::UnitRange{Int64} = 1:length(f.values[1])) = begin
    axis = findfirst(n::String -> n == name, f.names)
    f.values[n]
end

# generation

generate(af::AbstractAlgebraFrame) = Frame(af.names, af.T, [(generate(alg) for alg in af.algebra) ...])

function getindex(af::AbstractAlgebraFrame, column::String, r::UnitRange{Int64} = 1:af.length)
    colaxis = findfirst(x -> x == column, af.names)
    af.algebra[colaxis][r]
end

function show(io::IO, algebra::AbstractAlgebraFrame)
    colnames = join((n for n in algebra.names), " | ")
    println(io, 
        "frame $(algebra.length + algebra.offsets) x $(length(algebra.names)) | $colnames")
end

function show(io::IO, algebra::AbstractDataFrame)

end

eachrow(af::AlgebraFrame) = begin
    [[alg[e] for e in 1:af.length] for alg in af.values]
end

eachcol(af::AlgebraFrame) = begin
    [(generate(alg) for alg in af.algebra) ...]
end

function pairs(af::AbstractAlgebraFrame)
    names = af.names
    [begin 
        names[e] => generate(af.algebra[e])
    end for e in 1:length(names)]
end

Dict(af::AbstractAlgebraFrame) = Dict(pairs(af) ...)

# `AlgebraFrame` API
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

join!(f::Function, af::AlgebraFrame, col::Pair{String, DataType}; axis::Any = length(af.names)) = begin
    alg = algebra(f, col[2], af.length + af.offsets)
    if typeof(axis) <: AbstractString
        axis = findfirst(n::String -> n == axis, af.names)
    end
    if axis < length(af.names)
        af.names = vcat(af.names[1:axis], col[1], af.names[axis + 1:end])
        af.algebra = vcat(af.algebra[1:axis], alg, af.algebra[axis + 1:end])
        af.T = vcat(af.T[1:axis], col[2], af.T[axis + 1:end])
    else
        push!(af.names, col[1])
        push!(af.algebra, alg)
        push!(af.T, col[2])
    end
    af::AlgebraFrame
end

join!(af::AlgebraFrame, col::Pair{String, DataType}; axis::Any = length(af.names)) = begin
    join!(algebra_initializer(col[2]), af, col, axis = axis)
end

join!(af::AlgebraFrame, af2::AlgebraFrame; axis::Any = length(af.names)) = begin
    if typeof(axis) <: AbstractString
        axis = findfirst(n::String -> n == axis, af.names)
    end
    if axis < length(af.names)
        af.names = vcat(af.names[1:axis], af2.names, af.names[axis + 1:end])
        af.algebra = vcat(af.algebra[1:axis], af2.algebra, af.algebra[axis + 1:end])
        af.T = vcat(af.T[1:axis], af2.T, af.T[axis + 1:end])
    else
        push!(af.names, af2.names ...)
        push!(af.algebra, af2.algebra ...)
        push!(af.T, af2.T ...)
    end
end

join(af::AlgebraFrame, af2::AlgebraFrame; axis::Any = length(af.names)) = begin

end

merge(af::AlgebraFrame, af2::AlgebraFrame; at::Int64 = af.length + af.offsets) = begin

end

merge!(af::AlgebraFrame, af2::AlgebraFrame; at::Int64 = af.length + af.offsets) = begin
    for (e, name) in enumerate(af2.names)
        if name in af.names
            axis = findfirst(n -> n == name, af.names)

        else

        end
    end

end

set_generator!(f::Function, af::AbstractAlgebraFrame, axis::Any = 1) = begin
    set_generator!(f, af.algebra[axis])
end

# `Frame` API:

function join()

end

#===
(special functions)
===#
# filtering

function filter!(f::Function, af::AbstractAlgebraFrame)

end

function filter!(f::Function, af::AbstractDataFrame)

end

