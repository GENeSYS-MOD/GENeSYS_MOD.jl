import Pkg
cd("/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl/src")
Pkg.activate(".")
Pkg.develop(path="/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl")
ENV["CPLEX_STUDIO_BINARIES"] = "/cluster/home/fsalenca/cplex/bin/x86-64_linux/"

# Z:/cplex/bin/x86-64_linux


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
using HiGHS



# Initializing arrays for both CPLEX and HiGHS results
building_time_cplex = []
solving_time_cplex = []
objective_list_cplex = []
n_var_cplex = []
n_constr_cplex = []

building_time_highs = []
solving_time_highs = []
objective_list_highs = []
n_var_highs = []
n_constr_highs = []

# Iterate through the different granularities
for n in [182, 121, 91] # Days

    # Define common model parameters
    year=2018
    model_region="minimal"
    data_base_region="DE"
    data_file="Data_Europe_GradualDevelopment_Input_cleaned_free" # Changed Full_Europe with Data_Europe_GradualDevelopment_Input_cleaned_free
    hourly_data_file="Hourly_Data_Europe_v13"
    threads=30
    emissionPathway="MinimalExample"
    emissionScenario="globalLimit"
    socialdiscountrate=0.05
    inputdir=joinpath("/cluster/home/fsalenca/oceangrid_case/Input")
    resultdir = joinpath("/cluster/home/fsalenca/Spesialization_project/dev_jl/","Results", "Spatial")
    switch_infeasibility_tech=1
    switch_investLimit=1
    switch_ccs=0
    switch_ramping=0
    switch_weighted_emissions=0
    set_symmetric_transmission=0
    switch_intertemporal=0
    switch_base_year_bounds=0
    switch_base_year_bounds_debugging=0
    switch_peaking_capacity=0
    set_peaking_slack=0
    set_peaking_minrun_share=0
    set_peaking_res_cf=0
    set_peaking_min_thermal=0
    set_peaking_startyear=0
    switch_peaking_with_storages=0
    switch_peaking_with_trade=0
    switch_peaking_minrun=0
    switch_employment_calculation=0
    switch_endogenous_employment=0
    employment_data_file="None"
    switch_dispatch=0
    elmod_nthhour=n
    elmod_starthour=0
    elmod_dunkelflaute=0
    elmod_daystep=0
    elmod_hourstep=0
    switch_raw_results=0
    switch_processed_results=0
    write_reduced_timeserie=0
    offshore_grid = "Meshed"
    switch_LCOE_calc=0

    # Function to run model with a specified solver
    function run_model(solver)
        global building_time, solving_time, objective_list, n_var, n_constr
        
        # Run the model with the given solver
        model = Model(solver)
        set_optimizer_attribute(model, "threads", threads)
        # Add your model building steps here...
        
        # Measure building and solving time
        b = @elapsed begin
            # Build the model here...
        end
        s = @elapsed begin
            optimize!(model)
        end

        # Check termination status and capture results
        if termination_status(model) == MOI.OPTIMAL
            objective = objective_value(model)
            n_v = num_variables(model)
            n_c = sum(num_constraints(model, F, S) for (F, S) in list_of_constraint_types(model))

            # Append results to the corresponding arrays
            append!(building_time, b)
            append!(solving_time, s)
            append!(objective_list, objective)
            append!(n_var, n_v)
            append!(n_constr, n_c)
        else
            println("Termination status: ", termination_status(model))
        end
    end

    # Run for CPLEX Solver
    building_time, solving_time, objective_list, n_var, n_constr = building_time_cplex, solving_time_cplex, objective_list_cplex, n_var_cplex, n_constr_cplex
    run_model(CPLEX.Optimizer)

    # Run for HiGHS Solver
    building_time, solving_time, objective_list, n_var, n_constr = building_time_highs, solving_time_highs, objective_list_highs, n_var_highs, n_constr_highs
    run_model(HiGHS.Optimizer)
end

# Write results to a text file for both solvers
io_cplex = open(joinpath(resultdir, "result_cplex.txt"), "w")
for (b, s, o, v, c) in zip(building_time_cplex, solving_time_cplex, objective_list_cplex, n_var_cplex, n_constr_cplex)
    println(io_cplex, Dict("building" => b, "solve" => s, "Objective" => o, "#Var" => v, "#Constr" => c))
end
close(io_cplex)

io_highs = open(joinpath(resultdir, "result_highs.txt"), "w")
for (b, s, o, v, c) in zip(building_time_highs, solving_time_highs, objective_list_highs, n_var_highs, n_constr_highs)
    println(io_highs, Dict("building" => b, "solve" => s, "Objective" => o, "#Var" => v, "#Constr" => c))
end
close(io_highs)
