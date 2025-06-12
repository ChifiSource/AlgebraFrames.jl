#==| Hi friend, welcome to `algebra.jl`. Here is a map.
- Algebra
- Algebra Base
- Algebra creation (:)
- Algebra generation (vect, getindex, eachrow ...)
==#
"""
```julia
abstract type **AbstractAlgebra**
```
Consistencies
- pipe::Vector{Function}
- length::Int64
- `offsets`::Any
```
`AbstractAlgebra` is an algebraic type that holds data outside of memory. These types can be generated using 
`AlgebraFrames.generate` or `generate`, they also have a `length` and a pipeline of functions stored within them. 
`offsets` is used to measure any changes in dimensionality that come from certain operations -- such as using 
the `deleteat!` function directly on the `Algebra` itself. Also note the following `method` bindings:
```julia
length(a::AbstractAlgebra)
size(a::AbstractAlgebra)
copy(alg::AbstractAlgebra)
reshape(alg::AbstractAlgebra, news::Tuple{Int64, Int64})
set_generator!(f::Function, alg::AbstractAlgebra)
getindex(alg::AbstractAlgebra, dim::Int64)
getindex(alg::AbstractAlgebra, dim::Int64, dim2::Int64)
getindex(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:1)
eachrow(alg::AbstractAlgebra)
eachcol(alg::AbstractAlgebra)
```
"""
abstract type AbstractAlgebra end

length(a::AbstractAlgebra) = (a.length::Int64 + a.offsets[1])

size(a::AbstractAlgebra) = (a.length + a.offsets[1], typeof(a).parameters[2] + a.offsets[2])::Tuple{Int64, Int64}

"""
```julia
mutable struct Algebra{T <: Any, N <: Any} <: Algebra
```
- `pipe`**::Vector{Function}**
- `length`**::Int64**
- `offsets`**::Pair{Int64, Int64}**

`Algebra` is a structural algebra type that represent's `Base`'s `Array` type. This 
also includes an aliased `AlgebraVector` type. `Algebra` is created using *specific* 
methods of the `algebra` function.
```julia
algebra(T::Type{<:Any}, n::Int64, f::Function = algebra_initializer(T))
algebra(f::Function, T::Type{<:Any}, dim::Tuple)
algebra(f::Function, T::Type{<:Any} = methods(f)[1].sig.parameters[1], dim::Int64 = 1)
algebra(f::Function, T::Type{<:Any} = methods(f)[1].sig.parameters[1], dim::Int64 = 1)
algebra(vec::AbstractArray)
```
This allows us to create `algebra` of any length *with or without* an initializer, as well 
as allowing us to create *algebraic copies* of arrays using the `AbstractArray` dispatch.
```julia
alg = algebra(Int64, 20)
alg = algebra(Int64, 5) do
    [1, 2, 3, 4, 5]
end
alg2 = algebra(Int64, 5) do e
    e
end

alg3 = algebra([1, 2, 3, 4, 5])

[alg] == [alg2] == alg3
```
From here, we use `algebra!` to add transformations, and index our `Algebra` or vectorize
 to generate.
```julia
alg2 = algebra(Int64, 5) do e
    e
end

algebra!(alg2) do vec::Vector{Int64}
    vec[1] = 15
end

alg[1] == 15
```
`Algebra` is primarily bound through `Base` methods. Here is a comprehensive list:
```julia
length(a::AbstractAlgebra)
size(a::AbstractAlgebra)
copy(alg::AbstractAlgebra)
show(io::IO, algebra::Algebra{<:Any, <:Any})
reshape(alg::Algebra{T, N}, new_length::Int64, new_width::Int64)
deleteat!(alg::AbstractAlgebra, n::Int64)
getindex(alg::AbstractAlgebra, dim::Int64)
getindex(alg::AbstractAlgebra, dim::Int64, dim2::Int64)
getindex(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:1)
vect(alg::AbstractAlgebra)
eachrow(alg::AbstractAlgebra)
eachcol(alg::AbstractAlgebra)
vcat(origin::AbstractAlgebra, algebra::AbstractAlgebra ...)
hcat(origin::AbstractAlgebra, algebra::AbstractAlgebra ...)
```
- See also: `set_generator!`, `AlgebraFrame`, `AlgebraFrames`, `algebra`, `algebra!`
"""
mutable struct Algebra{T <: Any, N <: Any} <: AbstractAlgebra
    pipe::Vector{Function}
    length::Int64
    offsets::Pair{Int64, Int64}
    Algebra{T, N}(pipe::Vector{Function}, length::Int64, offsets::Pair{Int64, Int64}) where {T <: Any, N <: Any}= new{T, N}(pipe, 
        length, offsets)
    Algebra{T, N}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where {T <: Any, N <: Any} = begin
        funcs::Vector{Function} = Vector{Function}([f])
        new{T, N}(funcs, length, 0 => 0)::AbstractAlgebra
    end
    function Algebra{T}(algebra::Algebra{<:Any, <:Any}) where T <: Any
        new{T, typeof(algebra).parameters[2]}(algebra.pipe, algebra.length, 0 => 0)
    end
