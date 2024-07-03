using GENeSYS_MOD
using Ipopt
using Gurobi

# Run a dispatch with Norway and the rest of the World
# 

model, data = genesysmod_simple_dispatch_two_nodes(;elmod_daystep = 15, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
    inputdir = joinpath("test","TestData","Inputs"),
    resultdir = joinpath("test","TestData","Results"),
    data_file="RegularParameters_Europe_openENTRANCE_technoFriendly",
    hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
    switch_raw_results = 1,
    # write_reduced_timeserie = 1,
    year=2050,
    # switch_processed_results =1,
    considered_region = "DE"
);