using GENeSYS_MOD
using Test
using HiGHS
using Ipopt
using JuMP

try
    using Gurobi
    global solver = Ref(Gurobi.Optimizer)
catch
    global solver = Ref(HiGHS.Optimizer)
end

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
