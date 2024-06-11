using Pkg
Pkg.activate("GENeSYS_MOD")
import GENeSYS_MOD
using GENeSYS_MOD
using HiGHS
using Ipopt
using Gurobi

model, data = genesysmod(;elmod_daystep = 1, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_FR",
hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly_demand_Bordeaux",
switch_raw_results = 1,
write_reduced_timeserie = 0,
data_base_region="FR"
);