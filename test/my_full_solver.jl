using GENeSYS_MOD
using Ipopt
using Gurobi

# Gonna look at Norway in a one-node System
# First just optimize over all contries, but with low resolution
# (I also allow infesability tech for testing purposes)
# Use Germany as the region to look to if there are missing data for a country

model, data = genesysmod(;elmod_daystep = 60, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
    inputdir = joinpath("test","TestData","Inputs2"),
    resultdir = joinpath("test","TestData","Results2"),
    data_file="RegularParameters_standard",
    hourly_data_file = "Timeseries_standard",
    switch_raw_results = 1, # To save results for use by dispatch code
    switch_infeasibility_tech = 1, # Allow expensive DummyTech if porblem is not feasable.
    write_reduced_timeserie = 0,
    data_base_region="DE"
);