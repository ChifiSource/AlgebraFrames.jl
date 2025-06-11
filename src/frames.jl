#==| Hi friend, welcome to `algebraframes.jl`. Here is a map.
- AlgebraFrame
- AlgebraFrame creation (:)
- Algebra generation (vect, getindex, eachrow ...)
- FrameRow (row indexing/filtering)
==#

"""
```julia
abstract AbstractAlgebraFrame <: AbstractAlgebra
```
An `AbstractAlgebraFrame` is *similar* to `AbstractAlgebra`, but carries 
`names` and `types` alongside its generated values. Most algebraframes act as 
algebraic types for algebra vectors. All `AlgebraFrames` can be indexed by name or 
    column and row slices.
```julia
# consistencies
length::Int64
names::Vector{String}
T::Vector{Type}

copy(af::AbstractAlgebraFrame)
generate(af::AbstractAlgebraFrame)
names(af::AbstractAlgebraFrame)
size(af::AbstractAlgebraFrame)
length(af::AbstractAlgebraFrame)
algebra!(f::Function, af::AbstractAlgebraFrame, ...)
set_generator!(f::Function, af::AlgebraFrame, ...)
eachrow(af::AlgebraFrame)
framerows(af::AbstractAlgebraFrame)
eachcol(af::AbstractAlgebraFrame)
pairs(af::AbstractAlgebraFrame)
Dict(af::AbstractAlgebraFrame)
cast!(f::Function, af::AbstractAlgebraFrame, ...)
merge!(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame)
merge(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame)
join(af::AbstractAlgebraFrame, ...)
join!(af::AbstractAlgebraFrame, ...)
drop!(af::AlgebraFrame, ...)
deleteat!(af::AlgebraFrame, ...)
head(af::AbstractAlgebraFrame, headlength::Int64 = 5)
```
- See also: `Frame`, `AlgebraFrame`, `Transform`, `algebra`, `algebra!`, `drop!`, `cast!`
"""
abstract type AbstractAlgebraFrame <: AbstractAlgebra end

"""
```julia
abstract AbstractTransformation <: Any
```
An `AbstractTransformation` is used to represent a transformation taking place 
across a certain set of columns.
- See also: `AlgebraFrame`, `Transform`, `algebra!`, `drop!`, `Frame`
"""
abstract type AbstractTransformation end

"""
```julia
mutable struct Transform <: AbstractTransformation
```
- `col`**Vector{Int16}**
- `f`**Function**

The `Transform` is the standard type of `AbstractTransformation`. `col` stores 
the columns that are meant to perform the transformation, whereas `f` is the 
transformation itself; a `Function` that takes a `Frame`. These are held in 
`AlgebraFrame.transformations` and called whenever the `AlgebraFrame` is generated.
```julia
Transform(::Vector{Int64}, ::Function)
```
- See also: `AlgebraFrame`, `Frame`, `algebra!`, `set_generator!`
"""
mutable struct Transform <: AbstractTransformation
    col::Vector{Int16}
    f::Function
end

