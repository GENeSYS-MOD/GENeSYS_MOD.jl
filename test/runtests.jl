using GENeSYSMOD
using Test
using JuMP
using HiGHS
using Ipopt

solver = HiGHS.Optimizer

@testset "GENeSYS-MOD" begin
    @testset "Investment Run" begin
        include("test.jl")
    end
    @testset "Fetch Input Data" begin
        include("test_fetchdata.jl")
    end
    @testset "Dispatch Runs" begin
        @testset "Simple Dispatch" begin
            include("test_dispatch_simple.jl")
        end
        @testset "One Node Storage Dispatch" begin
            include("test_dispatch_onenodestorage.jl")
        end
        @testset "Two Nodes Dispatch" begin
            include("test_dispatch_twonodes.jl")
        end
    end
end

#clean Results folder and subfolders of everything
result_path = joinpath(pkgdir(GENeSYSMOD),"test","TestData","Results")
for (root, dirs, files) in walkdir(result_path)
    for file in files
        rm(joinpath(root, file))
    end
end
