using AFMEphys
using Test

testdat = makeFileList(pwd() * "\\example", ".asc")
println(pwd())

@testset "AFMEphys.jl" begin
    @test testdat[1] == pwd() * "\\example\\test.asc"
    @test length(testdat) == 1
end