"""
```julia
mutable struct AlgebraFrame{T <: Any}
```
- `length`**::Int64**
- `names`**Vector{String}**
- `T`**::Vector{Type}**
- `gen`**::Vector{Function}**
- `transformations`**::Vector{Transform}**
- `offsets`**::Int64**

The `AlgebraFrame` is an algebraic data-structure that represents the 
`AlgebraFrames.Frame` type. An `AlgebraFrame` is typically *created* using the 
`algebra` function and modified using the `algebra!` function. To create an `AlgebraFrame`, 
    we provide the `length` of our observations alongside pairs of names and types. 
    This can then be modified inside of a `Function` as a `Frame` using `algebra!`.
```julia
af = algebra(25, "col1" => Int64, "col2" => Float64)

algebra!(af) do frame::Frame
    af["col1"][1] = 5
end
# indexing for an af is done column-first
# the column may be provided by name or axis.
# note that it will generate the entire column, but only 
# transform and allocate `1:5`.
af["col1", 1:5][1:5]

af["col1"]

af[1:2, 1:5]
```
```julia
AlgebraFrame{T}(n::Integer, names::Vector{String}, types::Vector{Type}, 
    gen::Vector{Function}, transforms::Vector{Transform}, offset::Number)
AlgebraFrame(n::Int64, pairs::Pair{<:Any, DataType} ...; T::Symbol = :a)
```
Like `Algebra`, the `AlgebraFrame` primarily uses `Base` method bindings. Here is an exhaustive list:
```julia
copy(af::AlgebraFrame)
generate(af::AbstractAlgebraFrame)
names(af::AbstractAlgebraFrame)
size(af::AbstractAlgebraFrame)
length(af::AbstractAlgebraFrame)
eachrow(af::AbstractAlgebraFrame)
framerows(af::AbstractAlgebraFrame)
eachcol(af::AbstractAlgebraFrame)
pairs(af::AbstractAlgebraFrame)
Dict(af::AbstractAlgebraFrame)
show(io::IO, algebra::AbstractAlgebraFrame)
head(af::AbstractAlgebraFrame, headlength::Int64 = 5)
tail(af::AbstractAlgebraFrame, len::Int64 = 5)
deleteat!(af::AlgebraFrame, ...)
drop!(af::AlgebraFrame, ...)
join!(f::Function, af::AbstractAlgebraFrame, col::Pair{String, DataType}; axis::Any = length(af.names))
join!(af::AbstractAlgebraFrame, ...)
join(af::AbstractAlgebraFrame, ...)
merge(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame)
merge!(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame)
cast!(f::Function, af::AbstractAlgebraFrame, col::Int64, to::Type)
cast!(af::AbstractAlgebraFrame, col::Any, to::Type{<:Any})
```
- See also: `Algebra`, `algebra`, `algebra!`, `set_generator!`, `Frame`, `framerows`
"""
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

copy(af::AlgebraFrame) = begin
    AlgebraFrame{typeof(af).parameters[1]}(af.length, af.names, af.T, af.gen, 
    af.transformations, af.offsets)
end

generate(af::AbstractAlgebraFrame) = begin 
    values = [begin
        generate(Algebra{af.T[col]}(af.gen[col], af.length))
    end for col in 1:length(af.names)]
    newf = Frame(af.names, af.T, values)
    for transform in af.transformations
        transform.f(newf)
    end
    newf::Frame
end

names(af::AbstractAlgebraFrame) = af.names

size(af::AbstractAlgebraFrame) = (af.length, length(af.names))

length(af::AbstractAlgebraFrame) = af.length + af.offsets

algebra(n::Int64, prs::Pair{<:Any, DataType} ...; keys ...) = AlgebraFrame(n, prs ...; keys ...)

algebra!(f::Function, af::AbstractAlgebraFrame) = begin
    push!(af.transformations, 
        Transform([e for e in 1:length(af.names)], f))
end

algebra!(f::Function, af::AbstractAlgebraFrame, name::Int64 ...) = begin
    push!(af.transformations, Transform([name ...], f))
end

algebra!(f::Function, af::AbstractAlgebraAlgebraFrame, names::String ...) = begin
    positions = [findfirst(n -> n == name, af.names) for name in names]
    algebra!(f, af, positions ...)
    nothing
end

algebra!(f::Function, af::AbstractAlgebraFrame, names::UnitRange{Int64}) = begin
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
            curr_names = [af.names[e] for e in transform.col]
            curr_types = [af.T[e] for e in transform.col]
            curr_vals = Vector{AbstractVector}([Vector{af.T[column_n]}([af.gen[column_n](e) for e in 1:af.length]) for column_n in 1:length(af.names)])
            deleteat!(curr_vals, position)
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

eachrow(af::AbstractAlgebraFrame) = begin
    eachrow(generate(af))
end

