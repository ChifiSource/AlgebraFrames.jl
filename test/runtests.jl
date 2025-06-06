using AlgebraFrames
using Test

@testset "algebraframes !" verbose = true begin
   @testset "Algebra" verbose = true begin
      alg = nothing
      @testset "algebra constructors" begin
         alg = Algebra{Int64, 1}()
         @test alg.length == 1
         @test typeof(alg) == AlgebraVector{Int64}
         alg2 = Algebra(generate(alg))
         @test typeof(alg2) == AlgebraVector{Int64}
         @test [alg2] == [alg]
         alg = algebra(Int64, (5, 5)) do e
            1
         end
         @test alg[1] == 1
         @test typeof(alg).parameters[2] == 5
      end
      @testset "getters" begin
         @test length(alg) == 5
         @test size(alg) == (5, 5)
      end
      @testset "algebra" begin
         algebra!(alg) do values
            values[1] = 25
            values[2] = 10
            values[5] = 10
         end
         @test length(alg.pipe) > 1
         @warn [alg]
         @test alg[1] == 25
         @test alg[5] == 10
         @test alg[1:2] == [25, 10]
         @test [alg][1] == 25
         deleteat!(alg, 1)
         @test length(alg) == 4
         multidim = algebra(Int64, (5, 5)) do e
            e
         end
         @test multidim[1] == 1
      end
      insta_gen = nothing
      @testset "generation" begin
         af = Algebra([5, 6, 7, 8])
         @test af[1] == 5
         @test af[1:3] == [5, 6, 7]
         @test af[4] == 8
         algebra!(af) do vec
            vec[1] += 5
         end
         @test af[1] == 10
         insta_gen = algebra(String, 10) do 
            ["p" for x in 1:10]
         end
         @test [insta_gen] == ["p" for x in 1:10]
         set_generator!(insta_gen) do e
            e
         end
         @test insta_gen[1] == 1
         @test insta_gen[2] == 2
         @test generate(alg) == [e for e in 1:10]
         multidim = algebra(Int64, (5, 5)) do e
            e
         end
         @test length(eachrow(multidim)) == 5
         cols = eachcol(multidim)
         @test length(cols) == 5
         @test cols[1][1] == 1
         @test hcat(cols ...) == [multidim]
      end
      @testset "API" begin
         multidim = algebra(Int64, (5, 5)) do e
            e
         end
         @test size(multidim) == (5, 5)
         deleteat!(insta_gen, 1)
         @test length(insta_gen) == 9
         @test length([insta_gen]) == 9
         cop = copy(insta_gen)
         @test cop.offsets == insta_gen.offsets
         @test cop.length == insta_gen.length
         @test [cop] == insta_gen[cop]
         # TODO hcat, vcat, reshape tests
      end
   end
   @testset "AlgebraFrame" verbose = true begin
      @testset "constructors" begin

      end
      @testset "getters" begin

      end
      @testset "algebra" begin

      end
      @testset "generation" begin

      end
      @testset "API" begin

      end
   end
   @testset "Frame" verbose = true begin
      @testset "frame and frame row constructors" begin

      end
      @testset "indexing" begin

      end
      @testset "getters" begin

      end
      @testset "API" begin

      end
   end
   @testset "full test" begin

   end
end