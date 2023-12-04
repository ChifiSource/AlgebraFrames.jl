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

function (:)(length::Int64, cols::String ...)
    AlgebraFrame(length, cols ...)
end

function (:)(af::AlgebraFrame{<:Any}, name::String, f::Function)
    colaxis = findfirst(x -> x == column, names)
    indx = AlgebraIndex(f, r, colaxis:colaxis)
    push!(af.algebra.pipe, indx)
end

function getindex(af::AlgebraFrame{<:Any}, column::String, r::UnitRange{Int64} = 1:af.algebra.length)
    colaxis = findfirst(x -> x == column, names)
    af.algebra[r, colaxis:colaxis]
end

vect(af::AlgebraFrame{<:Any}) = vect(af.algebra)