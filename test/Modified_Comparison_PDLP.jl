import Pkg
Pkg.update()
cd("/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl/src")
Pkg.activate(".")
Pkg.develop(path="/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl")


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
#using PyCall
using HiGHS
# Data structures for each structures

building_time=[]
solving_time=[]
objective_list=[]
n_var = []
n_constr = []


    year = 2018
    solver = HiGHS.Optimizer
    DNLPsolver = Ipopt.Optimizer
    model_region = "minimal"
    data_base_region = "DE"
    data_file = "Data_Europe_GradualDevelopment_Input_cleaned_free"
    hourly_data_file = "Hourly_Data_Europe_v13"
    threads = 30
    emissionPathway = "MinimalExample"
    emissionScenario = "globalLimit"
    socialdiscountrate = 0.05
    inputdir = joinpath("/cluster/home/fsalenca/oceangrid_case/Input")
    resultdir = joinpath("/cluster/home/fsalenca/Spesialization_project/dev_jl/", "Results", "Spatial")
    switch_infeasibility_tech = 1
    switch_investLimit = 1
    switch_ccs = 0
    switch_ramping = 0
    switch_weighted_emissions = 0
    set_symmetric_transmission = 0
    switch_intertemporal = 0
    switch_base_year_bounds = 0
    switch_base_year_bounds_debugging = 0
    switch_peaking_capacity = 0
    set_peaking_slack = 0
    set_peaking_minrun_share = 0
    set_peaking_res_cf = 0
    set_peaking_min_thermal = 0
    set_peaking_startyear = 0
    switch_peaking_with_storages = 0
    switch_peaking_with_trade = 0
    switch_peaking_minrun = 0
    switch_employment_calculation = 0
    switch_endogenous_employment = 0
    employment_data_file = "None"
    switch_dispatch = 0
    elmod_nthhour = 400 #granularity at 4 days, try with 1000, 2000, 3000
    elmod_starthour = 0
    elmod_dunkelflaute = 0
    elmod_daystep = 0
    elmod_hourstep = 0
    switch_raw_results = 0
    switch_processed_results = 0
    write_reduced_timeserie = 0
    offshore_grid = "Meshed"
    switch_LCOE_calc = 0

    # Define the Switch for this granularity setting
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
    set_symmetric_transmission,
    switch_intertemporal,
    switch_base_year_bounds,
    switch_base_year_bounds_debugging,
    switch_peaking_capacity,
    set_peaking_slack,
    set_peaking_minrun_share,
    set_peaking_res_cf,
    set_peaking_min_thermal,
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
    elmod_daystep,
    elmod_hourstep,
    switch_raw_results,
    switch_processed_results,
    write_reduced_timeserie,
    offshore_grid, #newly added
    switch_LCOE_calc)
    # Start timing and model setup
    starttime = Dates.now()
    model = JuMP.Model()
    Sets, Params, Emp_Sets = GENeSYS_MOD.genesysmod_dataload(Switch)
    Maps = GENeSYS_MOD.make_mapping(Sets, Params)
    Vars = GENeSYS_MOD.genesysmod_dec(model, Sets, Params, Switch, Maps)
    Settings = GENeSYS_MOD.genesysmod_settings(Sets, Params, Switch.socialdiscountrate)
    GENeSYS_MOD.genesysmod_bounds(model, Sets, Params, Vars, Settings, Switch, Maps)
    GENeSYS_MOD.genesysmod_equ(model, Sets, Params, Vars, Emp_Sets, Settings, Switch, Maps)


    set_optimizer(model, solver)
    set_optimizer_attribute(model, "solver", "pdlp")
    optimize!(model)


    #set_optimizer_attribute(model, "solver", "pdlp"): 
    #Sets the HiGHS solver to use the PDLP algorithm for 
    #solving linear programming problems. 
    #This function call changes the algorithm that the solver 
    #uses by assigning the "solver" attribute the value "pdlp", 
    #switching HiGHS from its default methods to PDLP.



    build_end = Dates.now()
    build_time = (build_end - starttime)

    solve_time = Dates.now() - build_end
    obj_value = objective_value(model)
    n_vars = num_variables(model)
    n_constraints = sum(num_constraints(model, F, S) for (F, S) in list_of_constraint_types(model))

    # Append the results for comparison
    push!(building_time, build_time)
    push!(solving_time, solve_time)
    push!(objective_list, obj_value)
    push!(n_var, n_vars)
    push!(n_constr, n_constraints)

    println(" | Build Time: $build_time | Solve Time: $solve_time | Obj: $obj_value | Vars: $n_vars | Constr: $n_constraints")


io = open(joinpath(resultdir, "result_run_PDLP.txt"), "w")
for (b, s, o, v, c) in zip(building_time, solving_time, objective_list, n_var, n_constr)
    string = [Dict(
        "building"=>b, 
        "solve"=>s, 
        "Objective"=> o, 
        "#Var" => v, 
        "#Constr" => c)]
    println(io, string)
end
