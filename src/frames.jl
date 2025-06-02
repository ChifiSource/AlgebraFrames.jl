#==| Hi friend, welcome to `algebraframes.jl`. Here is a map.
- AlgebraFrame
- AlgebraFrame creation (:)
- Algebra generation (vect, getindex, eachrow ...)
- FrameRow (row indexing/filtering)
==#

abstract type AbstractAlgebraFrame <: AbstractAlgebra end

abstract type AbstractTransformation end

mutable struct Transform <: AbstractTransformation
    col::Vector{Int16}
    f::Function
end

mutable struct AlgebraFrame{T <: Any} <: AbstractAlgebraFrame
    length::Int64
    names::Vector{String}
    T::Vector{Type}
    gen::Vector{Function}
    transformations::Vector{Transform}
    offsets::Int64
    AlgebraFrame(n::Int64, pairs::Pair{<:Any, DataType} ...; T::Symbol = :a) = begin
        dct = Dict(pairs ...)
        names = [keys(dct) ...]
        types = [values(dct) ...]
        gens = [algebra_initializer(types[e]) for e in 1:length(names)]
        new{T}(n, names, types, gens, Vector{Transform}(), 0)::AlgebraFrame
    end
end

generate(af::AbstractAlgebraFrame) = begin 
    values = [begin
        generate(Algebra{af.T[col]}(af.gen[col], af.length))
    end for col in 1:length(af.names)]
    newf = Frame(af.names, af.T, values)
    for transform in af.transformations
        current_frame = newf[transform.col]
        transform.f(current_frame)
    end
    newf::Frame
end

names(af::AbstractAlgebraFrame) = af.names

length(af::AbstractAlgebraFrame) = af.length + offsets

algebra(n::Int64, prs::Pair{<:Any, DataType} ...; keys ...) = AlgebraFrame(n, prs ...; keys ...)

algebra!(f::Function, af::AlgebraFrame) = begin
    push!(af.transformations, 
        Transform([e for e in 1:length(af.names)], f))
end

algebra!(f::Function, af::AlgebraFrame, name::Int64 ...) = begin
    push!(transformations, Transform([name ...], f))
end

algebra!(f::Function, af::AlgebraFrame, names::String ...) = begin
    positions = [findfirst(n -> n == name, af.names) for name in names]
    algebra!(f, af, positions ...)
    nothing
end

algebra!(f::Function, af::AlgebraFrame, names::UnitRange{Int64}) = begin
    algebra!(f, af, names ...)
end

function set_generator!(f::Function, af::AlgebraFrame, col::Integer)
    af.gen[col] = f
end

function set_generator!(f::Function, af::AlgebraFrame, col::String)
    axis = findfirst(n -> n == col, af.names)
    set_generator!(f, af, axis)
end

function getindex(af::AbstractAlgebraFrame, column::Integer, r::UnitRange{Int64} = 1:af.length)
    init = generate(Algebra{af.T[column]}(af.gen[column], af.length))

end

function getindex(af::AbstractAlgebraFrame, column::String, r::UnitRange{Int64} = 1:af.length)
    colaxis = findfirst(x -> x == column, af.names)
    af[colaxis, r]
end

eachrow(af::AlgebraFrame) = begin
    [begin

    end for e in 1:af.length]
end

framerows(af::AlgebraFrame) = begin

end

function loop_rows(f::Function, af::AlgebraFrame)
    row = FrameRow(af.names, [])
    n = length(af.names)
    for row_number in 1:af.length
        row.values = [@view af.values[e][row_number] for e in 1:n]
        f(row)
    end
end

eachcol(af::AlgebraFrame) = begin
    generate(af).values
end

function pairs(af::AbstractAlgebraFrame)
    names = af.names
    [begin 
        names[e] => generate(af.algebra[e])
    end for e in 1:length(names)]
end

Dict(af::AbstractAlgebraFrame) = Dict(pairs(af) ...)

function show(io::IO, algebra::AbstractAlgebraFrame)
    colnames = join((n for n in algebra.names), " | ")
    println(io, 
        "frame $(algebra.length + algebra.offsets) x $(length(algebra.names)) | $colnames")
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

getindex(f::AbstractFrame, cols::UnitRange{<:Integer}) = begin
    Frame([f.names[e] for e in cols], [f.types[e] for e in cols], [f.values[e] for e in cols])
end

getindex(f::AbstractFrame, cols::Vector{<:Integer}) = begin
    Frame([f.names[e] for e in cols], [f.types[e] for e in cols], [f.values[e] for e in cols])
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
    f.values[axis]
end

function setindex!(f::AbstractFrame, ind::Integer, value::AbstractVector)
    n::Int64 = length(f.names)
    if ind > n
        throw("future error")
    elseif length(value) != length(f.values[1])
        throw("future error")
    end
    f.values[n] = value
    f::AbstractFrame
