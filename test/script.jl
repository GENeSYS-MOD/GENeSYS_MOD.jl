import Pkg
cd("C:\\Users\\dimitrip\\GENeSYS-MOD\\dev_jl")
Pkg.activate(".")
Pkg.develop(path="..\\GENeSYS_MOD.jl")
using GENeSYS_MOD
using JuMP
using Dates
using CPLEX
using Gurobi
using Ipopt
using CSV
using Revise
start = Dates.now()

year=2018
#solver=CPLEX.Optimizer
solver=Gurobi.Optimizer
DNLPsolver= Ipopt.Optimizer
model_region="minimal"
data_base_region="DE"
data_file="Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_new"
#data_file = "Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_only_DE_test"
#data_file="Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_new_few_zones"
#hourly_data_file = "Hourly_Data_Europe_v09_kl_23_02_2022"
data_file="Data_Europe_GradualDevelopment_NNS0_v6_withoutoffshore"
hourly_data_file = "Hourly_Data_Europe_13"
threads=6
emissionPathway="MinimalExample"
emissionScenario="globalLimit"
socialdiscountrate=0.05
inputdir = joinpath(pkgdir(GENeSYS_MOD),"..","GENeSYS-MOD-python","Julia_test","Inputdata")
resultdir = joinpath(pkgdir(GENeSYS_MOD),"..","GENeSYS-MOD-python","Julia_test","Results")
switch_infeasibility_tech = 0
switch_investLimit=1
switch_ccs=1
switch_ramping=0
switch_weighted_emissions=1
switch_intertemporal=0
switch_base_year_bounds = 0
switch_peaking_capacity = 0
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
elmod_skiphours = 1
#elmod_skipdays = 0
#elmod_skiphours = 0
switch_raw_results = 1
switch_processed_results = 1
write_reduced_timeserie = 1

if elmod_nthhour != 0 && (elmod_skipdays !=0 || elmod_skiphours !=0)
    @warn "Both elmod_nthhour and elmod_skipdays/elmod_skiphours are defined. elmod_nthhour will be ignored. To use it, change elmod_skipdays/elmod_skiphours to 0"
elseif elmod_nthhour == 0 && elmod_skipdays ==0 && elmod_skiphours ==0
    @warn "Both elmod_nthhour and elmod_skipdays/elmod_skiphours are 0. Set a value to at least one of them."
elseif elmod_nthhour != 0 && elmod_skipdays ==0 && elmod_skiphours ==0
    elmod_skipdays = elmod_nthhour ÷ 24
    elmod_skiphours = elmod_nthhour % 24
elseif elmod_nthhour == 0
    elmod_nthhour = elmod_skipdays*24 + elmod_skiphours
end

Switch = GENeSYS_MOD.Switch(year,
    solver,
    DNLPsolver,
    model_region,
    data_base_region,
    data_file,
    hourly_data_file,
    threads,
    emissionPathway,
    emissionScenario,
    socialdiscountrate,
    inputdir,
    resultdir,
    switch_infeasibility_tech,
    switch_investLimit,
    switch_ccs,
    switch_ramping,
    switch_weighted_emissions,
    switch_intertemporal,
    switch_base_year_bounds,
    switch_peaking_capacity,
    set_peaking_slack,
    set_peaking_minrun_share,
    set_peaking_res_cf,
    set_peaking_startyear,
    switch_peaking_with_storages,
    switch_peaking_with_trade,
    switch_peaking_minrun,
    switch_employment_calculation,
    switch_endogenous_employment,
    employment_data_file,
    switch_dispatch,
    elmod_nthhour,
    elmod_starthour,
    elmod_dunkelflaute,
    elmod_skipdays,
    elmod_skiphours,
    switch_raw_results,
    switch_processed_results,
    write_reduced_timeserie)

print("Julia Init : ",Dates.now()-start,"\n")
model= JuMP.Model()
print("Model Init : ",Dates.now()-start,"\n")
Sets, Subsets, Params, Emp_Sets = GENeSYS_MOD.genesysmod_dataload(Switch);
print("Dataload Init : ",Dates.now()-start,"\n")
Maps = GENeSYS_MOD.make_mapping(Sets,Params)
print("Mapping : ",Dates.now()-start,"\n")
Vars = GENeSYS_MOD.genesysmod_dec(model,Sets,Subsets,Params,Switch, Maps);
print("Variable Declaration : ",Dates.now()-start,"\n")
Settings=GENeSYS_MOD.genesysmod_settings(Sets, Subsets, Params, Switch.socialdiscountrate);
print("Settings : ",Dates.now()-start,"\n")
GENeSYS_MOD.genesysmod_bounds(model,Sets, Subsets,Params,Vars,Settings,Switch,Maps);
print("Bounds : ",Dates.now()-start,"\n")
GENeSYS_MOD.genesysmod_equ(model,Sets,Subsets,Params, Vars,Emp_Sets,Settings,Switch, Maps)
#GENeSYS_MOD.genesysmod_equ(model,Sets,Subsets,Params,Emp_Sets,Settings,Switch)
print("Constraints : ",Dates.now()-start,"\n")
set_optimizer(model, solver)
if solver == Gurobi.Optimizer
    set_optimizer_attribute(model, "Threads", threads)
    set_optimizer_attribute(model, "Method", 2)
    set_optimizer_attribute(model, "BarHomogeneous", 1)
    set_optimizer_attribute(model, "ResultFile", "Solution_julia.sol")
elseif solver == CPLEX.Optimizer
    set_optimizer_attribute(model, "CPX_PARAM_THREADS", threads)
    set_optimizer_attribute(model, "CPX_PARAM_PARALLELMODE", -1)
    set_optimizer_attribute(model, "CPX_PARAM_LPMETHOD", 4)
    #set_optimizer_attribute(model, "CPX_PARAM_BAROBJRNG", 1e+075)
end
#write_to_file(model,"julia_perf.mps")
write_to_file(model,"test_perf.lp")
optimize!(model)
solution_summary(model)
elapsed = (Dates.now() - start)
print("After Solve : ",Dates.now()-start,"\n")
VarPar = GENeSYS_MOD.genesysmod_variable_parameter(model, Sets, Params)
print("VarPar : ",Dates.now()-start,"\n")
if termination_status(model) == MOI.INFEASIBLE
    println("Model Infeasible! Computing IIS")
    compute_conflict!(model)
    println("Saving IIS to file")
    GENeSYS_MOD.print_iis(model)

elseif termination_status(model) == MOI.OPTIMAL
    if switch_processed_results == 1
        GENeSYS_MOD.genesysmod_results(model, Sets, Subsets, Params, VarPar, Switch,
         Settings, elapsed,"dispatch")
    end
    if switch_raw_results == 1
        GENeSYS_MOD.genesysmod_results_raw(model, Switch,"dispatch")
    end
else
    println(termination_status(model))
end
print("Total : ",Dates.now()-start,"\n")