"""
```julia
framerows(...) -> ::Vector{FrameRow}
```
Creates *frame rows* from an `AlgebraFrame` or a `Frame`. Similar to `eachrow`, except 
that each row is its own 'miniature frame' instead of coming in the form of a `Vector`.
```julia
framerows(af::AbstractAlgebraFrame) -> ::Vector{FrameRow}
framerows(f::AbstractDataFrame) -> ::Vector{FrameRow}
```
```julia
af = algebra(20, "A" => Int64, "B" => Int64)

set_generator!(af, "A") do e
    rand(1:50)
end

rows = framerows(af)

rows[1]["A"] # a random number between 1 and 50
algebra!(af) do frame
    # used for `filter!`, for example
    filter!(row -> row["A"] < 25, frame)
end

generate(af)
```
"""
function framerows end

framerows(af::AbstractAlgebraFrame) = begin
    framerows(generate(af))
end

eachcol(af::AbstractAlgebraFrame) = begin
    generate(af).values
end

function pairs(af::AbstractAlgebraFrame)
    names = af.names
    generated = generate(af)
    [begin 
        names[e] => generated.values[e]
    end for e in 1:length(af.names)]
end

Dict(af::AbstractAlgebraFrame) = Dict(pairs(af) ...)

function show(io::IO, algebra::AbstractAlgebraFrame)
    colnames = join((n for n in algebra.names), " | ")
    println(io, 
        "frame $(algebra.length + algebra.offsets) x $(length(algebra.names)) | $colnames")
end

"""
```julia
abstract AbstractFrame
```
The `AbstractFrame` is the base `Frame` type, which is indexable by names and ranges 
just like the `AlgebraFrame`. The biggest deviation from the `AlgebraFrame` is 
the presence of `AbstractFrame.values`. Crucially, an `AbstractFrame` is structured to hold 
a single observation or multiple observations, whereas an `AbstractDataFrame` is structured 
explicitly to hold multiple observations.
```julia
# consistencies
names::Vector{String}
values::Vector{Any}
```
- See also: `algebra`, `AbstractDataFrame`, `Frame`, `AlgebraFrame`, `framerows`, `FrameRow`
"""
abstract type AbstractFrame end

"""
```julia
abstract AbstractDataFrame <: AbstractFrame
```
An `AbstractDataFrame` is an `AbstractFrame` that is designed to hold 
multiple observations.
```julia
# consistencies
names::Vector{String}
types::Vector{Type}
values::Vector{Vector{<:Any}}
```
- See also: `AbstractFrame`, `FrameRow`, `framerows`, `AlgebraFrame`, `Algebra`
"""
abstract type AbstractDataFrame <: AbstractFrame end

"""
```julia
mutable struct FrameRow <: AbstractFrame
```
- `names`**Vector{String}**
- `values`**Vector{Any}**

A `FrameRow` is an individual row of a `Frame`. Like a `Frame`, the `FrameRow` 
is indexable by name. We can access all frame rows of a given `Frame` or 
`AlgebraFrame` by using the `framerows` function.
```julia
f::Frame = generate(algebra(20, "col" => Int64))
for row in framerows(f)
    if row["col"] == 0
        println("holding default fill value")
    end
end
```
```julia
FrameRow(::Vector{String}, ::Vector{Any})
```
- See also: `Frame`, `framerows`, `eachcol`, `eachrow`, `loop_rows`, `tail`
"""
mutable struct FrameRow <: AbstractFrame
    names::Vector{String}
    values::Vector{Any}
end

