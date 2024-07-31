using GENeSYS_MOD
using Ipopt
using Gurobi

# Gonna look at Norway in a one-node System
# First just optimize over all contries, but with low resolution
# (I also allow infesability tech for testing purposes)
# Use Germany as the region to look to if there are missing data for a country

model, data = genesysmod(;elmod_daystep = 40, elmod_hourstep = 4, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, elmod_starthour = 0,
    inputdir = joinpath("test","TestData","DailyTest_NewCode"),
    resultdir = joinpath("test","MyData","DailyTest_NewCode"),
    data_file= "Parameter_data_myscript_test",
    hourly_data_file = "Timeseries_data_myscript_test",
    switch_raw_results = 0, # To save results for use by dispatch code
    switch_infeasibility_tech = 0, # Allow expensive DummyTech if porblem is not feasable.
    switch_investLimit = 0,
    write_reduced_timeserie = 0,
    data_base_region="DE",
    solution_file_name = "Solution_test.sol" #"Solution_40_12_day.sol", # "Solution_40_12_season.sol",
);


