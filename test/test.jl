using GENeSYS_MOD
using Ipopt
using Gurobi

model, data = genesysmod(;elmod_daystep = 15, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath("test","TestData","Inputs"),
resultdir = joinpath("test","TestData","Results"),
data_file="RegularParameters_Europe_openENTRANCE_technoFriendly",
hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
switch_raw_results = 1,
write_reduced_timeserie = 0,
#data_base_region="FR"
);