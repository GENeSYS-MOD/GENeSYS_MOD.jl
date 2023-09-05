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

function genesysmod_dataload(Switch)

    # Step 0, initial declarations, replace first part of genesysmod_dec for the julia implementation
    Timeslice_full = 1:8760
    DailyTimeBracket = 1:24
    Year_full = 2015:2100

    inputdir = Switch.inputdir
    data_base_region = Switch.data_base_region

    in_data=XLSX.readxlsx(joinpath(inputdir, Switch.data_file * ".xlsx"))

    Emission = DataFrame(XLSX.gettable(in_data["Sets"],"A";first_row=1))[!,"Emission"]
    Technology = DataFrame(XLSX.gettable(in_data["Sets"],"B";first_row=1))[!,"Technology"]
    Fuel = DataFrame(XLSX.gettable(in_data["Sets"],"C";first_row=1))[!,"Fuel"]
    Year = DataFrame(XLSX.gettable(in_data["Sets"],"D";first_row=1))[!,"Year"]
    #Timeslice = DataFrame(XLSX.gettable(in_data["Sets"],"E";first_row=1))[!,"Timeslice"]
    Mode_of_operation = DataFrame(XLSX.gettable(in_data["Sets"],"F";first_row=1))[!,"Mode_of_operation"]
    Region_full = DataFrame(XLSX.gettable(in_data["Sets"],"G";first_row=1))[!,"Region"]
    Season = DataFrame(XLSX.gettable(in_data["Sets"],"H";first_row=1))[!,"Season"]
    Daytype = DataFrame(XLSX.gettable(in_data["Sets"],"I";first_row=1))[!,"Daytype"]
    DailyTimeBracket = DataFrame(XLSX.gettable(in_data["Sets"],"J";first_row=1))[!,"Dailytimebracket"]
    Storage = DataFrame(XLSX.gettable(in_data["Sets"],"K";first_row=1))[!,"Storage"]
    ModalType = DataFrame(XLSX.gettable(in_data["Sets"],"L";first_row=1))[!,"ModalType"]
    Sector = DataFrame(XLSX.gettable(in_data["Sets"],"N";first_row=1))[!,"Sectors"]
    if Switch.switch_infeasibility_tech == 1
        append!(Technology, ["Infeasibility_Power", "Infeasibility_HLI", "Infeasibility_HMI", "Infeasibility_HHI", "Infeasibility_HRI", "Infeasibility_Mob_Passenger", "Infeasibility_Mob_Freight"])
        push!(Sector,"Infeasibility")
    end
    

    #timeserie_data=XLSX.readxlsx(joinpath(inputdir, Switch.timeseries_data_file * ".xlsx"))
    #Timeslice=DataFrame(XLSX.gettable(timeserie_data["Set_TimeSlice"],"A";header=false)...)[!,:A]
    #Timeslice_Full = 1:8760
    Timeslice = [x for x in Timeslice_full if (x-Switch.elmod_starthour)%(Switch.elmod_nthhour) == 0]


    Sets=GENeSYS_MOD.Sets(Timeslice_full,DailyTimeBracket,Year_full,Emission,Technology,Fuel,Year,Timeslice,Mode_of_operation,Region_full,Season,Daytype,Storage,ModalType,Sector)

    Subsets = make_subsets(Sets)
    
    
    # Step 2: Read parameters from regional file  -> now includes World values
    
    #SpecifiedDemandProfile = GENeSYS_MOD.SpecifiedDemandProfile(DataFrame(XLSX.gettable(timeserie_data["Par_SpecifiedDemandProfile"];first_row=1)...))
    #SpecifiedDemandProfile = specified_demand_profile(timeserie_data,Sets,"DE")

    StartYear = Switch.StartYear

    #YearSplit = year_split(timeserie_data,Sets,"DE")
    #CapacityFactor = capacity_factor(timeserie_data,Sets,"DE")

    SpecifiedAnnualDemand = create_daa(in_data, "Par_SpecifiedAnnualDemand", data_base_region, Sets.Region_full, Sets.Fuel, Sets.Year)
    #        par=SpecifiedDemandProfile   Rng=Par_SpecifiedDemandProfile!A5                  rdim=3  cdim=1
    ReserveMarginTagFuel = create_daa(in_data, "Par_ReserveMarginTagFuel", data_base_region, Sets.Region_full, Sets.Fuel, Sets.Year; copy_world=true)
    EmissionsPenalty = create_daa(in_data, "Par_EmissionsPenalty", data_base_region, Sets.Region_full, Sets.Emission, Sets.Year)
    EmissionsPenaltyTagTechnology = create_daa(in_data, "Par_EmissionPenaltyTagTech", data_base_region, Sets.Region_full, Sets.Technology, Sets.Emission, Sets.Year; inherit_base_world=true)
    ReserveMargin = create_daa(in_data,"Par_ReserveMargin", data_base_region, Sets.Region_full, Sets.Year; copy_world=true)
    AnnualExogenousEmission = create_daa(in_data,"Par_AnnualExogenousEmission", data_base_region, Sets.Region_full, Sets.Emission, Sets.Year)
    RegionalAnnualEmissionLimit = create_daa(in_data,"Par_RegionalAnnualEmissionLimit", data_base_region, Sets.Region_full, Sets.Emission, Sets.Year)
    AnnualEmissionLimit = create_daa(in_data,"Par_AnnualEmissionLimit", data_base_region, Sets.Emission, Sets.Year)
    Readin_TradeRoute2015 = create_daa(in_data,"Par_TradeRoute", data_base_region, Sets.Fuel, Sets.Region_full, Sets.Region_full)
    TradeCosts = create_daa(in_data,"Par_TradeCosts", data_base_region, Sets.Fuel, Sets.Region_full, Sets.Region_full)
    #Readin_PowerTradeCapacity = DataFrame(XLSX.gettable(in_data["Par_TradeCapacity"];first_row=5)...) #TODO check intended behaviour with Konstantin: only give value for power, not for natural gas?
    Readin_PowerTradeCapacity = create_daa(in_data,"Par_TradeCapacity", data_base_region, Sets.Fuel, Sets.Region_full, Sets.Year, Sets.Region_full)
