using GENeSYS_MOD
using Ipopt
using Gurobi

model, data = genesysmod(;elmod_daystep = 1, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath("test","TestData","Inputs"),
resultdir = joinpath("test","TestData","Results"),
data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_FR",
hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly_demand_Bordeaux",
switch_raw_results = 1,
write_reduced_timeserie = 0,
data_base_region="FR"
);