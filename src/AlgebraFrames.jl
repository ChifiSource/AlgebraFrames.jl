"""
Created in December, 2023 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### AlgebraFrames
`AlgebraFrames` provides a *dynamic* and extensible API for out-of-memory
programming inside of Julia. This is facilitated through the `Algebra` and 
`AlgebraFrame` types. This project provides the `Algebra`/`AlgebraVector`, as well
as the `AlgebraFrame`.
```julia
# vector of length 15:
my_data = Int64:15

actual_vector = [my_data]

println(sizeof(actual_vector)) # 15 * 8 bytes, 120 bytes

println(sizeof(my_data)) # 16 bytes

# (reduction of 118 octets!)

# custom initializer:
my_data = Int64:e::Int64 -> 5
# 'e' is the enumeration.

# modifying data:
my_data:vector::Vector{Int64} -> begin
    vector[1] += 1
end

[my_data]

# multi-dimensional

my_data = Int16:(50, 50)

# peeking with `getindex`:
my_data[1:15]

# AlgebraFrame:
mydata = 15:["name", "number", "directory", "group"]

# consider all of these values were stored in files by the employee's names:
dirpath = "texts/employeeinfo"
n_files = length(readdir(dirpath))

mydata = 15:["name", "number", "directory", "group"]:e -> begin
    # we assemble each row ourselves, `x` is the row
end
```
"""
module AlgebraFrames

import Base: (:), getindex, setindex!, vect, Vector, show, length, size, pairs, reshape

include("algebra.jl")
include("frames.jl")

export AlgebraFrame, Algebra, AlgebraVector
end # module Algia