end

function copy(alg::AbstractAlgebra)
    params = typeof(alg).parameters
    Algebra{params[1], params[2]}(alg.pipe, alg.length, alg.offsets)
end

Algebra{T}(f::Function = x -> 0, length::Int64 = 1, width::Int64 = 1) where T <: Any = begin
    Algebra{T, width}(f, length)::AbstractAlgebra
end

Algebra{T}(f::Function, dim::Tuple) where T <: Any = begin
    if length(dim) == 1
        Algebra{T}(f, dim[1], 1)
    elseif length(dim) == 2
        Algebra{T}(f, dim[1], dim[2])
    end
end

function Algebra(vec::AbstractArray)
    T = typeof(vec).parameters[1]
    Algebra{T, 1}(length(vec)) do e
        vec[e]
    end::AbstractAlgebra
end

const AlgebraVector{T} = Algebra{T,1}

function show(io::IO, algebra::Algebra{<:Any, <:Any})
    cols, rows = typeof(algebra).parameters[2], length(algebra)
    T = typeof(algebra).parameters[1]
    println(io, "$T $(rows)x$cols")
end

function reshape(alg::Algebra{T, N}, new_length::Int64, new_width::Int64) where {T, N}
	# Ensure reshaping doesn't change total number of elements
	total_old = alg.length * N
	total_new = new_length * new_width
	if total_old != total_new
		throw(ArgumentError("Cannot reshape algebra of size ($alg.length, $N) to ($new_length, $new_width)"))
	end
	return Algebra{T, new_width}(alg.pipe, new_length, alg.offsets)
end

"""
```julia
algebra_initializer(::Type) -> ::Function
```
Creates a *generator* for common data-types, usually called as a default for a provided type.
```julia
algebra_initializer(T::Type{<:Integer}) = x -> T(0)
algebra_initializer(T::Type{Int64}) = x -> 0
algebra_initializer(T::Type{<:AbstractFloat}) = x -> T(0.0)
algebra_initializer(T::Type{Float64}) = x -> 0.0
algebra_initializer(T::Type{String}) = x -> "null"
```
- See also: `set_generator!`, `Algebra`, `AlgebraFrame`, `drop!`, `algebra`, `algebra!`
"""
function algebra_initializer end

algebra_initializer(T::Type{<:Integer}) = x -> T(0)
algebra_initializer(T::Type{Int64}) = x -> 0
algebra_initializer(T::Type{<:AbstractFloat}) = x -> T(0.0)
algebra_initializer(T::Type{Float64}) = x -> 0.0
algebra_initializer(T::Type{String}) = x -> "null"

deleteat!(alg::AbstractAlgebra, n::Int64) = begin
    algebra!(alg) do res
        deleteat!(res, n)
    end
    alg.offsets = alg.offsets[1] - 1 => alg.offsets[2]
end

