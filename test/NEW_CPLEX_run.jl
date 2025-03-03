import Pkg
cd("/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl/src")
Pkg.activate(".")
Pkg.develop(path="/cluster/home/fsalenca/Spesialization_project/GENeSYS_MOD.jl")
ENV["CPLEX_STUDIO_BINARIES"] = "/cluster/home/fsalenca/CPLEX_new_install/cplex/bin/x86-64_linux"

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



building_time=[]
solving_time=[]
objective_list=[]
n_var = []
n_constr = []

# iterate through 1,2,3,4 days respectively
#for n in [365,182,121] #change granularity to inly 3 different instead of 4 : [365,182,121, 91]
    year=2018
    solver=CPLEX.Optimizer
    DNLPsolver=Ipopt.Optimizer
    model_region="minimal"
    data_base_region="DE"
    data_file="Data_Europe_GradualDevelopment_Input_cleaned_free" # Changed Full_Europe with Data_Europe_GradualDevelopment_Input_cleaned_free
    hourly_data_file="Hourly_Data_Europe_v13"
    threads=30
    emissionPathway="MinimalExample"
    emissionScenario="globalLimit"
    socialdiscountrate=0.05
    inputdir=joinpath("/cluster/home/fsalenca/oceangrid_case/Input")
    resultdir = joinpath("/cluster/home/fsalenca/Spesialization_project/dev_jl/","Input", "New_CPLEX_Results")
    switch_infeasibility_tech= 1
    switch_investLimit=1
    switch_ccs=0
    switch_ramping=0
    switch_weighted_emissions=0
    set_symmetric_transmission=0
    switch_intertemporal=0
    switch_iis = 1 # added
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
    elmod_nthhour=300
    elmod_starthour=0
    elmod_dunkelflaute=0
    elmod_daystep=0
    elmod_hourstep=0
    switch_raw_results=0
    switch_processed_results=0
    write_reduced_timeserie=0
    offshore_grid = "Meshed"
    switch_LCOE_calc=0


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
    
    starttime= Dates.now()

    model= JuMP.Model()
    Sets, Params, Emp_Sets = GENeSYS_MOD.genesysmod_dataload(Switch);
    Maps = GENeSYS_MOD.make_mapping(Sets,Params)
    Vars=GENeSYS_MOD.genesysmod_dec(model,Sets,Params,Switch,Maps)
    Settings=GENeSYS_MOD.genesysmod_settings(Sets, Params, Switch.socialdiscountrate)
    GENeSYS_MOD.genesysmod_bounds(model,Sets,Params,Vars,Settings,Switch,Maps)
    GENeSYS_MOD.genesysmod_equ(model,Sets,Params,Vars,Emp_Sets,Settings,Switch,Maps)

    set_optimizer(model, solver)

    # cplex
    set_optimizer_attribute(model, "CPX_PARAM_THREADS", threads)
    set_optimizer_attribute(model, "CPX_PARAM_PARALLELMODE", -1)
    set_optimizer_attribute(model, "CPX_PARAM_LPMETHOD", 4)

    file = open("cplex.opt","w")
    write(file,"threads $threads ")
    write(file,"parallelmode -1 ")
    write(file,"lpmethod 4 ")
    close(file)

    n = Dates.now()
    b = (n - starttime)

    optimize!(model)

    s = (n - b)

   


        VarPar = GENeSYS_MOD.genesysmod_variable_parameter(model, Sets, Params)
        open(joinpath(resultdir, "TradeInvestments_nth300_editedData.txt"), "w") do file
            objective = objective_value(model)
            println(file, "Objective = $objective")
            for v in all_variables(model)
                if value.(v) > 0
                    val = value.(v)
                    str = string(v)
                    println(file, "$str = $val")
                end
            end
            for y ∈ axes(VarPar.ProductionByTechnology)[1], l ∈ axes(VarPar.ProductionByTechnology)[2], t ∈ axes(VarPar.ProductionByTechnology)[3], f ∈ axes(VarPar.ProductionByTechnology)[4], r ∈ axes(VarPar.ProductionByTechnology)[5]
                value = VarPar.ProductionByTechnology[y,l,t,f,r]
                if value > 0
                    println(file, "ProductionByTechnology[$y,$l,$t,$f,$r] = $value")
                end
            end
            for y ∈ axes(Params.RateOfDemand)[1], l ∈ axes(Params.RateOfDemand)[2], f ∈ axes(Params.RateOfDemand)[3], r ∈ axes(Params.RateOfDemand)[4]
                value = Params.Demand[y,l,f,r] *  Params.YearSplit[l,y]
                if value > 0
                    println(file, "RateOfDemand[$y,$l,$f,$r] = $value")
                    println(file, "Demand[$y,$l,$f,$r] = $(Params.Demand[y,l,f,r])")
                end
            end
        end
        append!(building_time,[b])
        append!(solving_time,[s])
        append!(objective_list,[objective_value(model)])
        n_v = num_variables(model)
        n_c = sum(num_constraints(model, F, S) for (F, S) in list_of_constraint_types(model))
        append!(n_var, n_v)
        append!(n_constr, n_c)
        println(b, " ", s," ", objective_value(model)," ", n_v, " ",n_c)
   
#end


# write everything in a text file
io = open(joinpath(resultdir, "result_run_all.txt"), "w")
for (b, s, o, v, c) in zip(building_time, solving_time, objective_list, n_var, n_constr)
    string = [Dict(
        "building"=>b, 
        "solve"=>s, 
        "Objective"=> o, 
        "#Var" => v, 
        "#Constr" => c)]
    println(io, string)
end

