
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
using HiGHS
using CSV
using Revise
using XLSX
using DataFrames

# Data structures for comparison
solver_names = ["CPLEX", "HiGHS"]
building_time = Dict("CPLEX" => [], "HiGHS" => [])
solving_time = Dict("CPLEX" => [], "HiGHS" => [])
objective_list = Dict("CPLEX" => [], "HiGHS" => [])
n_var = Dict("CPLEX" => [], "HiGHS" => [])
n_constr = Dict("CPLEX" => [], "HiGHS" => [])

# Function to set up the model with the given solver
function solve_with_solver(solver_name, n)
    solver = solver_name == "CPLEX" ? CPLEX.Optimizer : HiGHS.Optimizer
    model = Model(solver)

    year = 2018
    model_region = "minimal"
    data_base_region = "DE"
    data_file = "Data_Europe_GradualDevelopment_Input_cleaned_free"
    hourly_data_file = "Hourly_Data_Europe_v13"

    # Record building time
    build_start = Dates.now()
    GENeSYS_MOD.build_model(model, n, year, model_region, data_base_region, data_file, hourly_data_file)
    build_end = Dates.now()
    push!(building_time[solver_name], build_end - build_start)

    # Record solving time
    solve_start = Dates.now()
    JuMP.optimize!(model)
    solve_end = Dates.now()
    push!(solving_time[solver_name], solve_end - solve_start)

    # Record results
    push!(objective_list[solver_name], JuMP.objective_value(model))
    push!(n_var[solver_name], JuMP.num_variables(model))
    push!(n_constr[solver_name], JuMP.num_constraints(model))

    return model
end

# Iterate over the time granularities and solve with both solvers
for n in [182, 121, 91]
    for solver_name in solver_names
        println("Solving for solver: $solver_name with n=$n")
        solve_with_solver(solver_name, n)
    end
end

# Output comparison results
println("Solver Comparison Results")
println("Solver | Building Time | Solving Time | Objective Value | Num Variables | Num Constraints")
for solver_name in solver_names
    for i in 1:length(building_time[solver_name])
        println("$solver_name | $(building_time[solver_name][i]) | $(solving_time[solver_name][i]) | $(objective_list[solver_name][i]) | $(n_var[solver_name][i]) | $(n_constr[solver_name][i])")
    end
end