#=     TradeCapacity = create_daa(in_data, "Par_TradeCapacity", data_base_region, Sets.Fuel, Sets.Region_full, Sets.Year, Sets.Region_full)
    TradeCapacity[filter(x->x!="Power",Sets.Fuel),:,:,:] = JuMP.Containers.DenseAxisArray(
        zeros(length(Sets.Fuel)-1, length(Sets.Region_full), length(Sets.Year),length(Sets.Region_full)), 
        filter(x->x!="Power",Sets.Fuel), Sets.Region_full, Sets.Year, Sets.Region_full) =#


    GrowthRateTradeCapacity = create_daa(in_data, "Par_GrowthRateTradeCapacity", data_base_region, Sets.Year, Sets.Fuel, Sets.Region_full, Sets.Region_full)
    TradeCapacityGrowthCosts = create_daa(in_data, "Par_TradeCapacityGrowthCosts", data_base_region, Sets.Fuel, Sets.Region_full, Sets.Region_full)
    CapacityToActivityUnit = create_daa(in_data, "Par_CapacityToActivityUnit", data_base_region, Sets.Region_full, Sets.Technology)
    InputActivityRatio = create_daa(in_data, "Par_InputActivityRatio", data_base_region, Sets.Region_full, Sets.Technology, Sets.Fuel, Sets.Mode_of_operation, Sets.Year; inherit_base_world=true)
    OutputActivityRatio = create_daa(in_data, "Par_OutputActivityRatio", data_base_region, Sets.Region_full, Sets.Technology, Sets.Fuel, Sets.Mode_of_operation, Sets.Year; inherit_base_world=true)
    FixedCost = create_daa(in_data, "Par_FixedCost", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year; inherit_base_world=true)
    CapitalCost = create_daa(in_data, "Par_CapitalCost", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year; inherit_base_world=true)
    VariableCost = create_daa(in_data, "Par_VariableCost", data_base_region, Sets.Region_full, Sets.Technology, Sets.Mode_of_operation, Sets.Year; inherit_base_world=true)
    ResidualCapacity = create_daa(in_data, "Par_ResidualCapacity", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year)
    AvailabilityFactor = create_daa(in_data, "Par_AvailabilityFactor", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year; inherit_base_world=true)
    #CapacityFactor = create_daa(in_data, "Par_CapacityFactor", data_base_region, Sets.Region_full, Sets.Technology, Sets.Timeslice, Sets.Year)
    EmissionActivityRatio = create_daa(in_data, "Par_EmissionActivityRatio", data_base_region, Sets.Region_full, Sets.Technology, Sets.Emission, Sets.Mode_of_operation, Sets.Year; inherit_base_world=true)
    EmissionContentPerFuel = create_daa(in_data, "Par_EmissionContentPerFuel", data_base_region, Sets.Fuel, Sets.Emission)
    OperationalLife = create_daa(in_data, "Par_OperationalLife", data_base_region, Sets.Region_full, Sets.Technology;inherit_base_world=true)
    TotalAnnualMaxCapacity = create_daa(in_data, "Par_TotalAnnualMaxCapacity", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year)
    TotalAnnualMinCapacity = create_daa(in_data, "Par_TotalAnnualMinCapacity", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year)
    TotalTechnologyModelPeriodActivityUpperLimit = create_daa_init(in_data, "Par_ModelPeriodActivityMaxLimit", data_base_region, 999999, Sets.Region_full, Sets.Technology)

    
    TotalTechnologyAnnualActivityUpperLimit = create_daa(in_data, "Par_TotalAnnualMaxActivity", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year)
    TotalTechnologyAnnualActivityLowerLimit = create_daa(in_data, "Par_TotalAnnualMinActivity", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year)
    ReserveMarginTagTechnology = create_daa(in_data, "Par_ReserveMarginTagTechnology", data_base_region, Sets.Region_full, Sets.Technology, Sets.Year;copy_world=true)
    RegionalCCSLimit = create_daa(in_data, "Par_RegionalCCSLimit", data_base_region, Sets.Region_full)
    TechnologyToStorage = create_daa(in_data, "Par_TechnologyToStorage", data_base_region, Sets.Year, Sets.Mode_of_operation, Subsets.StorageDummies, Sets.Storage)
    TechnologyFromStorage = create_daa(in_data, "Par_TechnologyFromStorage", data_base_region, Sets.Year, Sets.Mode_of_operation, Subsets.StorageDummies, Sets.Storage)
    StorageLevelStart = create_daa(in_data, "Par_StorageLevelStart", data_base_region, Sets.Region_full, Sets.Storage)
    StorageMaxChargeRate = create_daa(in_data, "Par_StorageMaxChargeRate", data_base_region, Sets.Region_full, Sets.Storage; inherit_base_world=true) #TODO check if shoud be copy world, only values for DE
    StorageMaxDischargeRate = create_daa(in_data, "Par_StorageMaxDischargeRate", data_base_region, Sets.Region_full, Sets.Storage; inherit_base_world=true)
    MinStorageCharge = create_daa(in_data, "Par_MinStorageCharge", data_base_region, Sets.Region_full, Sets.Storage, Sets.Year; copy_world=true)
    OperationalLifeStorage = create_daa(in_data, "Par_OperationalLifeStorage", data_base_region, Sets.Region_full, Sets.Storage, Sets.Year;inherit_base_world=true)
    CapitalCostStorage = create_daa_init(in_data, "Par_CapitalCostStorage", data_base_region, 0.01, Sets.Region_full, Sets.Storage, Sets.Year;inherit_base_world=true)
    ResidualStorageCapacity = create_daa(in_data, "Par_ResidualStorageCapacity", data_base_region, Sets.Region_full, Sets.Storage, Sets.Year)
    ModalSplitByFuelAndModalType = create_daa(in_data, "Par_ModalSplitByFuel", data_base_region, Sets.Region_full, Sets.Fuel, Sets.Year, Sets.ModalType)
    TagTechnologyToModalType = create_daa(in_data, "Par_TagTechnologyToModalType", data_base_region, Sets.Technology, Sets.Mode_of_operation, Sets.ModalType)
    BaseYearProduction = create_daa(in_data, "Par_BaseYearProduction", data_base_region, Sets.Technology, Sets.Fuel)
    RegionalBaseYearProduction = create_daa(in_data, "Par_RegionalBaseYearProduction", data_base_region, Sets.Region_full, Sets.Technology, Sets.Fuel, Sets.Year)
    TagTechnologyToSector = create_daa(in_data, "Par_TagTechnologyToSector", data_base_region, Sets.Technology, Sets.Sector)
    TagDemandFuelToSector = create_daa(in_data, "Par_TagDemandFuelToSector", data_base_region, Sets.Fuel, Sets.Sector)
    AnnualSectoralEmissionLimit = create_daa(in_data, "Par_AnnualSectoralEmissionLimit", data_base_region, Sets.Emission, Sets.Sector, Sets.Year)

    RateOfDemand = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Timeslice), length(Sets.Fuel), length(Sets.Region_full)), Sets.Year, Sets.Timeslice, Sets.Fuel, Sets.Region_full)
    Demand = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Timeslice), length(Sets.Fuel), length(Sets.Region_full)), Sets.Year, Sets.Timeslice, Sets.Fuel, Sets.Region_full)
    CapacityOfOneTechnologyUnit = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Technology), length(Sets.Region_full)), Sets.Year, Sets.Technology, Sets.Region_full)
    TagDispatchableTechnology = JuMP.Containers.DenseAxisArray(ones(length(Sets.Technology)), Sets.Technology)
    StorageMaxCapacity = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Storage), length(Sets.Year)), Sets.Region_full, Sets.Storage, Sets.Year)
    TotalAnnualMaxCapacityInvestment = JuMP.Containers.DenseAxisArray(fill(999999, length(Sets.Region_full), length(Sets.Technology), length(Sets.Year)), Sets.Region_full, Sets.Technology, Sets.Year)
    TotalAnnualMinCapacityInvestment = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Technology), length(Sets.Year)), Sets.Region_full, Sets.Technology, Sets.Year)
    TotalTechnologyModelPeriodActivityLowerLimit = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Technology)), Sets.Region_full, Sets.Technology)

    RETagTechnology = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Technology), length(Sets.Year)), Sets.Region_full, Sets.Technology, Sets.Year)
    RETagFuel = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Fuel), length(Sets.Year)), Sets.Region_full, Sets.Fuel, Sets.Year)
    REMinProductionTarget = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Fuel), length(Sets.Year)), Sets.Region_full, Sets.Fuel, Sets.Year)

    ModelPeriodExogenousEmission = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Emission)), Sets.Region_full, Sets.Emission)
    ModelPeriodEmissionLimit = JuMP.Containers.DenseAxisArray(fill(999999, length(Sets.Emission)), Sets.Emission)
    RegionalModelPeriodEmissionLimit = JuMP.Containers.DenseAxisArray(fill(999999, length(Sets.Emission), length(Sets.Region_full)), Sets.Emission, Sets.Region_full)

    CurtailmentCostFactor = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Fuel), length(Sets.Year)), Sets.Region_full, Sets.Fuel, Sets.Year)
    TradeRoute = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full), length(Sets.Region_full)), Sets.Year, Sets.Fuel, Sets.Region_full , Sets.Region_full)
    TradeLossFactor = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel)), Sets.Year, Sets.Fuel)
    TradeRouteInstalledCapacity = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full), length(Sets.Region_full)), Sets.Year, Sets.Fuel, Sets.Region_full , Sets.Region_full)
    TradeLossBetweenRegions = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full), length(Sets.Region_full)), Sets.Year, Sets.Fuel, Sets.Region_full , Sets.Region_full)
    TradeCapacity = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full), length(Sets.Region_full)), Sets.Year, Sets.Fuel, Sets.Region_full , Sets.Region_full)

    AdditionalTradeCapacity = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full), length(Sets.Region_full)), Sets.Year, Sets.Fuel, Sets.Region_full , Sets.Region_full)

    SelfSufficiency = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel), length(Sets.Region_full)), Sets.Year, Sets.Fuel , Sets.Region_full)
    TagElectricTechnology = create_daa(in_data, "Par_TagElectricTechnology", data_base_region, Sets.Technology)
    #Conversionls = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Timeslice), length(Sets.Season)), Sets.Timeslice, Sets.Season)
    #Conversionld = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Timeslice), length(Sets.Daytype)), Sets.Timeslice, Sets.Daytype)
    #Conversionlh = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Timeslice), length(Sets.DailyTimeBracket)), Sets.Timeslice, Sets.DailyTimeBracket)
    #DaySplit = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Timeslice)), Sets.Year, Sets.Timeslice)

    #
    # ####### Including Subsets #############
    #

    #Subsets = make_subsets(Sets)

    deleteat!(Sets.Region_full,findall(x->x=="World",Sets.Region_full))

    #
    # ####### Assigning TradeRoutes depending on initialized Regions and Year #############
    #

    for y ∈ Sets.Year
        TradeLossFactor[y,"Power"] = 0.00003
        for r ∈ Sets.Region_full for rr ∈ Sets.Region_full
            for f ∈ Sets.Fuel
                TradeRoute[y,f,r,rr] = Readin_TradeRoute2015[f,r,rr]
                TradeLossBetweenRegions[y,f,r,rr] = TradeLossFactor[y,f]*TradeRoute[y,f,r,rr]
            end
            TradeCapacity[y,"Power",r,rr] = Readin_PowerTradeCapacity["Power",r,y,rr]
        end end
    end

    for r ∈ Sets.Region_full for rr ∈ Sets.Region_full for y ∈ Sets.Year[2:end]
        GrowthRateTradeCapacity[y,"Power",r,rr] = GrowthRateTradeCapacity[Sets.Year[1],"Power",r,rr]
    end end end


    #
    # ######### Missing in Excel, Overwriten later in scenario data #############
    #

  

    #
    # ######### YearValue assignment #############
    #
    #YearVal(y) = y.val ; # probably not necessary for Julia

    if Switch.switch_ramping == 1
        RampingUpFactor = create_daa(in_data, "Par_RampingUpFactor", data_base_region, Sets.Technology,Sets.Year)
        RampingDownFactor = create_daa(in_data, "Par_RampingDownFactor", data_base_region,Sets.Technology,Sets.Year)
    else
        RampingUpFactor = nothing
        RampingDownFactor = nothing
        ProductionChangeCost = nothing
        MinActiveProductionPerTimeslice = nothing
    end

    if Switch.switch_employment_calculation == 1
        ########## Dataload of Employment Excel ##########
        employment_data = XLSX.readxlsx(joinpath(inputdir, Switch.employment_data_file * ".xlsx"))

        Technology = DataFrame(XLSX.gettable(employment_data["Sets"],"A";first_row=1)...)[!,"Technology"]
        Year = DataFrame(XLSX.gettable(employment_data["Sets"],"D";first_row=1)...)[!,"Year"]
        Region = DataFrame(XLSX.gettable(employment_data["Sets"],"G";first_row=1)...)[!,"Region"]

        Emp_Sets=GENeSYS_MOD.Emp_Sets(Technology,Year,Region)


        EFactorConstruction = create_daa(employment_data, "Par_EFactorConstruction", data_base_region, Emp_Sets.Technology, Emp_Sets.Year)
        EFactorOM = create_daa(employment_data, "Par_EFactorOM", data_base_region, Emp_Sets.Technology, Emp_Sets.Year)
        EFactorManufacturing = create_daa(employment_data, "Par_EFactorManufacturing", data_base_region, Emp_Sets.Technology, Emp_Sets.Year)
        EFactorFuelSupply = create_daa(employment_data, "Par_EFactorFuelSupply", data_base_region, Emp_Sets.Technology, Emp_Sets.Year)
        EFactorCoalJobs = create_daa(employment_data, "Par_EFactorCoalJobs", data_base_region, Emp_Sets.Technology, Emp_Sets.Year)
        CoalSupply = create_daa(employment_data, "Par_CoalSupply", data_base_region, Sets.Region_full, Emp_Sets.Year)
        CoalDigging = create_daa(employment_data, "Par_CoalDigging", data_base_region, Switch.model_region, Emp_Sets.Technology, "$(Switch.emissionPathway)_$(Switch.emissionScenario)", Sets.Year)
        RegionalAdjustmentFactor = create_daa(employment_data, "PAR_RegionalAdjustmentFactor", data_base_region, Switch.model_region, Emp_Sets.Year)
        LocalManufacturingFactor = create_daa(employment_data, "PAR_LocalManufacturingFactor", data_base_region, Switch.model_region, Emp_Sets.Year)
        DeclineRate = create_daa(employment_data, "PAR_DeclineRate", data_base_region, Emp_Sets.Technology, Emp_Sets.Year)

    else
        EFactorConstruction = nothing
        EFactorOM = nothing
        EFactorManufacturing = nothing
        EFactorFuelSupply = nothing
        EFactorCoalJobs = nothing
        CoalSupply = nothing
        CoalDigging = nothing
        RegionalAdjustmentFactor = nothing
        LocalManufacturingFactor = nothing
        DeclineRate = nothing

        Emp_Sets=GENeSYS_MOD.Emp_Sets(nothing,nothing,nothing)
    end

