import Pkg
cd("/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl/src")
include("/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl/src/GENeSYS_MOD.jl")
Pkg.activate(".")
#Pkg.develop(path="/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl")
#Pkg.activate(".")
#Pkg.instantiate()
#ENV["CPLEX_STUDIO_BINARIES"] = "/cluster/home/danare/opt/ibm/ILOG/CPLEX_Studio2211/cplex/bin/x86-64_linux/"
#Pkg.build("CPLEX")
Pkg.add("Ipopt")
using .GENeSYS_MOD
using JuMP
using Dates
#using CPLEX
using Ipopt
using CSV
using Revise
using XLSX
using DataFrames
using HiGHS

model, data = genesysmod(;elmod_daystep = 80, elmod_hourstep = 1, solver=HiGHS.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath("/cluster/home/fsalenca/oceangrid_case/Input"),
resultdir = joinpath("/cluster/home/fsalenca/Spesialization_project/dev_jl/","Results"),
data_file="Data_Europe_GradualDevelopment_Input_cleaned_free",
hourly_data_file = "Hourly_Data_Europe_v13",
switch_infeasibility_tech = 1,
switch_investLimit=0,
switch_ccs=1,
switch_ramping=0,
switch_weighted_emissions=1,
switch_intertemporal=0,
switch_base_year_bounds = 1,
switch_peaking_capacity = 0,
set_peaking_slack = 0,
set_peaking_minrun_share = 0,
set_peaking_res_cf = 0,
set_peaking_startyear = 2025,
switch_peaking_with_storages = 0,
switch_peaking_with_trade = 0,
switch_peaking_minrun = 0,
switch_employment_calculation = 0,
switch_endogenous_employment = 0,
employment_data_file = "",
elmod_nthhour = 1000,
elmod_starthour = 1,
elmod_dunkelflaute= 0,
switch_raw_results = 0,
#elmod_daystep=0,
#elmod_hourstep=0,
switch_processed_results = 1,
write_reduced_timeserie = 0,
offshore_grid="Meshed", #newly added
switch_LCOE_calc=0);#newly added