"""
```julia
mutable struct Frame <: AbstractFrame
```
- `names`**::Vector{String}**
- `types`**::Vector{Type}**
- `values`**::Vector{Vector{<:Any}}**

The `Frame` is the generated equivalent of the `AlgebraFrame`. This structure is 
indexable by names, integers, and ranges just like the `AlgebraFrame`. We create a 
`Frame` by calling `generate` on an `AlgebraFrame`. The `Frame` will also be provided to 
`algebra!` transformation functions as its only argument when adding transformations 
to an `AlgebraFrame`.
```julia
Frame(::Vector{String}, ::Vector{Type}, ::Vector{Vector{<:Any}})
```
```julia
af = algebra(10, "one" => Int64, "two" => String, "three" => Float64)

algebra!(af) do f::Frame
    f["one", 1] = 5
end

af["one"]

gen::Frame = generate(af)

filter!(row -> row["one"] != 5, gen)
```
- See also: `AbstractDataFrame`, `AbstractFrame`, `AlgebraFrame`, `algebra!`, `framerows`, `head`
"""
mutable struct Frame <: AbstractDataFrame
    names::Vector{String}
    types::Vector{Type}
    values::Vector{Vector{<:Any}}
end

length(f::AbstractFrame) = length(f.values[1])

size(f::AbstractFrame) = (length(f.values[1]), length(f.names))

names(f::AbstractFrame) = f.names

copy(f::Frame) = Frame(f.names, f.types, f.values)

"""
```julia
loop_rows(f::Function, af::AbstractDataFrame) -> ::Nothing
```
Iteratively loops the `FrameRows` of a given `AbstractDataFrame`, calling `f` on 
each row as it loops. This is a faster and more efficient way of looping framerows with 
`framerows`.
```julia
f = generate(algebra(20, "A" => String))
loop_rows(f) do row
    @info row["A"]
end
```
- See also: `framerows`, `Frame`, `AlgebraFrame`, `algebra`, `generate`
"""
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
    [f.names[e] => f.values[e] for e in 1:length(f.names)]
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

getindex(af::AbstractFrame, col::Any, at::Integer) = begin
    if typeof(col) <: AbstractString
        col = findfirst(n -> n == col, af.names)
    end
    getindex(af, col, at:at)[at]
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

function setindex!(f::AbstractFrame, value::AbstractVector, colname::String)
    position = findfirst(x -> x == colname, names)
    if isnothing(position)
        # (adds a new column)
        T::Type = typeof(value).parameters[1]
        join!(f, colname, T, value)
        return(f)::AbstractFrame
    end
    setindex!(f, position, value)::AbstractFrame
end


function setindex!(f::AbstractFrame, row::Tuple, position::Int64)
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

function setindex!(f::AbstractDataFrame, to::Any, col::Any, n::Integer)
    if typeof(col) <: AbstractString
        col = findfirst(n -> n == col, f.names)
    end
    f.values[col][n] = to
end

function setindex!(f::AbstractDataFrame, to::AbstractVector, col::Any, n::UnitRange{Int64})
    if typeof(col) <: AbstractString
        col = findfirst(n -> n == col, f.names)
    end
    len = length(f.values[col])
    finisher = maximum(n)
    starter = minimum(n)
    if minimum(n) > 1 && finisher != len
        f.values[col] = vcat(f.values[col][1:to - 1], to, f.values[col][finisher + 1:len])
    elseif finisher == len
        f.values[col] = vcat(f.values[col][1:to - 1], to)
    else
        f.values[col] = vcat(to, f.values[col][finisher + 1:len])
    end

    f::AbstractDataFrame
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

function html_string(frame::Frame, headlength::Int64 = 5, start::Integer = 1)
    header = "<table><tr>" * join("<th>$name</th>" for name in frame.names) * "</tr>"
    for row in eachrow(frame)[start:headlength]
        header = header * "<tr>" * join("<td>$val</td>" for val in row) * "</tr>"
    end
    header * "</table>"
end

"""
```julia
head(args ...) -> ::Nothing
```
Displays the `head`, or first `n` values in an `AbstractDataFrame` or `AbstractAlgebraFrame`. 
The inverse of `tail`.
```julia
head(af::AbstractAlgebraFrame, headlength::Int64 = 5)
head(f::Frame, headlength::Int64 = 5)
```
- See also: `tail`, `Frame`, `FrameRow`, `algebra!`, `AlgebraFrames`, `set_generator!`
"""
function head end

