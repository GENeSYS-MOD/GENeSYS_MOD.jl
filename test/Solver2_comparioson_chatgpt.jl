import Pkg
cd("/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl/src")
Pkg.activate(".")
Pkg.develop(path="/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl")
ENV["CPLEX_STUDIO_BINARIES"] = "/cluster/home/fsalenca/cplex/bin/x86-64_linux/"

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

# Iterate through different granularities
for n in [365, 182, 121]
    year = 2018
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

    # Function to run the model with a specified solver
    function run_model(solver)
        global building_time, solving_time, objective_list, n_var, n_constr
        
        # Initialize model
        model = Model(solver)
        
        # Set model parameters and optimizations (Insert your model-building steps here)
        
        # Measure building time
        b = @elapsed begin
            # Build the model here...
        end
        
        # Measure solving time
        s = @elapsed begin
            optimize!(model)
        end

        # Capture results
        if termination_status(model) == MOI.OPTIMAL
            objective = objective_value(model)
            n_v = num_variables(model)
            n_c = sum(num_constraints(model, F, S) for (F, S) in list_of_constraint_types(model))

            # Append results to arrays
            append!(building_time, b)
            append!(solving_time, s)
            append!(objective_list, objective)
            append!(n_var, n_v)
            append!(n_constr, n_c)
        else
            println("Termination status: ", termination_status(model))
        end
    end

    # Run with CPLEX Solver
    building_time, solving_time, objective_list, n_var, n_constr = building_time_cplex, solving_time_cplex, objective_list_cplex, n_var_cplex, n_constr_cplex
    run_model(CPLEX.Optimizer)

    # Run with HiGHS Solver
    building_time, solving_time, objective_list, n_var, n_constr = building_time_highs, solving_time_highs, objective_list_highs, n_var_highs, n_constr_highs
    run_model(HiGHS.Optimizer)
end

# Write CPLEX results to a text file
io_cplex = open(joinpath(resultdir, "result_cplex.txt"), "w")
for (b, s, o, v, c) in zip(building_time_cplex, solving_time_cplex, objective_list_cplex, n_var_cplex, n_constr_cplex)
    println(io_cplex, Dict("building" => b, "solve" => s, "Objective" => o, "#Var" => v, "#Constr" => c))
end
close(io_cplex)

# Write HiGHS results to a text file
io_highs = open(joinpath(resultdir, "result_highs.txt"), "w")
for (b, s, o, v, c) in zip(building_time_highs, solving_time_highs, objective_list_highs, n_var_highs, n_constr_highs)
    println(io_highs, Dict("building" => b, "solve" => s, "Objective" => o, "#Var" => v, "#Constr" => c))
end
close(io_highs)

# Compare and print the results
println("Comparison of CPLEX and HiGHS Solvers:")
for i in 1:length(building_time_cplex)
    println("For time granularity $(i):")
    println("CPLEX -> Building: $(building_time_cplex[i]), Solving: $(solving_time_cplex[i]), Objective: $(objective_list_cplex[i])")
    println("HiGHS -> Building: $(building_time_highs[i]), Solving: $(solving_time_highs[i]), Objective: $(objective_list_highs[i])")
end
