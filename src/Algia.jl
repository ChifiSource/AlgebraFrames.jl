"""
Created in December, 2023 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### Algia

"""
module Algia
import Base: (:), getindex, setindex!, vect, Vector, show, length

"""
### abstract type **AbstractAlgebra**

### Consistencies
- pipe::Vector{AlgebraIndex}
- length::Int64
```
"""
abstract type AbstractAlgebra end

include("algebra.jl")
include("algebraframes.jl")


length(a::AbstractAlgebra) = a.length::Int64
export AlgebraFrame, Algebra, AlgebraVector
end # module Algia
