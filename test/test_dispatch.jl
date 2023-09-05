include("init.jl")
using GENeSYS_MOD
using CPLEX
using Ipopt

year=2018
switch_only_load_gdx=0
switch_test_data_load=0
solver=CPLEX.Optimizer
#solver=Gurobi.Optimizer
DNLPsolver= Ipopt.Optimizer
model_region="minimal"
data_base_region="DE"
#data_file="Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_new"
#data_file = "Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_only_DE_test"
data_file="Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_new_few_zones"
hourly_data_file = "Hourly_Data_Europe_v09_kl_23_02_2022"
timeseries_data_file="genesysmod_timeseriesdata_minimalexample_v02_kl_15_03_2023"
threads=20
emissionPathway="MinimalExample"
emissionScenario="globalLimit"
socialdiscountrate=0.05
inputdir = joinpath(pkgdir(GENeSYS_MOD),"..","..","Inputdata")
tempdir = joinpath(pkgdir(GENeSYS_MOD),"..","..","TempFiles")
resultdir = joinpath(pkgdir(GENeSYS_MOD),"..","..","Results")
switch_infeasibility_tech = 0
switch_investLimit=1
switch_ccs=1
switch_ramping=0
switch_weighted_emissions=1
switch_intertemporal=0
switch_short_term_storage=1
switch_base_year_bounds = 1
switch_peaking_capacity = 1
set_peaking_slack = 1.0
set_peaking_minrun_share = 0.15
set_peaking_res_cf = 0.5
set_peaking_startyear = 2025
switch_peaking_with_storages = 0
switch_peaking_with_trade = 0
switch_peaking_minrun = 1
switch_employment_calculation = 0
switch_endogenous_employment = 0
employment_data_file = ""
switch_dispatch = 0
#elmod_nthhour = 0
elmod_nthhour = 0
elmod_starthour = 8
elmod_dunkelflaute= 0
elmod_skipdays = 80
elmod_skiphours = 8
#elmod_skipdays = 0
#elmod_skiphours = 0
switch_raw_results = 1
switch_processed_results = 1
write_reduced_timeserie = 1

model,case=genesysmod(;elmod_skipdays, elmod_skiphours, solver, DNLPsolver, year, switch_only_load_gdx, switch_test_data_load,
    model_region, data_base_region, data_file,timeseries_data_file, threads, emissionPathway,
    emissionScenario, socialdiscountrate,  inputdir, tempdir ,resultdir,
    switch_infeasibility_tech, switch_investLimit, switch_ccs, switch_ramping,switch_weighted_emissions,switch_intertemporal,
    switch_short_term_storage, switch_base_year_bounds,switch_peaking_capacity, set_peaking_slack, set_peaking_minrun_share,
    set_peaking_res_cf, set_peaking_startyear, switch_peaking_with_storages, switch_peaking_with_trade,switch_peaking_minrun,
    switch_employment_calculation, switch_endogenous_employment, employment_data_file, switch_dispatch, 
    hourly_data_file,elmod_nthhour, elmod_starthour, elmod_dunkelflaute,
    switch_raw_results, switch_processed_results, write_reduced_timeserie)

data_file="Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_new_few_zones_dispatch"

model_disp,case_disp=genesysmod_simple_dispatch(; solver, DNLPsolver, year, switch_only_load_gdx, switch_test_data_load,
    model_region, data_base_region, data_file,
    timeseries_data_file, threads, emissionPathway,
    emissionScenario, socialdiscountrate,  inputdir, tempdir ,resultdir,
    switch_investLimit, switch_ccs, switch_ramping,switch_weighted_emissions,switch_intertemporal,
    switch_short_term_storage, switch_base_year_bounds,switch_peaking_capacity, set_peaking_slack, set_peaking_minrun_share, 
    set_peaking_res_cf, set_peaking_startyear, switch_peaking_with_storages, switch_peaking_with_trade,switch_peaking_minrun ,
    switch_employment_calculation, switch_endogenous_employment, employment_data_file, hourly_data_file, 
    elmod_dunkelflaute, switch_raw_results, switch_processed_results, write_reduced_timeserie)

    