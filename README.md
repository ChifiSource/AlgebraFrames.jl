<div align="center">
  <img src="https://github.com/ChifiSource/image_dump/blob/main/algebraframes/alframe.png" width="200"></img>
  <h6>soon to come: algia</h6>
</div>

`AlgebraFrames` provides several convenient *out-of-memory* data-structures for Julia. There are a few specific goals that this package hopes to achieve on the front of **out-of-memory** data.
- **live-wrangled** data. This means data that is never brought into Julia until calculation time. Using Algia, we will be able to make an algebraic object which represents data from a request, file, or data-base cursor, for example. One of the many applications of this project will be [ToolipsORM](https://github.com/ChifiSource/ToolipsORM.jl), providing algebraic relational objects for remote data-bases. Likewise, this will also be forged to work with requests, and I am also considering making some seeking readers for this same application.
- **mutated copies**. In Science, there are an array of situations where we need to apply operations over a large amount of data -- typically, we will create a copy of an data and then we will mutate a now second version of our data in memory. Algia seeks to mitigate the memory usage of this by allowing us to instead create an algebraic representation of those changes, storing the `Vector` as a reference to itself inside of the `Function` which generates our initial array.
- **manual compute**. In addition to the other things that `Algia` offers; one aspect of lazy calculation is simple yet still rings vital. We are able to choose when our machine engages in certain data processes.

###### map
- [get started](#get-started)
  - [adding algia](#adding-algia)
  - [explanation](#explanation)
- [usage](#usage)
  - [creation](#creation)
  - [generation](#generation)
  - [mutation](#mutation)
  - [examples](#examples)
- [Algebra](#algebra)
  - [creation](#algebra-creation)
  - [mutation](#algebra-mutation)
  - [generation](#algebra-generation)
- [AlgebraFrame](#algebra-frame)
  
### get started
`Algia` is still in a pretty early working form, though the project is **surprisingly far along** considering how little time has been invested into actually creating it. As of right now, most of the functionality revolves around a `Vector` of algebra, most of the functions for a 1-dimensional `Algebra` already exist. There are still more bindings to do, and with time I will **surely** be coming up with new bindings to do different things.
###### adding algia
```julia
using Pkg
Pkg.add("Algia")
```
**Unstable**
```julia
using Pkg
Pkg.add("Algia", rev = "Unstable")
```
##### explanation
Memory is a significant problem in the world of Scientific Computing. One of the most prominent solutions to this problem is called lazy execution. `Algia` simplifies lazy algebraic operations in Julia, providing flexibility in the **creation**, **mutation**, and **generation** of `Array` data in Julia. The package provides an `Array` equivalent in the form of `Algebra` and an `AlgebraFrame` which wraps the `Algebra` into a table.
### usage
The typical `Algia` process consists of three major steps:
- creation
- mutation
- and generation

In the creation step, we use `:` or a constructor to create some `Algebra`. In the mutation step, we use `:` to mutate the the generated return `Vector` inside of a `Function`. Finally, in the generation step we retrieve our data.
###### creation
**Creation** is the first step in this process, and creation of algebra with `Algia` revolves primarily around the colon, `:`. To create new `Algebra`, we provide `:` with a `Type` and dimensions. We are able to provide an `Int64`, for 1-dimensional length, or a `Tuple` of Int64s representing dimensions:
```julia
myalg = Int64:5
Int64 2x5

myalgebra = String:(5, 5)
String 5x5
```
Algebra can also be created from other `Algebra`.
```julia
just3 = myalg:(1:3)
Int64 3x1
```
Finally, we are also able to create `Algebra` from existing data structures. If we want to create algebra from data, we provide the data to the `Algebra` constructor.
```julia
newalg = Algebra([5, 10, 15])
Int64 3x1
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
Whereas our initialization `Function` provided during **creation** will provide the enumeration of our value, **mutation** will provide us an entire `Vector` of the portion we have selected. Here, for example, I utilize `filter!` to mutate our `Algebra`.
```julia
alg:x -> filter!(y -> y == 1, x)

[alg]
1-element Vector{Int64}:
 1
```
###### generation

#### examples

### algebra
#### algebra creation
#### algebra mutation
#### algebra generation
### algebra frame

