"""
Created in December, 2023 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
This software is MIT-licensed.
### AlgebraFrames
`AlgebraFrames` provides *algebraic structures* to Julia in the form of the `Algebra` 
and `AlgebraFrame` types. These are used to store transformations on calculated 
values and preserve memory usage.
```julia
# algebra
# default initializer
alg = algebra(Int64, 25)

# use getindex?
alg[1]

alg = algebra(Int64, (5, 5))

alg[1:5, 1:1]

# or vect
[alg]

# set initializer
alg = algebra(Int64, 25) do e::Int64
    # each number will be the index
    e
end

# perform algebra

algebra!(alg) do vec::Vector{Int64}
    vec[1] = 5
    vec[3] = 15
end

[alg]
```
```julia
# frames
frame = algebra(20, "A" => Int64, "B" => String)

set_generator!(frame, "A") do e
    e # 1, 2, 3... 19, 20
end

algebra!(frame) do f
    filter!(row -> row["A"] < 15, f)
end

result = generate(f)
```
##### provides
```julia
# base algebra
AbstractAlgebra
length(a::AbstractAlgebra)
size(a::AbstractAlgebra)
Algebra{T <: Any, N <: Any}
copy(alg::AbstractAlgebra)
AlgebraVector{T}
show(io::IO, algebra::Algebra{<:Any, <:Any})
reshape(alg::Algebra{T, N}, new_length::Int64, new_width::Int64)
algebra_initializer
deleteat!(alg::AbstractAlgebra, n::Int64)
set_generator!
algebra
algebra!
generate
getindex(alg::AbstractAlgebra, dim::Int64)
getindex(alg::AbstractAlgebra, dim::Int64, dim2::Int64) 
getindex(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:1)
vect(alg::AbstractAlgebra)
eachrow(alg::AbstractAlgebra)
eachcol(alg::AbstractAlgebra)
vcat(origin::AbstractAlgebra, algebra::AbstractAlgebra ...)
hcat(origin::AbstractAlgebra, algebra::AbstractAlgebra ...)

# algebra frames
AbstractAlgebraFrame
AbstractTransformation
Transform
get_axis
copy(af::AbstractAlgebraFrame)
names(af::AbstractAlgebraFrame)
size(af::AbstractAlgebraFrame)
length(af::AbstractAlgebraFrame)
getindex(af::AbstractAlgebraFrame, column::AbstractString, r::UnitRange{Int64} = 1:af.length)
eachrow(af::AbstractAlgebraFrame)
framerows
eachcol(af::AbstractAlgebraFrame)
pairs(af::AbstractAlgebraFrame)
Dict(af::AbstractAlgebraFrame)
show(io::IO, algebra::AbstractAlgebraFrame)
AbstractFrame
AbstractDataFrame
FrameRow
Frame
length(f::AbstractFrame)
size(f::AbstractFrame)
names(f::AbstractFrame)
copy(f::Frame)
loop_rows
eachcol(f::AbstractDataFrame)
eachrow(f::AbstractDataFrame)
pairs(f::AbstractDataFrame)
getindex(f::AbstractFrame, cols::UnitRange{<:Integer})
getindex(f::AbstractFrame, cols::Vector{<:Integer})
getindex(f::AbstractFrame, ind::Integer, ind2::Integer)
getindex(f::AbstractFrame, ind::Integer, col::AbstractString)
getindex(f::AbstractFrame, ind::Integer, observations::UnitRange{Int64} = 1:length(f.values[1]))
getindex(f::AbstractFrame, name::AbstractString, observations::UnitRange{Int64} = 1:length(f.values[1]))
getindex(af::AbstractFrame, col::Any, at::Integer)
setindex!(f::AbstractFrame, ind::Integer, value::AbstractVector)
setindex!(f::AbstractFrame, value::AbstractVector, colname::AbstractString)
setindex!(f::AbstractFrame, row::Tuple, position::Int64)
setindex!(f::AbstractFrame, position::Int64, row::FrameRow)
setindex!(f::AbstractFrame, axis::Any, position::Int64, value::Any)
setindex!(f::AbstractDataFrame, to::Any, col::Any, n::Integer)
setindex!(f::AbstractDataFrame, to::AbstractVector, col::Any, n::UnitRange{Int64})
show(io::IO, frame::AbstractDataFrame)
display(io::IO, frame::AbstractDataFrame)
display(frame::AbstractDataFrame)
display(io::IO, mime::MIME{Symbol("text/html")}, frame::AbstractDataFrame)
html_string
head
tail

deleteat!(af::AbstractAlgebraFrame, row_n::Int64)
deleteat!(af::AbstractAlgebraFrame, row_n::UnitRange{Int64})
drop!
join!(f::Function, af::AbstractAlgebraFrame, col::Pair{String, DataType}; axis::Any = length(af.names))
join!(af::AbstractAlgebraFrame, col::Pair{String, DataType}; axis::Any = length(af.names))
join!(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame; axis::Any = length(af.names))
join(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame; axis::Any = length(af.names))
merge(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame)
merge!(af::AbstractAlgebraFrame, af2::AbstractAlgebraFrame)
join!(f::AbstractFrame, colname::AbstractString, T::Type, value::AbstractVector; axis::Any = length(f.names))
join!(f::AbstractFrame, f2::AbstractFrame; axis::Any = length(f.names))
join(f::AbstractFrame, f2::AbstractFrame; axis::Any = length(f.names))
drop!(f::AbstractFrame, col::Int64)
drop!(f::AbstractFrame, col::AbstractString)
deleteat!(f::AbstractFrame, observations::UnitRange{Int64})
deleteat!(f::AbstractFrame, observation::Int64)
eachrow(f::AbstractFrame)
framerows(f::AbstractDataFrame)
eachcol(f::AbstractFrame)
merge(f::AbstractFrame, af::AbstractFrame)
merge!(f::AbstractFrame, af::AbstractFrame)
filter!(f::Function, af::AbstractDataFrame)
replace!(af::AbstractDataFrame, value::Any, with::Any)
replace!(a::AbstractArray, rep_value::Any, with::Any)
replace!(af::AbstractDataFrame, col::Any, value::Any, with::Any)
cast!
cast
CastError
showerror(c::CastError)
```
"""
module AlgebraFrames

import Base: (:), getindex, setindex!, vect, Vector, show, length, size, pairs, reshape, eachcol, eachrow, filter!, filter
import Base: deleteat!, merge!, merge, join, Dict, hcat, replace, vcat, Dict, Matrix, Array, Vector, display, size, copy, names
import Base: replace!, showerror
include("algebra.jl")
include("frames.jl")

export AlgebraFrame, Algebra, AlgebraVector, algebra, algebra!, generate, drop!, join!, Frame, FrameRow, set_generator!
export framerows, cast!, head, tail
end # module Algia
