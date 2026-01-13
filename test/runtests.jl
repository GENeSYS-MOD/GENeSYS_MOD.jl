using GENeSYS_MOD
using Test
using JuMP
using HiGHS
using Ipopt

solver = HiGHS.Optimizer

@testset "GENeSYS-MOD" begin
    include("test.jl")
    include("test_dispatch_simple.jl")
    include("test_dispatch_onenodestorage.jl")
    include("test_dispatch_twonodes.jl")
end

#clean Results folder and subfolders of everything
result_path = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results")
for (root, dirs, files) in walkdir(result_path)
    for file in files
        rm(joinpath(root, file))
    end
end
