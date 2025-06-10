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
   @testset "Algebra Frames" verbose = true begin
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
      end
      @testset "algebra" begin
         algebra!(af) do f::Frame
            f["A", 1] = 5
         end
         @test af["A"][1] == 5
         @test length(af["A"]) == length(af)
         gen = generate(af)
         @test gen["A"] == af["A"]
         @test gen["B"] == af["B"]
         @test typeof(gen["B"][1]) <: AbstractString
      end
      @testset "transformations" begin
         algebra!(af) do f::Frame
            f["A", 1:5] = [1, 2, 3, 4, 5]
            f["B", 1] = "now"
            @test f["A", 1] == 1
            @test f["A", 1:5][1:5] == [1, 2, 3, 4, 5]
         end
         gen = generate(af)
         @test gen["A"][1:5] == [1, 2, 3, 4, 5]
         @test gen["A", 1:5][1:5] == [1, 2, 3, 4, 5]
         @test gen["B"][1] == "now"
      end
      @testset "generation" begin
         dct = Dict(af)
         @test length(keys(dct)) == 2
         @test length(first(dct)[2]) == 15
         for x in framerows(af)
            @test "B" in x.names
            @test length(x.values) == 2
            @test x["A"] in [1, 2, 3, 4, 5, 0]
         end
         for y in eachcol(af)
            @test length(y) == af.length
         end
         NLEN = length(af.names)
         for y in eachrow(af)
            @test length(y) == NLEN
         end
         @test length(pairs(af)) == length(af.names)
         gen = generate(af)
         @test length(gen.names) == length(af.names)
         @test length(gen.values[1]) == af.length
      end
      af = algebra(15, "A" => Int64, "B" => String)
      @testset "API" begin
         # Af api
         af2 = algebra(5, "A" => Int64, "B" => String)
         combided = merge(af, af2)
         @test length(combided) == length(af) + length(af2)
         @test length(generate(combided)) == length(af) + length(af2)
         join!(af, "C" => Int64) do e
            e
         end
         @test size(af) == (length(af), 3)
         @test length(names(af)) == 3
         @test length(names(combided)) == 3
         @test "C" in names(af)
         drop!(af, "A")
         @test length(names(af)) == 2
         @test ~("A" in names(af))
         gen = generate(af)
         @test "C" in names(gen)
         @test ~("A" in names(gen))
         @test length(names(gen)) == 2
         @test "B" in names(gen)
         gen = generate(af2)
         newcol = algebra(combided.length, "W" => Float64, "Y" => Int64)
         joined = join(combided, newcol)
         for x in ("W", "Y")
            @test x in names(joined)
            @test ~(x in names(combided))
         end
         join!(combided, newcol)
         for x in ("W", "B", "C", "Y")
            @test x in names(combided)
         end
         # f api
         # (merge, size, length, join, join!, names, etc...)
         @test size(gen) == size(af2)
         @test gen["B", 1:3][1:3] == ["null", "null", "null"]
         @test length(gen) == length(af2)
         @test length(names(gen)) == 2
         # replace!
         af = algebra(20, "A" => Int64, "B" => String)
         algebra!(af) do f::Frame
            replace!(f, "null", "n")
         end
         @test af["B"][2] == "n"
         join!(af, "C" => Int64)
         algebra!(af) do f::Frame
            replace!(f, "A", 0, 5)
         end
         gen = generate(af)
         @test ~(0 in gen["A"])
         @test 0 in gen["C"]
         mergef = merge(generate(af), generate(af))
         @test length(mergef) == length(af) * 2
         # cast!
         cast!(af, "A", Float64)
         @test Float64 in af.T
         @test typeof(af["A"]) == Vector{Float64}
         testgen = generate(af)
         cast!(testgen, "A", Float64)
         @test typeof(testgen["A", 1]) == Float64
         # filter!
         newf = algebra(5, "A" => Int64, "B" => String)
         set_generator!(newf, "A") do e
            [5, 6, 22, 33, 8][e]
         end
         algebra!(newf) do frame::Frame
            filter!(frame) do row::FrameRow
               row["A"] > 22
            end
         end
         @test length(generate(newf)) < 5
         found = findfirst(x -> x < 22, generate(newf)["A"])
         @test isnothing(found)
         # drop! + deleteat!
         drop!(gen, "A")
         @test ~("A" in names(gen))
         # frame rows/pairs/eachcol/eachrow
         for row in framerows(gen)
            @test "C" in names(row)
            break
         end
         @test length(eachcol(gen)) == 2
         @test length(pairs(gen)) == 2
         @test "C" in keys(Dict(pairs(gen) ...))
         @test length(eachrow(gen)) == length(gen)
         @test length(gen) == length(af)
      end
   end
end