"""
```julia
tail(args ...) -> ::Nothing
```
Displays the `tail`, or last `n` values in an `AbstractDataFrame` or `AbstractAlgebraFrame`. 
The inverse of `head`.
```julia
tail(af::AbstractAlgebraFrame, len::Int64 = 5)
tail(f::Frame, len::Int64 = 5)
```
- See also: `head`, `Frame`, `FrameRow`, `algebra!`, `cast!`, `set_generator!`
"""
function tail end

head(af::AbstractAlgebraFrame, headlength::Int64 = 5) = head(generate(af), headlength)

tail(af::AbstractAlgebraFrame, len::Int64 = 5) = tail(generate(af), length(f) = len)

head(f::Frame, headlength::Int64 = 5)  = display("/text/html", html_string(f, headlength))

tail(f::Frame, len::Int64 = 5) = display("/text/html", html_string(f, headlength, length(f) - len))

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

"""
```julia
drop!(af::Any, ...) -> ::Any
```
Drops a **column** from an `AlgebraFrame` or `Frame` by name or axis. 
For removing observations, use `deleteat!`
```julia
drop!(af::AlgebraFrame, axis::Int64)
drop!(af::AlgebraFrame, col::String)
```
```julia
drop!(f::AbstractFrame, col::Int64)
drop!(f::AbstractFrame, col::AbstractString)
```
- See also: 
"""
function drop! end

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

join!(f::Function, af::AbstractAlgebraFrame, col::Pair{String, DataType}; axis::Any = length(af.names)) = begin
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

join!(af::AbstractAlgebraFrame, col::Pair{String, DataType}; axis::Any = length(af.names)) = begin
    join!(algebra_initializer(col[2]), af, col, axis = axis)
end

join!(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame; axis::Any = length(af.names)) = begin
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

join(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame; axis::Any = length(af.names)) = begin
    if typeof(axis) <: AbstractString
        axis = findfirst(n::String -> n == axis, f.names)
    end
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

merge(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame) = begin
    cop = copy(af)
    cop.length += af2.length
    cop.offsets += af2.offsets
    push!(cop.transformations, af2.transformations ...)
    cop
end

merge!(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame) = begin
    af.length = af.length + af2.length
    af.offsets = af.offsets + af2.offsets
    push!(af.transformations, af2.transformations ...)
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

function join!(f::AbstractFrame, f2::AbstractFrame; axis::Any = length(f.names))
    n = length(f.names)
    if typeof(axis) <: AbstractString
        axis = findfirst(n::String -> n == axis, f.names)
    end
    if axis < n
        f.names = vcat(f.names[1:axis], f2.names, f.names[axis + 1:end])
        f.values = vcat(f.values[1:axis], f2.values, f.values[axis + 1:end])
        f.types = vcat(f.T[1:axis], f2.types, f.types[axis + 1:end])
    else
        push!(f.names, f2.names ...)
        push!(f.values, f2.values ...)
        push!(f.types, f2.types ...)
    end
    f::AbstractFrame
end

function join(f::AbstractFrame, f2::AbstractFrame; axis::Any = length(f.names))
    if typeof(axis) <: AbstractString
        axis = findfirst(n::String -> n == axis, f.names)
    end
    newf = copy(f)
    if axis < n
        newf.names = vcat(f.names[1:axis], f2.names, f.names[axis + 1:end])
        newf.values = vcat(f.values[1:axis], f2.values, f.values[axis + 1:end])
        newf.types = vcat(f.T[1:axis], f2.types, f.types[axis + 1:end])
    else
        push!(newf.names, f2.names ...)
        push!(newf.values, f2.values ...)
        push!(newf.types, f2.types ...)
    end
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
        [f.values[n][x] for n in 1:length(f.values)]
    end for x in 1:length(f.values[1])]
end

function framerows(f::AbstractDataFrame)
    [begin
        FrameRow(f.names, [f.values[n][x] for n in 1:length(f.values)]) 
    end for x in 1:length(f.values[1])]::Vector{FrameRow}
end

