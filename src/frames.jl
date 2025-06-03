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
    AlgebraFrame{T}(n::Integer, names::Vector{String}, types::Vector{Type}, 
    gen::Vector{Function}, transforms::Vector{Transform}, offset::Number) where {T} = begin
        new{T}(n, names, types, gen, transforms, offset)
    end
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
    push!(af.transformations, Transform([name ...], f))
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

function getindex(af::AbstractAlgebraFrame, column::Int64, r::UnitRange{Int64} = 1:af.length)
    init = generate(Algebra{af.T[column]}(af.gen[column], af.length))
    for transform in af.transformations
        if column in transform.col
            n = length(transform.col)
            position = findfirst(i -> i == column, transform.col)
            filtered = if position != n
                vcat(transform.col[1:position - 1], transform.col[position:end])
            elseif position == 1
                transform.col[position:end]
            else
                transform.col[position:position]
            end
            curr_names = [af.names[e] for e in transform.col]
            curr_types = [af.T[e] for e in transform.col]
            curr_vals = Vector{AbstractVector}([Vector{af.T[column_n]}([af.gen[column_n](e) for e in 1:af.length]) for column_n in filtered])
            for column_n in filtered

            end
            insert!(curr_vals, position, init)
            n_frame = Frame(curr_names, curr_types, curr_vals)
            transform.f(n_frame)
        end
    end
    init[r]
end

function getindex(af::AbstractAlgebraFrame, column::String, r::UnitRange{Int64} = 1:af.length)
    colaxis = findfirst(x -> x == column, af.names)
    af[colaxis, r]
end

eachrow(af::AlgebraFrame) = begin
    eachrow(generate(af))
end

framerows(af::AlgebraFrame) = begin
    framerows(generate(af))
end

eachcol(af::AlgebraFrame) = begin
    generate(af).values
end

function pairs(af::AbstractAlgebraFrame)
    names = af.names
    generated = generate(af)
    [begin 
        names[e] => generated.values[e]
    end for e in 1:af.length]
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

function loop_rows(f::Function, af::AbstractDataFrame)
    row = FrameRow(af.names, [])
    n = length(af.names)
    for row_number in 1:af.length
        row.values = [@view af.values[e][row_number] for e in 1:n]
        f(row)
    end
end

function eachcol(f::AbstractDataFrame)
    f.values
end

function eachrow(f::AbstractDataFrame)
    n = length(f.names)
    [begin
        [f.values[col][e] for col in 1:n]
    end for e in 1:length(f.values[1])]
end

function pairs(f::AbstractDataFrame)
    [f.names[e] => f.values[e] for e in length(f.names)]
end

function framerows(f::AbstractDataFrame)
    n = length(f.names)
    [begin
        FrameRow(f.names, [f.values[col][e] for col in 1:n])
    end for e in 1:length(f.values[1])]
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

getindex(f::AbstractFrame, ind::Integer, observations::UnitRange{Int64} = 1:length(f.values[1])) = begin
    f.values[ind][observations]
end

getindex(f::AbstractFrame, name::String, observations::UnitRange{Int64} = 1:length(f.values[1])) = begin
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
    display(io, frame)
end

function display(io::IO, frame::AbstractDataFrame)
    display(io, MIME"text/html"(), frame)
end

function display(io::IO, mime::MIME{Symbol("text/html")}, frame::AbstractDataFrame)
    display(MIME"text/html"(), html_string(frame))
end

function html_string(frame::Frame)
    header = "<table><tr>" * join("<th>$name</th>" for name in frame.names) * "</tr>"
    for row in eachrow(frame)
        header = header * "<tr>" * join("<td>$val</td>" for val in row) * "</tr>"
    end
    header * "</table>"
end

function deleteat!(af::AlgebraFrame, row_n::Int64)
    del = f -> begin
        deleteat!(f, row_n)
    end
	push!(af.transformations, Transform([e for e in 1:length(af.names)], del))
	af.offsets -= 1
	af::AlgebraFrame
end

