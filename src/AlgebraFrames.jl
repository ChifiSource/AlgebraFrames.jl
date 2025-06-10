"""
Created in December, 2023 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
This software is MIT-licensed.
### AlgebraFrames
`AlgebraFrames` provides *structural algebra* to Julia in the form of the `Algebra` 
and `AlgebraFrame` types. These are used to store transformations on calculated 
values and preserve memory usage.
```julia
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

```
"""
module AlgebraFrames

import Base: (:), getindex, setindex!, vect, Vector, show, length, size, pairs, reshape, eachcol, eachrow, filter!, filter
import Base: deleteat!, merge!, merge, join, Dict, hcat, replace, vcat, Dict, Matrix, Array, Vector, display, size, copy, names
import Base: replace!
include("algebra.jl")
include("frames.jl")

export AlgebraFrame, Algebra, AlgebraVector, algebra, algebra!, generate, drop!, join!, Frame, FrameRow, set_generator!
export framerows, cast, cast!
end # module Algia
