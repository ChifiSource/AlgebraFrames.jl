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
         alg = Algebra{Int64}((5, 5)) do e
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
         end
         @test length(alg.pipe) > 1
    #     @test alg[1] == 25
         @test [alg][1] == 25
      end
      @testset "generation" begin

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