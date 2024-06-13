using GENeSYS_MOD
using Ipopt
using Gurobi

model, data = genesysmod_simple_dispatch_two_nodes(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=4, 
inputdir = joinpath("test","TestData","Inputs"),
resultdir = joinpath("test","TestData","Results"),
data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch_full_region",
hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
switch_raw_results = 1,
# write_reduced_timeserie = 1,
year=2050,
# switch_processed_results =1
);

# model, data = genesysmod_simple_dispatch(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
# inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
# resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
# data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch",
# hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
# switch_raw_results = 1,
# # write_reduced_timeserie = 1,
# year=2050,
# # switch_processed_results =1
# );

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