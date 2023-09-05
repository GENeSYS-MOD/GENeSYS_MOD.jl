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

function genesysmod(;elmod_daystep, elmod_hourstep, solver, DNLPsolver, year=2018, switch_only_load_gdx=0, switch_test_data_load=0,
    model_region="minimal", data_base_region="DE", data_file="Data_Europe_openENTRANCE_technoFriendly_combined_v00_kl_21_03_2022_new",
    timeseries_data_file="genesysmod_timeseriesdata_minimalexample_v02_kl_15_03_2023", threads=4, emissionPathway="MinimalExample",
    emissionScenario="globalLimit", socialdiscountrate=0.05,  inputdir="Inputdata\\", tempdir="TempFiles\\" ,resultdir="Results\\",
    switch_infeasibility_tech = 0, switch_investLimit=1, switch_ccs=1, switch_ramping=0,switch_weighted_emissions=1,switch_intertemporal=0,
    switch_short_term_storage=1, switch_base_year_bounds = 1,switch_peaking_capacity = 1, set_peaking_slack =1.0, set_peaking_minrun_share =0.15,
    set_peaking_res_cf=0.5, set_peaking_startyear = 2025, switch_peaking_with_storages = 0, switch_peaking_with_trade = 0,switch_peaking_minrun = 1,
    switch_employment_calculation = 0, switch_endogenous_employment = 0, employment_data_file = "", switch_dispatch = 0, 
    hourly_data_file = "Hourly_Data_Europe_v09_kl_23_02_2022",elmod_nthhour = 0, elmod_starthour = 8, elmod_dunkelflaute = 0,
    switch_raw_results = 0, switch_processed_results = 1, write_reduced_timeserie = 1)

    if elmod_nthhour != 0 && (elmod_daystep !=0 || elmod_hourstep !=0)
        @warn "Both elmod_nthhour and elmod_daystep/elmod_hourstep are defined. elmod_nthhour will be ignored. To use it, change elmod_daystep/elmod_hourstep to 0"
    elseif elmod_nthhour == 0 && elmod_daystep ==0 && elmod_hourstep ==0
        @warn "Both elmod_nthhour and elmod_daystep/elmod_hourstep are 0. Set a value to at least one of them."
    elseif elmod_nthhour != 0 && elmod_daystep ==0 && elmod_hourstep ==0
        elmod_daystep = elmod_nthhour ÷ 24
        elmod_hourstep = elmod_nthhour % 24
    elseif elmod_nthhour == 0
        elmod_nthhour = elmod_daystep*24 + elmod_hourstep
    end

    if !isdir(resultdir)
        mkdir(resultdir)
    end

    elmod_nthhour = Int64(elmod_daystep * 24 + elmod_hourstep)

    Switch = GENeSYS_MOD.Switch(year,
    switch_only_load_gdx,
    switch_test_data_load,
    solver,
    DNLPsolver,
    model_region,
    data_base_region,
    data_file,
    timeseries_data_file,
    threads,
    emissionPathway,
    emissionScenario,
    socialdiscountrate,
    inputdir,
    tempdir,
    resultdir,
    switch_infeasibility_tech,
    switch_investLimit,
    switch_ccs,
    switch_ramping,
    switch_weighted_emissions,
    switch_intertemporal,
    switch_short_term_storage,
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
    hourly_data_file,
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

    #if !set switch_unixPath              $setglobal switch_unixPath 0 end
    #if !set switch_all_regions           $setglobal switch_all_regions 1 end
    #if !set switch_infeasibility_tech    $setglobal switch_infeasibility_tech 0 end
    #if !set switch_write_output          $setglobal switch_write_output xls end
    #if !set switch_aggregate_region      $setglobal switch_aggregate_region 0 end
    #if !set switch_employment_calculation $setglobal switch_employment_calculation 0 end
    #if !set switch_only_write_results    $setglobal switch_only_write_results 0 end


    #if !set switch_peaking_minrun        $setglobal switch_peaking_minrun 1 end
    ##consider vRES only partially (1.0 consider vRES fully, 0.0 ignore vRES in peaking equation)



    #if !set eployment_data_file          $setglobal employment_data_file Employment_v01_06_11_2019 end
    #if !set hourly_data_file             $setglobal hourly_data_file Hourly_Data_Europe_v09_kl_23_02_2022 end
    #if !set timeseries                   $setglobal timeseries elmod end
    #if !set elmod_nthhour                $setglobal elmod_nthhour 1000 end
    #if !set elmod_starthour              $setglobal elmod_starthour 8 end
    #if !set elmod_dunkelflaute           $setglobal elmod_dunkelflaute 0 end
    #if !set elmod_hour_steps             $setglobal elmod_hour_steps 4 end


    #if switch_unixPath == 1
    #if !set inputdir                     $setglobal inputdir Inputdata/ end
    #if !set gdxdir                       $setglobal gdxdir GdxFiles/ end
    #if !set tempdir                      $setglobal tempdir TempFiles/ end
    #if !set resultdir                    $setglobal resultdir Results/ end
    #else
    #if !inputdir     $setglobal inputdir Inputdata\ end
    #if !set gdxdir                       $setglobal gdxdir GdxFiles\ end
    #if !set tempdir                      $setglobal tempdir TempFiles\ end
    #if !set resultdir                    $setglobal resultdir Results\ end
    #end

    #option dnlp = conopt

    ###
    ### Here, the data files for various pathway runs are defined
    ###
    #if %emissionPathway% == "SocietalCommitment" $setglobal data_file Data_Europe_openENTRANCE_SocietalCommitment_oE_v29_kh_24_02_2022
    #if %emissionPathway% == "TechnoFriendly" $setglobal data_file Data_Europe_openENTRANCE_technoFriendly_oE_v40_kh_24_02_2022
    #if %emissionPathway% == "DirectedTransition" $setglobal data_file Data_Europe_openENTRANCE_DirectedTransition_oE_v26_kh_24_02_2022
    #if %emissionPathway% == "GradualDevelopment" $setglobal data_file Data_Europe_openENTRANCE_GradualDevelopment_oE_v28_kh_24_02_2022


    #
    # ####### Load data from provided excel files and declarations #############
    #

    Sets, Subsets, Params, Emp_Sets = genesysmod_dataload(Switch)
    println(Dates.now()-starttime)
    genesysmod_dec(model,Sets,Subsets,Params,Switch)
    println(Dates.now()-starttime)
    #
    # ####### Settings for model run (Years, Regions, etc) #############
    #

    Settings=genesysmod_settings(Sets, Subsets, Params, Switch.socialdiscountrate)
    println(Dates.now()-starttime)
    #include("genesysmod_interpolation.jl")

    #if switch_aggregate_region == 1
    #    include("genesysmod_aggregate_region.jl")
    #end
    #
    # ####### apply general model bounds #############
    #

    genesysmod_bounds(model,Sets,Subsets,Params,Settings,Switch)
    println(Dates.now()-starttime)
    #
    # ####### load additional bounds and data for certain scenarios #############
    #
    #if isfile("genesysmod_scenariodata_$(model_region).jl")
    #    include("genesysmod_scenariodata_$(model_region).jl")
    #else
    #    println("HINT: No scenario data for region $(model_region) found!")
    #end


    #include("genesysmod_errorcheck.jl")

    # if switch_test_data_load == 0 end
    #if switch_only_write_results == 0 end
    #
    # ####### Including Equations #############
    #

    genesysmod_equ(model,Sets,Subsets,Params,Emp_Sets,Settings,Switch)
    println(Dates.now()-starttime)
    #
    # ####### CPLEX Options #############
    #

    set_optimizer(model, solver)
#=     set_optimizer_attribute(model, "lp", solver)
    set_optimizer_attribute(model, "limrow", 0)
    set_optimizer_attribute(model, "limcol", 0)
    set_optimizer_attribute(model, "solprintln", "off")
    set_optimizer_attribute(model, "sysout", "off")
    set_optimizer_attribute(model, "profile", 2) =#

#=     if solver == CPLEX.Optimizer
        set_optimizer_attribute(model, "CPX_PARAM_THREADS", threads)
        set_optimizer_attribute(model, "CPXPARAM_Parallel", -1)
        set_optimizer_attribute(model, "CPXPARAM_LPMethod", 4)
        #set_optimizer_attribute(model, "quality", "yes") ?
        set_optimizer_attribute(model, "CPXPARAM_Barrier_Limits_ObjRange", 1e+075)
    end =#

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


#=     println("switch_investLimit   = $switch_investLimit")
    println("switch_ccs           = $switch_ccs")
    println("switch_ramping       = $switch_ramping")
    println("switch_short_term_storage = $switch_short_term_storage")
    println("switch_all_regions = $switch_all_regions")
    println("switch_infeasibility_tech = $switch_infeasibility_tech")
    println("switch_base_year_bounds = $switch_base_year_bounds")
    println("switch_only_load_gdx = $switch_only_load_gdx") =#

    println("model_region = $model_region")
    println("data_base_region = $data_base_region")
    println("data_file = $data_file")
    #println("hourly_data_file = $hourly_data_file")
    println("solver = $solver")
    #println("timeseries = $timeseries")

#=     println("emissionScenario = $emissionScenario")
    println("emissionPathway = $emissionPathway") =#

    #println("info = $info")

    #
    # ####### Model and Solve statements #############
    #
    #model genesys /all
    #$ifthen %switch_dispatch% == 1
    #$elseIf %timeseries% == elmod
    #-def_scaling_objective
    #-def_scaling_dummy
    #-def_scaling_flh
    #-def_scaling_min
    #-def_scaling_max
    #$else
    #$endif
    #/;

#=     genesys.holdfixed = 1
    genesys.optfile = 1

    heapSizeBeforSolve = heapSize =#

    optimize!(model)
    #solve genesys minimizing z using lp;

    VarPar = genesysmod_variable_parameter(model, Sets, Params)

    #heapSizeAfterSolve = heapSize

    elapsed = (Dates.now() - starttime)#24#3600;

    println(elapsed)
    #println(elapsed,  heapSizeBeforSolve, heapSizeAfterSolve)

    #
    # ####### Creating Result Files #############
    #
    if termination_status(model) == MOI.INFEASIBLE
        println("Model Infeasible! Computing IIS")
        compute_conflict!(model)
        println("Saving IIS to file")
        print_iis(model)

    elseif termination_status(model) == MOI.OPTIMAL
        if switch_processed_results == 1
            GENeSYS_MOD.genesysmod_results(model, Sets, Subsets, Params, VarPar, Switch, Settings, elapsed,"dispatch")
        end
        if switch_raw_results == 1
            GENeSYS_MOD.genesysmod_results_raw(model, Switch,"dispatch")
        end
    else
        println(termination_status(model))
    end

    #$ifthen not %switch_write_output% == xls
    #$ifthen not %switch_write_output% == csv
    #$ifthen not %switch_write_output% == gdx
    #println("HINT: No output file format (csv, xls, gdx) specified, will reset to default and only output gdx file!")
    #$endif
    #$endif
    #$endif

    #if %switch_employment_calculation% == 1 include("genesysmod_employment.jl")

    #$endif
    return model, Dict("Sets" => Sets, "Subsets" => Subsets, "Params" => Params, "Switch" => Switch)
end