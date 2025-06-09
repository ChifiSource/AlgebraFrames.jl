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
         @test generate(insta_gen) == [e for e in 1:10]
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
         cop = copy(insta_gen)
         @test cop.offsets == insta_gen.offsets
         @test cop.length == insta_gen.length
         @test [cop] == [insta_gen]
         one = algebra(Int64, 5)
         two = algebra(Int64, 5)
         @test length(vcat(one, two)) == 10
         @test typeof(hcat(one, two)).parameters[2] == 2
         mydim = algebra(Int64, (2, 5))
         @test size(mydim) == (2, 5)
         r = reshape(mydim, 5, 2)
         @test length(eachcol(r)) == 2
      end
   end
   @testset "AlgebraFrame" verbose = true begin
      af = algebra(15, "A" => Int64, "B" => String)
      @testset "constructors" begin
         trans = AlgebraFrames.Transform(Vector{Int16}(), print)
         @test typeof(trans) == AlgebraFrames.Transform
         @test length(af) == 15
         @test length(af.names) == 2
         @test "A" in af.names
      end
      @testset "getters" begin
         @test length(names(af)) == 2
         @test length(af) == 15
         @test size(af) == (15, 2)
         e = 0
         for x in framerows(af)
            @test "B" in x.names
            @test length(x.values) == 2
            @test x["A"] == 0
         end
         dct = Dict(af)
         @test length(keys(dct)) == 2
         @test length(first(dct)[2]) == 15
      end
      @testset "algebra" begin
         algebra!(af) do f::Frame
            f["A"][1] = 5
         end
         @test af["A"][1] == 5
         
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