function deleteat!(af::AlgebraFrame, row_n::UnitRange{Int64})
    del = f -> begin
        deleteat!(f, row_n ...)
    end
	push!(af.transformations, Transform([e for e in 1:length(af.names)], del))
	af.offsets -= 1
	af::AlgebraFrame
end

function drop!(af::AlgebraFrame, axis::Int64)
    deleteat!(af.names, axis)
    deleteat!(af.T, axis)
    deleteat!(af.gen, axis)
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
    if typeof(axis) <: AbstractString
        axis = findfirst(n::String -> n == axis, af.names)
    end
    if axis < length(af.names)
        af.names = vcat(af.names[1:axis], col[1], af.names[axis + 1:end])
        af.gen = vcat(af.gen[1:axis], f, af.gen[axis + 1:end])
        af.T = vcat(af.T[1:axis], col[2], af.T[axis + 1:end])
    else
        push!(af.names, col[1])
        push!(af.gen, f)
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
        af.gen = vcat(af.gen[1:axis], af2.gen, af.gen[axis + 1:end])
        af.T = vcat(af.T[1:axis], af2.T, af.T[axis + 1:end])
    else
        push!(af.names, af2.names ...)
        push!(af.gen, af2.gen ...)
        push!(af.T, af2.T ...)
    end
end

join(af::AlgebraFrame, af2::AlgebraFrame; axis::Any = length(af.names)) = begin
    if af.length != af2.length
        throw("future error here")
    end
    n = length(af.names)
    names = nothing
    gen = nothing
    T = nothing
    if axis < n
        names = vcat(af.names[1:axis], af2.names, af.names[axis + 1:end])
        gen = vcat(af.gen[1:axis], af2.gen, af.gen[axis + 1:end])
        T = vcat(af.T[1:axis], af2.T, af.T[axis + 1:end])
    else
        names = vcat(af.names, af2.names)
        gen = vcat(af.gen, af2.gen)
        T = vcat(af.T, af2.T)
    end
    AlgebraFrame{:a}(af.length, names, T, gen, vcat(af.transformations, af2.transformations), 
        af.offsets + af2.offsets)::AlgebraFrame{:a}
end

merge(af::AlgebraFrame, af2::AlgebraFrame; index::Int64 = af.length) = begin

end

merge!(af::AlgebraFrame, af2::AlgebraFrame; axis::Int64 = af.length + af.offsets) = begin
    for (e, name) in enumerate(af2.names)
        if name in af.names

        else

        end
    end

end


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
    [deleteat!(f.values[e], observation) for e in 1:length(f.values)]
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

function merge(f::AbstractFrame, af::AbstractFrame)

end

function merge!(f::AbstractFrame, af::AbstractFrame)

end

# filtering

function filter!(f::Function, af::AbstractDataFrame)
    N::Int64 = length(af.names)
    remove::Vector{Bool} = Vector{Bool}()
    for x in 1:length(af.values[1])
        row = FrameRow(af.names, [af.values[e][x] for e in 1:N])
        push!(remove, ~(f(row)))
    end
    for val in range(length(remove), 1, step = -1)
        if remove[val]
            deleteat!(af, val)
        end
    end
    af::AbstractDataFrame
end

# replace
function replace!(af::AbstractDataFrame, value::Any, with::Any)
    for column in 1:length(af.values)
        replace!(af.values[column], value, with)
    end
end

function replace!(a::AbstractArray, value::Any, with::Any)
    for value in 1:length(a)
        if value == with
            a[value] = with
        end
    end
end

function replace!(af::AbstractDataFrame, col::Int64, value::Any, with::Any)
    replace!(af.values[col], value, with)
end

function cast!(f::Function, af::AbstractAlgebraFrame, col::Int64, to::Type)
    af.T[col] = to
    af.gen[col] = f
end

function cast!(f::Function, af::AbstractAlgebraFrame, col::String, to::Type)
    f = findfirst(name -> name == col, af.names)
    cast!(f, af, f, to)
end

function cast!(a::AbstractArray, to::Type{<:Number})

end

function cast!(a::AbstractArray, to::Type{<:AbstractString})

end

function cast!(af::AbstractDataFrame, col::Int64, to::Type)

end

function cast!(af::AbstractDataFrame, col::String, to::Type)

end