"""
```julia
set_generator!(f::Function, alg::AbstractAlgebra, args ...) -> ::Nothing
```
Sets the *generator*, or the first function that is called, of a given algebra. Generators for `Algebra` 
(as opposed to an `AbstractAlgebraFrame`,) can take either the enumeration, `Int64`, or nothing as an argument. In 
the case of nothing, we will need to generate the entire array in a single function call and return it. When providing a generator 
for an `AlgebraFrame`'s column, our generator will *always* take an `Int64`.
```julia
# algebra
set_generator!(f::Function, alg::AbstractAlgebra)
# algebraframe
set_generator!(f::Function, af::AlgebraFrame, col::String)
set_generator!(f::Function, af::AlgebraFrame, col::Integer)
```
- See also: `algebra_initializer`, `Algebra`, `algebra!`, `algebra`
"""
function set_generator! end

set_generator!(f::Function, alg::AbstractAlgebra) = alg.pipe[1] = f

# creation
"""
```julia
algebra(args ...) -> ::Algebra{<:Any, <:Any}
```
Creates both the `Algebra` and `AlgebraFrame` types using different bindings. 
Relatively straightforward to use; for `Algebra`, provide a `Function` or don't.
```julia
alg = algebra(Int64, 5)
alg = algebra(Int64, (5, 5))
alg = algebra(Int64, (5, 2)) do e
    e - 1
end
```
For an `AlgebraFrame`, provide a `length` and a type for each column:
```julia
af = algebra(20, "A" => Float64, "B" => Int64, "C" => String)
```

```julia
# algebra
algebra(T::Type{<:Any}, n::Int64, f::Function = algebra_initializer(T))
algebra(vec::AbstractArray)
algebra(f::Function, T::Type{<:Any}, dim::Tuple
algebra(f::Function, T::Type{<:Any} = methods(f)[1].sig.parameters[1], dim::Int64 = 1)
# algebraframe
algebra(n::Int64, prs::Pair{<:Any, DataType} ...; keys ...)
```
- See also: `algebra!`, `set_generator!`, `AlgebraFrame`, `Algebra`, `AbstractAlgebra`
"""
function algebra end

algebra(T::Type{<:Any}, n::Int64, f::Function = algebra_initializer(T)) = Algebra{T}(f, n, 1)::Algebra{T, 1}

function algebra(T::Type{<:Any}, dim::Tuple, f::Function = algebra_initializer(T))
    Algebra{T}(f, dim)::Algebra{T, dim[2]}
end

algebra(vec::AbstractArray) = Algebra(vec)

function algebra(f::Function, T::Type{<:Any}, dim::Tuple)
    Algebra{T}(f, dim)::Algebra{T, dim[2]}
end

function algebra(f::Function, T::Type{<:Any} = methods(f)[1].sig.parameters[1], dim::Int64 = 1)
    Algebra{T}(f, dim, 1)::Algebra{T, 1}
end

algebra(vec::Vector{<:Any}) = Algebra(vec)

"""
```julia
algebra!(f::Function, alg::AbstractAlgebra, args ...) -> ::Nothing
```
Adds `f` to `alg`'s set of transformations.
```julia
# algebra
algebra!(f::Function, alg::AbstractAlgebra)
# algebraframe
algebra!(f::Function, af::AlgebraFrame)
algebra!(f::Function, af::AlgebraFrame, name::Int64 ...)
algebra!(f::Function, af::AlgebraFrame, names::String ...) 
algebra!(f::Function, af::AlgebraFrame, names::UnitRange{Int64})
```
- See also: `algebra`, `Frame`, `AlgebraFrame`, `Algebra`, `AlgebraFrames`
"""
function algebra! end

algebra!(f::Function, alg::AbstractAlgebra) = push!(alg.pipe, f)

"""
```julia
generate(alg::AbstractAlgebra) -> ::Any
```
Generates an `AbstractAlgebra` into its equivalent type. Note that `generate` 
**works differently** between `Algebra` and the `AlgebraFrame`. For `Algebra`, 
`generate` will only build the base shape of the `Array` using the initializer. 
Instead, for an `Algebra` use `vect`. When we call `generate` on an `AlgebraFrame`, 
however, we will get a fully generated and transformed `Frame` in return.
```julia
alg = algebra(Int64, 15)
af = algebra(15, "one" => Int64)
alg_gen, af_gen = [alg], generate(af)
```
- Note that we could also use `Dict(af)`, `pairs(af)`, `framerows(af)`, `eachcol(af)`, 
or `eachrow(af)` to generate our `AlgebraFrame`.
```julia
# algebra
generate(alg::Algebra{<:Any, <:Any})
generate(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:1)

# algebra frames
generate(af::AbstractAlgebraFrame)
```
- See also: `Algebra`, `algebra!`, `set_generator!`, `AlgebraFrame`, `Frame`, `FrameRow`
"""
function generate end

