mutable struct AlgebraFrame{N <: Any}
    names::Vector{String}
    algebra::Algebra{Any, N}
    AlgebraFrame(names::Vector{String}, algebra::Algebra{Any, <:Any}) = new{length(names)}(names, algebra)
    function AlgebraFrame(f::Function, observations::Int64, names::String ...)
        algebra = Algebra{Any}(f, observations, length(names))
        AlgebraFrame([string(name) for name in names], algebra)
    end
    function AlgebraFrame(observations::Int64, names::String ...)
        algebra = Algebra{Any}(x -> 0, observations, length(names))
        AlgebraFrame([string(name) for name in names], algebra)
    end
    function AlgebraFrame(cols::Pair{String, <:AbstractVector} ...)
        n_obs = length(cols[1][2])
        cols_generated::Int64 = 1
        AlgebraFrame(n_obs, [p[1] for p in cols] ...) do e
            n = e / cols_generated
            if n == n_obs
                cols_generated += 1
            end
            e = cols[cols_generated][2][n]
        end::AlgebraFrame{<:Any}
    end
end

length(af::AlgebraFrame{<:Any}) = length(af.algebra)

# creation
function (:)(length::Int64, cols::String ...)
    AlgebraFrame(length, cols ...)
end

function (:)(af::AlgebraFrame{<:Any}, name::String, f::Function)
    colaxis = findfirst(x -> x == column, names)
    indx = AlgebraIndex(f, r, colaxis:colaxis)
    push!(af.algebra.pipe, indx)
end

# algebraic indexing
function (:)(af::AlgebraFrame{<:Any}, name::String, dims::UnitRange{Int64} = 1:length(af))
    col = findfirst(n::String -> n == name, af.names)
    af.algebra:(dims, col:col)
end

(:)(alg::AlgebraFrame{<:Any}, args ...) = (:)(alg.algebra, args ...)

# generation
function getindex(af::AlgebraFrame{<:Any}, column::String, r::UnitRange{Int64} = 1:af.algebra.length)
    colaxis = findfirst(x -> x == column, names)
    af.algebra[r, colaxis:colaxis]
end

getindex(af::AlgebraFrame{<:Any}, args ...) = (:)(alg.algebra, args ...)

vect(af::AlgebraFrame{<:Any}) = vect(af.algebra)

function show(io::IO, algebra::AlgebraFrame{<:Any})
    previews = [algebra[name, 1:5] for name in algebra.names]
    println(io, "$T $(rows)x$cols")
end