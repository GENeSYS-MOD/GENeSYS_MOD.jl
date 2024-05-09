import Pkg
cd("/cluster/home/danare/git/GENeSYS-MOD/dev_jl")
Pkg.activate(".")
Pkg.develop(path="/cluster/home/danare/git/TMP/GENeSYS_MOD.jl")
ENV["CPLEX_STUDIO_BINARIES"] = "/cluster/home/danare/opt/ibm/ILOG/CPLEX_Studio2211/cplex/bin/x86-64_linux/"
Pkg.build("CPLEX")


using GENeSYS_MOD
using JuMP
using Dates
using CPLEX
using Ipopt
using CSV
using Revise
using XLSX
using Pkg
using DataFrames
using PyCall


model, data = genesysmod(;elmod_daystep = 80, elmod_hourstep = 1, solver=CPLEX.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=30, 
inputdir = joinpath("/cluster/home/danare/git/GENeSYS_MOD.data","Output", "output_excel"),
resultdir = joinpath("/cluster/home/danare/git/GENeSYS-MOD/dev_jl","results"),
data_file="RegularParameters_Europe_openENTRANCE_technoFriendly",
hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
switch_infeasibility_tech = 1,
switch_investLimit=1,
switch_ccs=1,
switch_ramping=0,
switch_weighted_emissions=1,
switch_intertemporal=0,
switch_base_year_bounds = 0,
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
elmod_nthhour = 1,
elmod_starthour = 0,
elmod_dunkelflaute= 0,
switch_raw_results = 0,
switch_processed_results = 0,
write_reduced_timeserie = 1,
)


