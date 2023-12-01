<div align="center">
  <img src="https://github.com/ChifiSource/image_dump/blob/main/algia/Algia.png"></img>
  <h6>soon to come: algia</h6>
</div>

Algia provides Julia with a high-level lazy algebriac framework which includes an `AlgebraVector`, multi-dimensional `Algebra`, and an `AlgebraFrame`. There are a few specific goals that this package hopes to achieve on the front of **out-of-memory** data.
- **live-wrangled** data. This means data that is never brought into Julia until calculation time. Using Algia, we will be able to make an algebraic object which represents data from a request, file, or data-base cursor, for example. One of the many applications of this project will be [ToolipsORM](https://github.com/ChifiSource/ToolipsORM.jl), providing algebraic relational objects for remote data-bases. Likewise, this will also be forged to work with requests, and I am also considering making some seeking readers for this same application.
- **mutated copies**. In Science, there are an array of situations where we need to apply operations over a large amount of data -- typically, we will create a copy of an data and then we will mutate a now second version of our data in memory. Algia seeks to mitigate the memory usage of this by allowing us to instead create an algebraic representation of those changes, storing the `Vector` as a reference to itself inside of the `Function` which generates our initial array.
- **manual compute**. In addition to the other things that `Algia` offers; one aspect of lazy calculation is simple yet still rings vital. We are able to choose when our machine engages in certain data processes.

###### current form
`Algia` is still in a pretty early working form, though the project is **surprisingly far along** considering how little time has been invested into actually creating it. As of right now, most of the functionality revolves around a `Vector` of algebra, most of the functions for a 1-dimensional `Algebra` already exist. There are still more bindings to do, and with time I will **surely** be coming up with new bindings to do different things.

The `Algia` process consists of three main parts...
- creation
- mutation
- and generation
###### creation
**Creation** is the first step in this process, and creation of algebra with `Algia` revolves primarily around the colon, `:`. To create new `Algebra`, we provide `:` with a `Type` and dimensions. We are able to provide an `Int64`, for 1-dimensional length, or a `Tuple` of Int64s representing dimensions:
```julia
alg = Int64:10
AlgebraVector{Int64}(Algia.AlgebraIndex[Algia.AlgebraIndex(Algia.var"#75#85"(), 1:10, 1:1)], 10)

multialg = String:(5, 5)
Algebra{String, 5}(Algia.AlgebraIndex[Algia.AlgebraIndex(Algia.var"#81#91"(), 1:5, 1:5)], 5)
```
We are also able to create `Algebra` from existing data structures. This applies in the context of **mutated copies** above, for example.
```julia
myvec = [1, 2, 3]
newalg = Algebra(myvec)

AlgebraVector{Int64}(Algia.AlgebraIndex[Algia.AlgebraIndex(Algia.var"#82#92"{Vector{Int64}}([1, 2, 3]), 1:3, 1:1)], 3)
```
###### generation
The next step in this process would be **mutation**, but to make this process make a bit more sense, we will first discuss **generation**. If we want to generate a specific index of our `Algebra`, we use `getindex`. Note that indexing will always generate. To generate the whole thing, we can either index with nothing, `alg[]` or use `Vector` delimeters to `vect` the `Algebra`.
```julia
[alg]
10-element Vector{Int64}:
 0
 0
 0
 0
 0
 0
 0
 0
 0
 0

[multialg]
5×5 Matrix{String}:
 "nothing"  "nothing"  "nothing"  "nothing"  "nothing"
 "nothing"  "nothing"  "nothing"  "nothing"  "nothing"
 "nothing"  "nothing"  "nothing"  "nothing"  "nothing"
 "nothing"  "nothing"  "nothing"  "nothing"  "nothing"
 "nothing"  "nothing"  "nothing"  "nothing"  "nothing"
```
Using `getindex` works with ranges and integers, exactly how one might expect and will only generate that range.
```julia
alg[3]
0
alg[3:4]
[0, 0]
```
###### mutation
Like **creation**, **mutation** in `Algia` centers around the colon, `:`. In order to mutate some `Algebra`, we provide the `Algebra` and a `Function` to `:`.
```julia
alg:x -> x[1] += 1

[alg]
10-element Vector{Int64}:
 1
 0
 0
 0
 0
 0
 0
 0
 0
 0
```
Whereas **generation** will provide the enumeration of our value, **mutation** will provide us an entire `Vector` of the portion we have selected. Here, for example, I utilize `filter!` to mutate our `Algebra`.
```julia
alg:x -> filter!(y -> y == 1, x)

[alg]
1-element Vector{Int64}:
 1
```