#=     if Switch.switch_peaking_capacity == 1
        x_peakingDemand = read_x_peakingDemand(timeserie_data, Sets, "DE")
    else
        x_peakingDemand = nothing
    end =#

    #
    # ####### Load from hourly Data #############
    #
    
    SpecifiedDemandProfile, CapacityFactor, x_peakingDemand, YearSplit, DaySplit, Conversionls, Conversionld, Conversionlh = GENeSYS_MOD.timeseries_reduction(Sets, Subsets, Switch, SpecifiedAnnualDemand)

    #$elseif %timeseries% == classic
    #$offlisting
    #$include genesysmod_timeseries_timeslices.gms

    #CapacityFactor(r,Solar,'Q1N',y) = 0;
    #CapacityFactor(r,Solar,'Q2N',y) = 0;
    #CapacityFactor(r,Solar,'Q3N',y) = 0;
    #CapacityFactor(r,Solar,'Q4N',y) = 0;
    #$endif

    Params = GENeSYS_MOD.Parameters(StartYear,YearSplit,SpecifiedAnnualDemand,SpecifiedDemandProfile,RateOfDemand,Demand,CapacityToActivityUnit,CapacityFactor,AvailabilityFactor,OperationalLife,ResidualCapacity,InputActivityRatio,OutputActivityRatio,
    CapacityOfOneTechnologyUnit,TagDispatchableTechnology,BaseYearProduction,RegionalBaseYearProduction,RegionalCCSLimit,CapitalCost,VariableCost,FixedCost,StorageLevelStart,StorageMaxChargeRate,
    StorageMaxDischargeRate,MinStorageCharge,OperationalLifeStorage,CapitalCostStorage,ResidualStorageCapacity,TechnologyToStorage,TechnologyFromStorage,StorageMaxCapacity,TotalAnnualMaxCapacity,TotalAnnualMinCapacity,
    TagTechnologyToSector,AnnualSectoralEmissionLimit,TotalAnnualMaxCapacityInvestment,TotalAnnualMinCapacityInvestment,TotalTechnologyAnnualActivityUpperLimit,TotalTechnologyAnnualActivityLowerLimit,
    TotalTechnologyModelPeriodActivityUpperLimit,TotalTechnologyModelPeriodActivityLowerLimit,ReserveMarginTagTechnology,ReserveMarginTagFuel,ReserveMargin,RETagTechnology,RETagFuel,REMinProductionTarget,EmissionActivityRatio,
    EmissionContentPerFuel,EmissionsPenalty,EmissionsPenaltyTagTechnology,AnnualExogenousEmission,AnnualEmissionLimit,RegionalAnnualEmissionLimit,ModelPeriodExogenousEmission,ModelPeriodEmissionLimit,RegionalModelPeriodEmissionLimit,
    CurtailmentCostFactor,Readin_TradeRoute2015,Readin_PowerTradeCapacity,TradeRoute,TradeCosts,TradeLossFactor,TradeRouteInstalledCapacity,TradeLossBetweenRegions,AdditionalTradeCapacity,TradeCapacity,TradeCapacityGrowthCosts,GrowthRateTradeCapacity,SelfSufficiency,Conversionls,Conversionld,
    Conversionlh, DaySplit,RampingUpFactor,RampingDownFactor,ProductionChangeCost,MinActiveProductionPerTimeslice,ModalSplitByFuelAndModalType,TagTechnologyToModalType,
    EFactorConstruction, EFactorOM, EFactorManufacturing, EFactorFuelSupply, EFactorCoalJobs, CoalSupply, CoalDigging, RegionalAdjustmentFactor, LocalManufacturingFactor, DeclineRate, x_peakingDemand,TagDemandFuelToSector,TagElectricTechnology)

    return Sets, Subsets, Params, Emp_Sets
end