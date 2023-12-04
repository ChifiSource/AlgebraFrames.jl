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

include("algebra.jl")
include("algebraframes.jl")

export AlgebraFrame, Algebra, AlgebraVector
end # module Algia
