using Pkg
Pkg.develop(path="..\\GENeSYS_MOD.jl")
using GENeSYS_MOD
using HiGHS
using Ipopt
using Gurobi

print(pkgdir(GENeSYS_MOD))
model, data = genesysmod(;elmod_daystep = 80, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
data_file="RegularParameters_Europe_openENTRANCE_technoFriendly",
hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
)