end

function setindex!(f::AbstractFrame, colname::String, value::AbstractVector)
    position = findfirst(x -> x == colname, names)
    if isnothing(position)
        # (adds a new column)
        T::Type = typeof(value).parameters[1]
        join!(f, colname, T, value)
        return(f)::AbstractFrame
    end
    setindex!(f, position, value)::AbstractFrame
end


function setindex!(f::AbstractFrame, position::Int64, row::Any ...)
    row = FrameRow(f.names, [row ...])
    f[position] = row
end


function setindex!(f::AbstractFrame, position::Int64, row::FrameRow)
    [f.values[e][position] = row.values[e] for e in 1:length(f.values)]
    f::AbstractFrame
end

function setindex!(f::AbstractFrame, axis::Any, position::Int64, value::Any)
    if typeof(axis) <: AbstractString
        axis = findfirst(n -> n == axis, f.names)
    end
    f.values[axis][position] = value
    f::AbstractFrame
end

function show(io::IO, frame::AbstractDataFrame)

end

function display(io::IO, mime::MIME{Symbol("text/html")}, frame::AbstractDataFrame)
    colframe = 
    for col in frame

    end
end

# basic `AlgebraFrame` API
function deleteat!(af::AlgebraFrame, row_n::Int64)
	for alg in af.algebra
        deleteat!(alg, row_n)
	end
	af.offsets -= 1
	af::AlgebraFrame
end

function deleteat!(af::AlgebraFrame, row_n::UnitRange{Int64})
	for alg in af.algebra
        for n in row_n
            deleteat!(alg, n)
        end
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
            af2.algebra
        else

        end
    end

end

set_generator!(f::Function, af::AbstractAlgebraFrame, axis::Any = 1) = begin
    set_generator!(f, af.algebra[axis])
end

# basic `Frame` API:

function join!(f::AbstractFrame, colname::AbstractString, T::Type, value::AbstractVector; axis::Any = length(f.names))
    if typeof(axis) <: AbstractString
        axis = findfirst(n::String -> n == axis, f.names)
    end
    insert!(f.names, axis - 1, colname)
    insert!(f.types, axis - 1, T)
    insert!(f.values, axis - 1, value)
    f::AbstractFrame
end


function drop!(f::AbstractFrame, col::Int64)
    deleteat!(f.types, col)
    deleteat!(f.names, col)
    deleteat!(f.values, col)
    f::AbstractFrame
end

function drop!(f::AbstractFrame, col::AbstractString)
    axis = findfirst(x -> x == col, f.names)
    drop!(f, axis)::AbstractFrame
end

function deleteat!(f::AbstractFrame, observations::UnitRange{Int64})
    N::Int64 = length(f.values)
    [[deleteat!(f.values[e], obs) for e in 1:N] for obs in observations]
    f::AbstractFrame
end

function deleteat!(f::AbstractFrame, observation::Int64)
    [deleteat!(f.values[e], observation) for e in 1:length(values)]
    f::AbstractFrame
end

function eachrow(f::AbstractFrame)
    [begin
        FrameRow(f.names, [f.values[n][x] for n in 1:length(f.values)]) 
    end for x in 1:length(f.values[1])]::Vector{FrameRow}
end

function eachcol(f::AbstractFrame)
    f.values::Vector{<:AbstractVector}
end

function pairs(f::AbstractFrame)
    [f.names[e] => f.values[e] for e in 1:length(f.values)]
end

function merge()

end

function merge!()

end

# frame row API:

#===
special functions (for both)
===#
# filtering

function filter!(f::Function, af::AbstractAlgebraFrame)
    N::Int64 = length(af.names)
    for x in 1:af.length
        row = FrameRow(af.names, [af[e, x] for e in 1:N])
        remove = f(row)
        if remove
            deleteat!(af, x)
        end
    end
    af::AbstractAlgebraFrame
end

function filter!(f::Function, af::AbstractDataFrame)
    N::Int64 = length(af.names)
    for x in 1:length(af.values[1])
        row = FrameRow(af.names, [af.values[e][x] for e in 1:N])
        remove = f(row)
        if remove
            deleteat!(af, x)
        end
    end
    af::AbstractDataFrame
end

# replace
function replace!(af::AbstractAlgebraFrame, value::Any, with::Any)

end

function replace!(af::AbstractAlgebraFrame, col::Int64, value::Any, with::Any)

end

function replace!(af::AbstractAlgebraFrame, col::String, value::Any, with::Any)

end

function replace!(af::AbstractAlgebraFrame, col::String, value::Any, with::Any)

end

function cast!(af::AbstractAlgebraFrame, col::Int64, to::Type)

end

function cast!(af::AbstractAlgebraFrame, col::String, to::Type)

end