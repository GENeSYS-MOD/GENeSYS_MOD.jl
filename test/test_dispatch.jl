using Pkg
Pkg.activate("GENeSYS_MOD")
import GENeSYS_MOD
using GENeSYS_MOD
using HiGHS
using Ipopt
using Gurobi

# model, data = genesysmod_simple_dispatch_two_nodes(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
# inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
# resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
# data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch_full_region",
# hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
# switch_raw_results = 1,
# # write_reduced_timeserie = 1,
# year=2050,
# # switch_processed_results =1,
# considered_region = "DE"
# );

model, data = genesysmod_simple_dispatch(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch_FR",
hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly_demand_Aggregation",
switch_raw_results = 1,
# write_reduced_timeserie = 1,
year=2050,
data_base_region="FR",
# switch_processed_results =1,
extr_str_results = "dispatch_test",
extr_str_dispatch = "run_FR_test"
);

# model, data = genesysmod_simple_dispatch_one_node_storage(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
# inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
# resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
# data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch",
# hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
# switch_raw_results = 1,
# # write_reduced_timeserie = 1,
# year=2050,
# # switch_processed_results =1
# );