function eachcol(f::AbstractFrame)
    f.values::Vector{<:AbstractVector}
end


function merge(f::AbstractFrame, af::AbstractFrame)
    n = 0
    cop = copy(f)
    for coln in 1:length(af.names)
        name = af.names[coln]
        position = findfirst(colname -> colname == name, f.names)
        if isnothing(position)
            continue
        end
        n += 1
        cop.values[position] = vcat(cop.values[position], af.values[coln])
    end
    if n > 0 && n != length(af.names)
        lens = [length(col) for col in cop.values]
        set_len = lens[1]
        f = findfirst(val -> val != set_len, cop.values)
        if ~(isnothing(f))
            throw("cannot merge frames, as this will create unequal columns.")
        end
    end
    return(cop)
end

function merge!(f::AbstractFrame, af::AbstractFrame)
    n = 0
    saved_values = copy(f.values)
    for coln in 1:length(af.names)
        name = af.names[coln]
        position = findfirst(colname -> colname == name, f.names)
        if isnothing(position)
            continue
        end
        n += 1
        f.values[position] = vcat(f.values[position], af.values[coln])
    end
    if n > 0 && n != length(names)
        lens = [length(col) for col in f.values]
        set_len = lens[1]
        f = findfirst(val -> val != set_len, f.values)
        if ~(isnothing(f))
            f.values = saved_values
            throw("cannot merge frames, as this will create unequal columns.")
        end
    end
    saved_values = nothing
    return(f)::AbstractFrame
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
        af.values[column] = replace!(af.values[column], value, with)
    end
end

function replace!(a::AbstractArray, rep_value::Any, with::Any)
    for value in 1:length(a)
        if a[value] == rep_value
            a[value] = with
        end
    end
    a
end

function replace!(af::AbstractDataFrame, col::Any, value::Any, with::Any)
    if typeof(col) <: AbstractString
        col = findfirst(val -> val == col, af.names)
    end
    af.values[col] = replace!(af.values[col], value, with)
end

"""
```julia
cast!(...) -> ::Nothing
```
`cast!` is used on an `AbstractDataFrame` or an `AbstractAlgebraFrame` to *cast* columns 
to new types.
```julia
cast!(f::Function, af::AbstractAlgebraFrame, col::Int64, to::Type)
cast!(af::AbstractAlgebraFrame, col::Any, to::Type{<:Any})
cast!(f::Function, af::AbstractAlgebraFrame, col::String, to::Type)
```
```julia
cast!(af::AbstractDataFrame, col::Int64, to::Type)
cast!(af::AbstractDataFrame, col::String, to::Type)
```
- See also: `generate`, `deleteat!`, `merge!`, `replace!`, `algebra`, `algebra!`
"""
function cast! end

function cast!(f::Function, af::AbstractAlgebraFrame, col::Int64, to::Type)
    af.T[col] = to
    af.gen[col] = f
end

cast!(af::AbstractAlgebraFrame, col::Any, to::Type{<:Any}) = cast!(algebra_initializer(to), af, col, to)

function cast!(f::Function, af::AbstractAlgebraFrame, col::String, to::Type)
    found = findfirst(name -> name == col, af.names)
    cast!(f, af, found, to)
end

function cast(a::AbstractArray, to::Type{<:Number})::AbstractArray
    if typeof(a[1]) <: AbstractString
        return([begin
            parse(to, val) 
        end for val in a])
    end
    [begin
        to(val) 
    end for val in a]
end

function cast(a::AbstractArray, to::Type{<:Any})
    [to(val) for val in a]
end

function cast(a::AbstractArray, to::Type{<:AbstractString})
    [to(string(val)) for val in a]
end

function cast!(af::AbstractDataFrame, col::Int64, to::Type)
    af.types[col] = to
    af.values[col] = cast(af.values[col], to)
end

function cast!(af::AbstractDataFrame, col::String, to::Type)
    f = findfirst(name -> name == col, af.names)
    if isnothing(f)
        throw("future error")
    end
    cast!(af, f, to)
end