function generate(alg::Algebra{<:Any, <:Any})
    gen = first(alg.pipe)
    params = methods(gen)[1].sig.parameters
    generated = if length(params) > 1
        [gen(dim) for dim in 1:length(alg)]
    else
        gen()
    end
    N = typeof(alg).parameters[2]
    if N > 1
        len = length(generated)
        lastlen = length(generated)
        [begin
            generated = hcat(generated, [gen(e) for e in lastlen + 1:(lastlen + len)])
            lastlen += len
        end for column in 2:N]
     end
    return(generated)
end

function generate(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:1)
    gen = first(alg.pipe)
    N_COLS = typeof(alg).parameters[2]
    params = methods(gen)[1].sig.parameters
    if maximum(col) > N_COLS

    elseif maximum(row) > alg.length
        throw("indexing too big of a value for the length")
    end
    col_length = Int64(round(N_COLS / alg.length))
    generated = if length(params) > 1
        if N_COLS > 1
            vals = (vcat(
                fill(0, minimum(row) - 1),
                [gen((dim - 1) + colrange * alg.length + 1) for dim in row],
                fill(0, length(alg) - maximum(row))
            ) for colrange in 0:N_COLS)
            hcat(vals ...)
        else
            vcat(
                fill(0, minimum(row) - 1),
                [gen(dim) for dim in row],
                fill(0, length(alg) - maximum(row)))
        end
    else
        gen()
    end
    generated::AbstractArray
end

getindex(alg::AbstractAlgebra, dim::Int64) = begin
    getindex(alg, dim:dim, 1:1)[1]
end

getindex(alg::AbstractAlgebra, dim::Int64, dim2::Int64) = getindex(alg, dim:dim, dim2:dim2)[dim, dim2]

function getindex(alg::AbstractAlgebra, row::UnitRange{Int64}, col::UnitRange{Int64} = 1:1)
    generated = generate(alg, row, col)
    [begin
        try
            func(generated)
        catch e
            throw("Algebra error todo here")
        end
    end for func in alg.pipe[2:length(alg.pipe)]]
    if col == 1:1
        generated[row]
    else
        generated[row, col]
    end
end

function vect(alg::AbstractAlgebra)
    generated = generate(alg)
    [begin
        try
            func(generated)
        catch e
            throw(e)
            throw("Algebra error todo here")
        end
    end for func in alg.pipe[2:length(alg.pipe)]]
    generated::AbstractArray
end

function eachrow(alg::AbstractAlgebra)
    eachrow([alg])
end

function eachcol(alg::AbstractAlgebra)
    eachcol([alg])
end

function vcat(origin::AbstractAlgebra, algebra::AbstractAlgebra ...)
    T = typeof(origin)
    dim = T.parameters[2]
    total_len = origin.length
    offsets = origin.offsets
    pipe = origin.pipe
    T = T.parameters[1]
    for alg in algebra
        alg_type = typeof(alg)
        if alg_type.parameters[2] != dim
            throw("future bounds error")
        end
        total_len += alg.length
        offsets = alg.offsets[1] + offsets[1] => alg.offsets[2] + offsets[2]
        push!(origin.pipe, alg.pipe ...)
    end
    Algebra{T, dim}(pipe, total_len, offsets)::Algebra{T, dim}
end

function hcat(origin::AbstractAlgebra, algebra::AbstractAlgebra ...)
    T = typeof(origin)
    dim = T.parameters[2]
    total_len = origin.length
    offsets = origin.offsets
    pipe = origin.pipe
    T = T.parameters[1]
    for alg in algebra
        push!(pipe, alg.pipe ...)
        dim += 1
        offsets = alg.offsets[1] + offsets[1] => alg.offsets[2] + offsets[2]
    end
    Algebra{T, dim}(pipe, total_len, offsets)
end