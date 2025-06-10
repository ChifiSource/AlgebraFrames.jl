<div align="center">
  <img src="https://github.com/ChifiSource/image_dump/blob/main/algebraframes/alframe.png" width="200"></img>

[documentation](https://chifidocs.com/algebraframes/AlgebraFrames)
  
  <h6>algebraframes !</h6>
</div>

`AlgebraFrames` provides several convenient *out-of-memory* [*algebraic* data-structures](https://en.wikipedia.org/wiki/Algebraic_structure) for Julia. There are a few specific goals that this package hopes to achieve on the front of **out-of-memory** data. The goal of this package is to reduce memory usage when web-hosting or analyzing large swaths of data using *Relational Management* for a simplified end-user experience.
- **relational management** `AlgebraFrames` uses *indexing* to act as a *relational management* tool for computed, or " algebraic", data.
- **live-wrangled** data. Data is only brought into Julia at execution time.
- **low-memory mutated copies** of existing array take far less memory.
- **extension ecosystem** like other base [chifi](https://github.com/ChifiSource) packages, `AlgebraFrames` comes with its own [Ecosystem](https://github.com/ChifiSource#algebra-frames)
###### map
- [get started](#get-started)
  - [documentation]()
- [Algebra](#algebra)
  - [creation](#algebra-creation)
  - [mutation](#algebra-mutation)
  - [generation](#algebra-generation)
- [Frames](#frames)
- [contributing]()
  - [issue guidelines]()
  - [contributing guidelines]()
  
### get started
- `AlgebraFrames` requires [julia](https://julialang.org/install/)

Using Julia, we install `AlgebraFrames` `using Pkg`:
```julia
julia> using Pkg; Pkg.add("AlgebraFrames")
```
Alternatively, you may add the `Unstable` revision:
```julia
using Pkg
Pkg.add(name = "AlgebraFrames", rev = "Unstable")
```
###### documentation
- [chifidocs documentation](https://chifidocs.com/algebraframes/AlgebraFrames)
- [ecosystem documentation](https://chifidocs.com/algebraframes)
--- 
### algebra
`AlgebraFrames` creates out-of-memory, computational structures for Julia's `Base` `Array` type **and** `AlgebraFrames'` own `Frame` type. An `AlgebraFrame` is a non-generated equivalent to a `Frame` and an `Algebra` is the non-generated equivalent to the `Array`. This includes multi-dimensional arrays, as well as the `AlgebraVector` equivalent for the `Vector`.
