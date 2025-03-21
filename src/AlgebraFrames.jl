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
my_data = Int64:5:e::Int64 -> 5
# 'e' is the enumeration. if we do not want provide argument, we can generate 
# the entire thing at once:
my_data = Int16:5:() -> begin

end

# modifying data:
my_data:vector::Vector{Int64} -> begin
    vector[1] += 1
end

[my_data]

# multi-dimensional

my_data = Int16:(50, 50)

# peeking with `getindex`:
my_data[1:15]

# normalization example:

my_data = Float64:(50, 50):e -> randn()

using Statistics; std, mean

my_data:mat -> begin
    mu = mean(mat)
    sigma = std(mat)
    [(xbar - mu) / sigma for xbar in mat]
end

# AlgebraFrame:
mydata = 15:["name", "number", "directory", "group"]

# file reader example:

frame = ["name", "age", "birth month", "state"]:() -> begin
           names, age, bm, st = [], [], [], []
           open("samplefile.txt", "r") do o::IOStream
               while true
                   if eof(o)
                       break
                   end
                   line = readline(o)
                   splits = split(line, "|")
                   [push!(g, splits[e]) for (e, g) in enumerate([names, age, bm, st])]
               end
           end
           hcat(names, age, bm, st)
       end
```
"""
module AlgebraFrames

import Base: (:), getindex, setindex!, vect, Vector, show, length, size, pairs, reshape, eachcol, eachrow, filter!, filter

include("algebra.jl")
include("frames.jl")

export AlgebraFrame, Algebra, AlgebraVector
end # module Algia
