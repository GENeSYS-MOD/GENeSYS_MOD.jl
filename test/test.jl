#= import Pkg;
Pkg.activate(@__DIR__)
Pkg.instantiate() =#
include("init.jl")
using GENeSYS_MOD
using GLPK
using CPLEX
using Gurobi
using Ipopt

genesysmod(;elmod_skipdays = 16, elmod_skiphours = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath(pkgdir(GENeSYS_MOD),"..","..","Inputdata"),
tempdir = joinpath(pkgdir(GENeSYS_MOD),"..","..","TempFiles"),
resultdir = joinpath(pkgdir(GENeSYS_MOD),"..","..","Results"))