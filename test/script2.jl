import Pkg
cd("/cluster/home/danare/git/GENeSYS_MOD-main/dev")
Pkg.activate(".")
Pkg.develop(path="../GENeSYS_MOD.jl")
Pkg.add("Revise")
using GENeSYS_MOD
using JuMP
using Dates
using Gurobi
using Ipopt
using CSV
using Revise
start = Dates.now()


year=2018
solver=Gurobi.Optimizer
DNLPsolver= Ipopt.Optimizer
model_region="minimal"
data_base_region="DE"
data_file="Data_Europe_GradualDevelopment_NNS0_v7_13Dec23NewOffshoreZones"
hourly_data_file = "Hourly_Data_Europe_v13_kl_13_12_2023_windDataWP1"
threads=6
emissionPathway="MinimalExample"
emissionScenario="globalLimit"
socialdiscountrate=0.05
inputdir = joinpath("/cluster/home/danare/git/GENeSYS_MOD-main/dev","data", "Meshed", "WP1")
resultdir = joinpath("/cluster/home/danare/git/GENeSYS_MOD-main/dev","results")
switch_infeasibility_tech = 0
switch_investLimit=1
switch_ccs=1
switch_ramping=0
switch_weighted_emissions=1
switch_intertemporal=0
switch_base_year_bounds = 0
switch_peaking_capacity = 0
set_peaking_slack = 0
set_peaking_minrun_share = 0
set_peaking_res_cf = 0
set_peaking_startyear = 2025
switch_peaking_with_storages = 0
switch_peaking_with_trade = 0
switch_peaking_minrun = 0
switch_employment_calculation = 0
switch_endogenous_employment = 0
employment_data_file = ""
switch_dispatch = 0
elmod_nthhour = 0
elmod_starthour = 8
elmod_dunkelflaute= 0
elmod_skipdays = 30
elmod_skiphours = 4
switch_raw_results = 0
switch_processed_results = 0
write_reduced_timeserie = 0

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
GENeSYS_MOD.genesysmod_dec(model,Sets,Subsets,Params,Switch);
print("Variable Declaration : ",Dates.now()-start,"\n")
Settings=GENeSYS_MOD.genesysmod_settings(Sets, Subsets, Params, Switch.socialdiscountrate);
print("Settings : ",Dates.now()-start,"\n")
GENeSYS_MOD.genesysmod_bounds(model,Sets, Subsets,Params,Settings,Switch);
print("Bounds : ",Dates.now()-start,"\n")
#Maps = GENeSYS_MOD.make_mapping(Sets,Params)
#print("Mapping : ",Dates.now()-start,"\n")
#GENeSYS_MOD.genesysmod_equ(model,Sets,Subsets,Params,Emp_Sets,Settings,Switch, Maps)
GENeSYS_MOD.genesysmod_equ(model,Sets,Subsets,Params,Emp_Sets,Settings,Switch)
print("Constraints : ",Dates.now()-start,"\n")
set_optimizer(model, solver)
if solver == Gurobi.Optimizer
    set_optimizer_attribute(model, "Threads", threads)
    set_optimizer_attribute(model, "Method", 2)
    set_optimizer_attribute(model, "BarHomogeneous", 1)
    set_optimizer_attribute(model, "ResultFile", "Solution_julia.lp")
end

optimize!(model)
solution_summary(model)
elapsed = (Dates.now() - start)

println(termination_status(model))
if termination_status(model) == MOI.INFEASIBLE_OR_UNBOUNDED
    JuMP.compute_conflict!(model)
    list_of_conflicting_constraints = ConstraintRef[]
    for (F, S) in list_of_constraint_types(model)
        for con in all_constraints(model, F, S)
            if get_attribute(con, MOI.ConstraintConflictStatus()) == MOI.IN_CONFLICT
                push!(list_of_conflicting_constraints, con)
            end
        end
    end
    
    open("/cluster/home/danare/git/GENeSYS_MOD-main/dev/results/iis.txt", "w") do file
        for r in list_of_conflicting_constraints
            println(r)
            write(file, string(r)*"\n")
        end
    end
    # write model to file
    write_to_file(model, "my_model.lp")
    f = open("model.lp", "w")
    print(f, model)
    close(f)

elseif termination_status(model) == MOI.OPTIMAL
    print("After Solve : ",Dates.now()-start,"\n")
    VarPar = GENeSYS_MOD.genesysmod_variable_parameter(model, Sets, Params)
    print("VarPar : ",Dates.now()-start,"\n")
    if switch_processed_results == 1
        GENeSYS_MOD.genesysmod_results(model, Sets, Subsets, Params, VarPar, Switch,
         Settings, elapsed,"dispatch")
    end

    # write solution to txt file
    dt = Dates.format(Dates.now(), "yyyymmdd")

    file = open(normpath(joinpath(dirname(@__FILE__),"..","..", "dev", "results", "v7h2$dt.txt")), "w")
    # Write variable names and values to the file
    for v in all_variables(model)
        if value.(v) > 0
            val = value.(v)
            str = string(v)
            println(file, "$str = $val")
        end
    end
    println(length(all_variables(model)))
    
    if switch_raw_results == 1
        GENeSYS_MOD.genesysmod_results_raw(model, Switch,"dispatch")
    end
else
    println(termination_status(model))
end
print("Total : ",Dates.now()-start,"\n")