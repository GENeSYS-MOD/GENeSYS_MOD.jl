# GENeSYS-MOD v3.1 [Global Energy System Model]  ~ March 2022
#
# #############################################################
#
# Copyright 2020 Technische Universität Berlin and DIW Berlin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# #############################################################

"""
Run the simple dispatch model. A previous run is necessary to allow to read in investment 
decisions. For information about the switches, refer to the datastructure documentation
"""
function genesysmod_simple_dispatch(; solver, DNLPsolver, year=2018,
        model_region="minimal", data_base_region="DE", data_file="Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_new",
        hourly_data_file = "Hourly_Data_Europe_v09_kl_23_02_2022", threads=4, emissionPathway="MinimalExample",
        emissionScenario="globalLimit", socialdiscountrate=0.05,  inputdir="Inputdata\\",resultdir="Results\\",
        switch_investLimit=1, switch_ccs=1, switch_ramping=0,switch_weighted_emissions=1,switch_intertemporal=0,
        switch_base_year_bounds = 1,switch_peaking_capacity = 1, set_peaking_slack =1.0, set_peaking_minrun_share =0.15, 
        set_peaking_res_cf=0.5, set_peaking_startyear = 2025, switch_peaking_with_storages = 0, switch_peaking_with_trade = 0,switch_peaking_minrun = 1,
        switch_employment_calculation = 0, switch_endogenous_employment = 0, employment_data_file = "",  
        elmod_dunkelflaute = 0, switch_raw_results = 0, switch_processed_results = 1, write_reduced_timeserie = 0)
    
    elmod_daystep = 0
    elmod_hourstep = 1
    elmod_nthhour = 1
    elmod_starthour = 1
    switch_dispatch = 1
    switch_infeasibility_tech = 1
    
    if !isdir(resultdir)
        mkdir(resultdir)
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
    elmod_daystep,
    elmod_hourstep,
    switch_raw_results,
    switch_processed_results,
    write_reduced_timeserie)

    starttime= Dates.now()
    model= JuMP.Model()

    #
    # ####### Load data from provided excel files and declarations #############
    #
    println(Dates.now()-starttime)
    Sets, Subsets, Params, Emp_Sets = GENeSYS_MOD.genesysmod_dataload(Switch);
    println(Dates.now()-starttime)
    GENeSYS_MOD.genesysmod_dec(model,Sets,Subsets,Params,Switch)
    println(Dates.now()-starttime)
    #
    # ####### Settings for model run (Years, Regions, etc) #############
    #

    Settings=GENeSYS_MOD.genesysmod_settings(Sets, Subsets, Params, Switch.socialdiscountrate)
    println(Dates.now()-starttime)
    #
    # ####### apply general model bounds #############
    #

    GENeSYS_MOD.genesysmod_bounds(model,Sets,Subsets,Params,Settings,Switch)
    println(Dates.now()-starttime)
    #
    # ####### Including Equations #############
    #

    GENeSYS_MOD.genesysmod_equ(model,Sets,Subsets,Params,Emp_Sets,Settings,Switch)
    println(Dates.now()-starttime)
    #
    # ####### Fix Investment Variables #############
    #
    # read investment results for relevant variables
    in_data=CSV.read(joinpath(Switch.resultdir, "TotalCapacityAnnual_" * Switch.model_region * "_" * Switch.emissionPathway * "_" * Switch.emissionScenario * ".csv"), DataFrame)
    tmp_TotalCapacityAnnual = GENeSYS_MOD.create_daa(in_data, "Par_TotalCapacityAnnual", data_base_region, Sets.Year, Sets.Technology, Sets.Region_full)
    in_data=CSV.read(joinpath(Switch.resultdir, "TotalTradeCapacity_" * Switch.model_region * "_" * Switch.emissionPathway * "_" * Switch.emissionScenario * ".csv"), DataFrame)
    tmp_TotalTradeCapacity = GENeSYS_MOD.create_daa(in_data, "Par_TotalTradeCapacity", data_base_region, Sets.Year, Sets.Fuel, Sets.Region_full, Sets.Region_full)
    in_data=CSV.read(joinpath(Switch.resultdir, "NewStorageCapacity_" * Switch.model_region * "_" * Switch.emissionPathway * "_" * Switch.emissionScenario * ".csv"), DataFrame)
    tmp_NewStorageCapacity = GENeSYS_MOD.create_daa(in_data, "Par_NewStorageCapacity", data_base_region, Sets.Storage, Sets.Year, Sets.Region_full)
    #= in_data=CSV.read(joinpath(Switch.resultdir, "NetTradeAnnual_" * Switch.model_region * "_" * Switch.emissionPathway * "_" * Switch.emissionScenario * ".csv"), DataFrame)
    tmp_NetTradeAnnual = GENeSYS_MOD.create_daa(in_data, "Par_NetTradeAnnual", data_base_region, Sets.Year, Sets.Fuel, Sets.Region_full) =#
    # make constraints fixing investments
    for y ∈ Sets.Year for r ∈ Sets.Region_full
        for t ∈ setdiff(Sets.Technology, Subsets.DummyTechnology)
            @constraint(model, model[:TotalCapacityAnnual][y,t,r] == tmp_TotalCapacityAnnual[y,t,r],
            base_name="Fix_Investments_$(y)_$(t)_$(r)")
        end
        if Switch.switch_infeasibility_tech == 1
            for t ∈ Subsets.DummyTechnology
                @constraint(model, model[:TotalCapacityAnnual][y,t,r] == 99999,
                base_name="Fix_Investments_$(y)_$(t)_$(r)")
            end
        end
        for s ∈ Sets.Storage
            @constraint(model, model[:NewStorageCapacity][s,y,r] == tmp_NewStorageCapacity[s,y,r],
            base_name="Fix_NewStorageCapacity_$(s)_$(y)_$(r)")
        end
    end end
    for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full for rr ∈ Sets.Region_full
        @constraint(model, model[:TotalTradeCapacity][y,f,r,rr] == tmp_TotalTradeCapacity[y,f,r,rr],
        base_name="Fix_TradeConnection_$(y)_$(f)_$(r)_$(rr)")
    end end end end
    #
    # ####### CPLEX Options #############
    #

    set_optimizer(model, solver)

    if string(solver) == "Gurobi.Optimizer"
        set_optimizer_attribute(model, "Threads", threads)
        #set_optimizer_attribute(model, "Names", "no")
        set_optimizer_attribute(model, "Method", 2)
        set_optimizer_attribute(model, "BarHomogeneous", 1)
        set_optimizer_attribute(model, "ResultFile", "Solution_julia.sol")
    elseif string(solver) == "CPLEX.Optimizer"
        set_optimizer_attribute(model, "CPX_PARAM_THREADS", threads)
        set_optimizer_attribute(model, "CPX_PARAM_PARALLELMODE", -1)
        set_optimizer_attribute(model, "CPX_PARAM_LPMETHOD", 4)
        #set_optimizer_attribute(model, "CPX_PARAM_BAROBJRNG", 1e+075)
    end


    file = open("cplex.opt","w")
    write(file,"threads $threads ")
    write(file,"parallelmode -1 ")
    write(file,"lpmethod 4 ")
    #names no
    #solutiontype 2
    write(file,"quality yes ")
    write(file,"barobjrng 1e+075 ")
    write(file,"tilim 1000000 ")
    close(file)

    file = open("gurobi.opt","w")
    write(file,"threads $threads ")
    write(file,"method 2 ")
    write(file,"names no ")
    write(file,"barhomogeneous 1 ")
    write(file,"timelimit 1000000 ")
    close(file)

    file = open("osigurobi.opt","w")
    write(file,"threads $threads ")
    write(file,"method 2 ")
    write(file,"names no ")
    write(file,"barhomogeneous 1 ")
    write(file,"timelimit 1000000 ")
    close(file)

    println("model_region = $model_region")
    println("data_base_region = $data_base_region")
    println("data_file = $data_file")
    println("solver = $solver")
    optimize!(model)

    if termination_status(model) == MOI.INFEASIBLE
        println("Model Infeasible! Computing IIS")
        compute_conflict!(model)
        println("Saving IIS to file")
        print_iis(model)
        
        #
        # ####### Creating Result Files #############
        #
    
    elseif termination_status(model) == MOI.OPTIMAL
        VarPar = GENeSYS_MOD.genesysmod_variable_parameter(model, Sets, Params)
        
        elapsed = (Dates.now() - starttime)#24#3600;

        println(elapsed)

        if switch_processed_results == 1
            GENeSYS_MOD.genesysmod_results(model, Sets, Subsets, Params, VarPar, Switch, Settings, elapsed,"dispatch")
        end
        if switch_raw_results == 1
            GENeSYS_MOD.genesysmod_results_raw(model, Switch,"dispatch")
        end
    else
        println(termination_status(model))
    end

    return model, Dict("Sets" => Sets, "Subsets" => Subsets, "Params" => Params, "Switch" => Switch)
end