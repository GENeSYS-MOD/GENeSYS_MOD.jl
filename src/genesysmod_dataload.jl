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
Internal function used in the run process to load the input data and create the reduced timeseries.
"""
function genesysmod_dataload(Switch)

    # Step 0, initial declarations, replace first part of genesysmod_dec for the julia implementation
    Timeslice_full = 1:8760

    inputdir = Switch.inputdir
    dbr = Switch.data_base_region

    in_data=XLSX.readxlsx(joinpath(inputdir, Switch.data_file * ".xlsx"))

    Emission = DataFrame(XLSX.gettable(in_data["Sets"],"F";first_row=1))[!,"Emission"]
    Technology = DataFrame(XLSX.gettable(in_data["Sets"],"B";first_row=1))[!,"Technology"]
    Fuel = DataFrame(XLSX.gettable(in_data["Sets"],"D";first_row=1))[!,"Fuel"]
    Year = DataFrame(XLSX.gettable(in_data["Sets"],"I";first_row=1))[!,"Year"]
    Mode_of_operation = DataFrame(XLSX.gettable(in_data["Sets"],"E";first_row=1))[!,"Mode_of_operation"]
    Region_full = DataFrame(XLSX.gettable(in_data["Sets"],"A";first_row=1))[!,"Region"]
    Storage = DataFrame(XLSX.gettable(in_data["Sets"],"C";first_row=1))[!,"Storage"]
    ModalType = DataFrame(XLSX.gettable(in_data["Sets"],"G";first_row=1))[!,"ModalType"]
    Sector = DataFrame(XLSX.gettable(in_data["Sets"],"H";first_row=1))[!,"Sector"]
    if Switch.switch_infeasibility_tech == 1
        append!(Technology, ["Infeasibility_Power", "Infeasibility_HLI", "Infeasibility_HMI",
         "Infeasibility_HHI", "Infeasibility_HRI", "Infeasibility_Mob_Passenger", "Infeasibility_Mob_Freight"])
        push!(Sector,"Infeasibility")
    end
    
    Timeslice = [x for x in Timeslice_full if (x-Switch.elmod_starthour)%(Switch.elmod_nthhour) == 0]

    Sets=GENeSYS_MOD.Sets(Timeslice_full,Emission,Technology,Fuel,
        Year,Timeslice,Mode_of_operation,Region_full,Storage,ModalType,Sector)

    Subsets = make_subsets(Sets)
    
    
    # Step 2: Read parameters from regional file  -> now includes World values
    StartYear = Switch.StartYear

    𝓡 = Sets.Region_full
    𝓕 = Sets.Fuel
    𝓨 = Sets.Year
    𝓣 = Sets.Technology
    𝓔 = Sets.Emission
    𝓜 = Sets.Mode_of_operation
    𝓛 = Sets.Timeslice
    𝓢 = Sets.Storage
    𝓜𝓽 = Sets.ModalType
    𝓢𝓮 = Sets.Sector


    AvailabilityFactor = create_daa(in_data, "Par_AvailabilityFactor",dbr, 𝓡, 𝓣, 𝓨; inherit_base_world=true)
    InputActivityRatio = create_daa(in_data, "Par_InputActivityRatio",dbr, 𝓡, 𝓣, 𝓕, 𝓜, 𝓨; inherit_base_world=true)

    OutputActivityRatio = create_daa(in_data, "Par_OutputActivityRatio",dbr, 𝓡, 𝓣, 𝓕, 𝓜, 𝓨; inherit_base_world=true)

    CapitalCost = create_daa(in_data, "Par_CapitalCost",dbr, 𝓡, 𝓣, 𝓨; inherit_base_world=true)
    FixedCost = create_daa(in_data, "Par_FixedCost",dbr, 𝓡, 𝓣, 𝓨; inherit_base_world=true)
    VariableCost = create_daa(in_data, "Par_VariableCost",dbr, 𝓡, 𝓣, 𝓜, 𝓨; inherit_base_world=true)

    EmissionActivityRatio = create_daa(in_data, "Par_EmissionActivityRatio",dbr, 𝓡, 𝓣, 𝓜, 𝓔, 𝓨; inherit_base_world=true)
    EmissionsPenalty = create_daa(in_data, "Par_EmissionsPenalty",dbr, 𝓡, 𝓔, 𝓨)
    EmissionsPenaltyTagTechnology = create_daa(in_data, "Par_EmissionPenaltyTagTech",dbr, 𝓡, 𝓣, 𝓔, 𝓨; inherit_base_world=true)

    #CapacityFactor = create_daa(in_data, "Par_CapacityFactor",dbr, 𝓡, 𝓣, 𝓛, 𝓨)

    ReserveMargin = create_daa(in_data,"Par_ReserveMargin",dbr, 𝓡, 𝓨; inherit_base_world=true)
    ReserveMarginTagFuel = create_daa(in_data, "Par_ReserveMarginTagFuel",dbr, 𝓡, 𝓕, 𝓨; inherit_base_world=true)
    ReserveMarginTagTechnology = create_daa(in_data, "Par_ReserveMarginTagTechnology",dbr, 𝓡, 𝓣, 𝓨;inherit_base_world=true)


    CapitalCostStorage = create_daa_init(in_data, "Par_CapitalCostStorage",dbr, 0.01, 𝓡, 𝓢, 𝓨;inherit_base_world=true)
    MinStorageCharge = create_daa(in_data, "Par_MinStorageCharge",dbr, 𝓡, 𝓢, 𝓨; copy_world=true)


    CapacityToActivityUnit = create_daa(in_data, "Par_CapacityToActivityUnit",dbr, 𝓣)
    RegionalBaseYearProduction = create_daa(in_data, "Par_RegionalBaseYearProduction",dbr, 𝓡, 𝓣, 𝓕, 𝓨)
    SpecifiedAnnualDemand = create_daa(in_data, "Par_SpecifiedAnnualDemand",dbr, 𝓡, 𝓕, 𝓨)

    AnnualEmissionLimit = create_daa(in_data,"Par_AnnualEmissionLimit",dbr, 𝓔, 𝓨)
    AnnualExogenousEmission = create_daa(in_data,"Par_AnnualExogenousEmission",dbr, 𝓡, 𝓔, 𝓨)             
    AnnualSectoralEmissionLimit = create_daa(in_data, "Par_AnnualSectoralEmissionLimit",dbr, 𝓔, 𝓢𝓮, 𝓨)
    EmissionContentPerFuel = create_daa(in_data, "Par_EmissionContentPerFuel",dbr, 𝓕, 𝓔)
    RegionalAnnualEmissionLimit = create_daa(in_data,"Par_RegionalAnnualEmissionLimit",dbr, 𝓡, 𝓔, 𝓨)

    GrowthRateTradeCapacity = create_daa(in_data, "Par_GrowthRateTradeCapacity",dbr, 𝓡, 𝓡, 𝓕, 𝓨)
    Readin_PowerTradeCapacity = create_daa(in_data,"Par_TradeCapacity",dbr, 𝓡, 𝓡, 𝓕, 𝓨)
    Readin_TradeRoute2015 = create_daa(in_data,"Par_TradeRoute",dbr, 𝓡, 𝓡, 𝓕)
    TradeCapacityGrowthCosts = create_daa(in_data, "Par_TradeCapacityGrowthCosts",dbr, 𝓡, 𝓡, 𝓕)
    TradeCosts = create_daa(in_data,"Par_TradeCosts",dbr, 𝓕, 𝓡, 𝓡)

    ResidualCapacity = create_daa(in_data, "Par_ResidualCapacity",dbr, 𝓡, 𝓣, 𝓨)

    TotalAnnualMaxCapacity = create_daa(in_data, "Par_TotalAnnualMaxCapacity",dbr, 𝓡, 𝓣, 𝓨)
    TotalAnnualMinCapacity = create_daa(in_data, "Par_TotalAnnualMinCapacity",dbr, 𝓡, 𝓣, 𝓨)
    TotalTechnologyAnnualActivityUpperLimit = create_daa(in_data, "Par_TotalAnnualMaxActivity",dbr, 𝓡, 𝓣, 𝓨)
    TotalTechnologyAnnualActivityLowerLimit = create_daa(in_data, "Par_TotalAnnualMinActivity",dbr, 𝓡, 𝓣, 𝓨)
    TotalTechnologyModelPeriodActivityUpperLimit = create_daa_init(in_data, "Par_ModelPeriodActivityMaxLimit",dbr, 999999, 𝓡, 𝓣)

    OperationalLife = create_daa(in_data, "Par_OperationalLife",dbr, 𝓣)

    RegionalCCSLimit = create_daa(in_data, "Par_RegionalCCSLimit",dbr, 𝓡)

    OperationalLifeStorage = create_daa(in_data, "Par_OperationalLifeStorage",dbr, 𝓢)
    ResidualStorageCapacity = create_daa(in_data, "Par_ResidualStorageCapacity",dbr, 𝓡, 𝓢, 𝓨)
    StorageLevelStart = create_daa(in_data, "Par_StorageLevelStart",dbr, 𝓡, 𝓢)
    TechnologyToStorage = create_daa(in_data, "Par_TechnologyToStorage",dbr, Subsets.StorageDummies, 𝓢, 𝓜, 𝓨)
    TechnologyFromStorage = create_daa(in_data, "Par_TechnologyFromStorage",dbr, Subsets.StorageDummies, 𝓢, 𝓜, 𝓨)

    ModalSplitByFuelAndModalType = create_daa(in_data, "Par_ModalSplitByFuel",dbr, 𝓡, 𝓕, 𝓨, 𝓜𝓽)
    TagDemandFuelToSector = create_daa(in_data, "Par_TagDemandFuelToSector",dbr, 𝓕, 𝓢𝓮)
    TagElectricTechnology = create_daa(in_data, "Par_TagElectricTechnology",dbr, 𝓣)
    TagTechnologyToModalType = create_daa(in_data, "Par_TagTechnologyToModalType",dbr, 𝓣, 𝓜, 𝓜𝓽)
    TagTechnologyToSector = create_daa(in_data, "Par_TagTechnologyToSector",dbr, 𝓣, 𝓢𝓮)


    RateOfDemand = JuMP.Containers.DenseAxisArray(zeros(length(𝓨), length(𝓛), length(𝓕), length(𝓡)), 𝓨, 𝓛, 𝓕, 𝓡)
    Demand = JuMP.Containers.DenseAxisArray(zeros(length(𝓨), length(𝓛), length(𝓕), length(𝓡)), 𝓨, 𝓛, 𝓕, 𝓡)
    TagDispatchableTechnology = JuMP.Containers.DenseAxisArray(ones(length(𝓣)), 𝓣)
    StorageMaxCapacity = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓢), length(𝓨)), 𝓡, 𝓢, 𝓨)
    TotalAnnualMaxCapacityInvestment = JuMP.Containers.DenseAxisArray(fill(999999, length(𝓡), length(𝓣), length(𝓨)), 𝓡, 𝓣, 𝓨)
    TotalAnnualMinCapacityInvestment = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓣), length(𝓨)), 𝓡, 𝓣, 𝓨)
    TotalTechnologyModelPeriodActivityLowerLimit = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓣)), 𝓡, 𝓣)

    RETagTechnology = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓣), length(𝓨)), 𝓡, 𝓣, 𝓨)
    RETagFuel = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓕), length(𝓨)), 𝓡, 𝓕, 𝓨)
    REMinProductionTarget = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓕), length(𝓨)), 𝓡, 𝓕, 𝓨)

    ModelPeriodExogenousEmission = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓔)), 𝓡, 𝓔)
    ModelPeriodEmissionLimit = JuMP.Containers.DenseAxisArray(fill(999999, length(𝓔)), 𝓔)
    RegionalModelPeriodEmissionLimit = JuMP.Containers.DenseAxisArray(fill(999999, length(𝓔), length(𝓡)), 𝓔, 𝓡)

    CurtailmentCostFactor = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓕), length(𝓨)), 𝓡, 𝓕, 𝓨)
    TradeRoute = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓡), length(𝓕), length(𝓨)), 𝓡, 𝓡, 𝓕 , 𝓨)
    TradeLossFactor = JuMP.Containers.DenseAxisArray(zeros(length(𝓕), length(𝓨)), 𝓕, 𝓨)
    TradeRouteInstalledCapacity = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓡), length(𝓕), length(𝓨)), 𝓡, 𝓡, 𝓕 , 𝓨)
    TradeLossBetweenRegions = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓡), length(𝓕), length(𝓨)), 𝓡, 𝓡, 𝓕 , 𝓨)
    TradeCapacity = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓡), length(𝓕), length(𝓨)), 𝓡, 𝓡, 𝓕 , 𝓨)

    CommissionedTradeCapacity = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓡), length(𝓕), length(𝓨)), 𝓡, 𝓡, 𝓕 , 𝓨)

    SelfSufficiency = JuMP.Containers.DenseAxisArray(zeros(length(𝓨), length(𝓕), length(𝓡)), 𝓨, 𝓕 , 𝓡)


    # delete world region from region set
    deleteat!(Sets.Region_full,findall(x->x=="World",Sets.Region_full))

    #
    # ####### Including Subsets #############
    #

    #Subsets = make_subsets(Sets)

    #
    # ####### Assigning TradeRoutes depending on initialized Regions and Year #############
    #

    for y ∈ 𝓨
        TradeLossFactor["Power",y] = 0.00003
        for r ∈ 𝓡 for rr ∈ 𝓡
            for f ∈ 𝓕
                TradeRoute[r,rr,f,y] = Readin_TradeRoute2015[r,rr,f]
                TradeLossBetweenRegions[r,rr,f,y] = TradeLossFactor[f,y]*TradeRoute[r,rr,f,y]
                TradeCapacity[r,rr,f,y] = Readin_PowerTradeCapacity[r,rr,f,y]
            end

            for f ∈ Subsets.TradeCapacities
                TradeCapacity[y,f,r,rr] = Readin_PowerTradeCapacity[f,r,y,rr]
            end
        end end
    end

    for r ∈ 𝓡 for rr ∈ 𝓡 for y ∈ 𝓨[2:end]
        for s in Subsets.TradeCapacities
            GrowthRateTradeCapacity[y,s,r,rr] = GrowthRateTradeCapacity[𝓨[1],s,r,rr]
        end
    end end end


    #
    # ######### YearValue assignment #############
    #

    if Switch.switch_ramping == 1
        RampingUpFactor = create_daa(in_data, "Par_RampingUpFactor",dbr, 𝓣,𝓨)
        RampingDownFactor = create_daa(in_data, "Par_RampingDownFactor",dbr,𝓣,𝓨)
        ProductionChangeCost = JuMP.Containers.DenseAxisArray(zeros(length(𝓡), length(𝓣), length(𝓨)), 𝓡, 𝓣, 𝓨)
        MinActiveProductionPerTimeslice = JuMP.Containers.DenseAxisArray(zeros(length(𝓨), length(𝓛), length(𝓕), length(𝓣), length(𝓡)), 𝓨, 𝓛, 𝓕, 𝓣, 𝓡)
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


        EFactorConstruction = create_daa(employment_data, "Par_EFactorConstruction",dbr, Emp_Sets.Technology, Emp_Sets.Year)
        EFactorOM = create_daa(employment_data, "Par_EFactorOM",dbr, Emp_Sets.Technology, Emp_Sets.Year)
        EFactorManufacturing = create_daa(employment_data, "Par_EFactorManufacturing",dbr, Emp_Sets.Technology, Emp_Sets.Year)
        EFactorFuelSupply = create_daa(employment_data, "Par_EFactorFuelSupply",dbr, Emp_Sets.Technology, Emp_Sets.Year)
        EFactorCoalJobs = create_daa(employment_data, "Par_EFactorCoalJobs",dbr, Emp_Sets.Technology, Emp_Sets.Year)
        CoalSupply = create_daa(employment_data, "Par_CoalSupply",dbr, 𝓡, Emp_Sets.Year)
        CoalDigging = create_daa(employment_data, "Par_CoalDigging",dbr, Switch.model_region,
            Emp_Sets.Technology, "$(Switch.emissionPathway)_$(Switch.emissionScenario)", 𝓨)
        RegionalAdjustmentFactor = create_daa(employment_data, "PAR_RegionalAdjustmentFactor",dbr, Switch.model_region, Emp_Sets.Year)
        LocalManufacturingFactor = create_daa(employment_data, "PAR_LocalManufacturingFactor",dbr, Switch.model_region, Emp_Sets.Year)
        DeclineRate = create_daa(employment_data, "PAR_DeclineRate",dbr, Emp_Sets.Technology, Emp_Sets.Year)

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

    #
    # ####### Load from hourly Data #############
    #
    
    SpecifiedDemandProfile, CapacityFactor, x_peakingDemand, YearSplit = GENeSYS_MOD.timeseries_reduction(Sets, Subsets, Switch, SpecifiedAnnualDemand)

    for y ∈ 𝓨 for l ∈ 𝓛 for f ∈ 𝓕 for r ∈ 𝓡
        RateOfDemand[y,l,f,r] = SpecifiedAnnualDemand[r,f,y]*SpecifiedDemandProfile[r,f,l,y] / YearSplit[l,y]
        Demand[y,l,f,r] = RateOfDemand[y,l,f,r] * YearSplit[l,y]
        if Demand[y,l,f,r] < 0.000001
          Demand[y,l,f,r] = 0
        end
    end end end end

    Params = GENeSYS_MOD.Parameters(StartYear,YearSplit,SpecifiedAnnualDemand,
    SpecifiedDemandProfile,RateOfDemand,Demand,CapacityToActivityUnit,CapacityFactor,
    AvailabilityFactor,OperationalLife,ResidualCapacity,InputActivityRatio,OutputActivityRatio,
    TagDispatchableTechnology,
    RegionalBaseYearProduction,RegionalCCSLimit,CapitalCost,VariableCost,FixedCost,
    StorageLevelStart,MinStorageCharge,
    OperationalLifeStorage,CapitalCostStorage,ResidualStorageCapacity,TechnologyToStorage,
    TechnologyFromStorage,StorageMaxCapacity,TotalAnnualMaxCapacity,TotalAnnualMinCapacity,
    TagTechnologyToSector,AnnualSectoralEmissionLimit,TotalAnnualMaxCapacityInvestment,
    TotalAnnualMinCapacityInvestment,TotalTechnologyAnnualActivityUpperLimit,
    TotalTechnologyAnnualActivityLowerLimit, TotalTechnologyModelPeriodActivityUpperLimit,
    TotalTechnologyModelPeriodActivityLowerLimit,ReserveMarginTagTechnology,
    ReserveMarginTagFuel,ReserveMargin,RETagTechnology,RETagFuel,REMinProductionTarget,
    EmissionActivityRatio, EmissionContentPerFuel,EmissionsPenalty,EmissionsPenaltyTagTechnology,
    AnnualExogenousEmission,AnnualEmissionLimit,RegionalAnnualEmissionLimit,
    ModelPeriodExogenousEmission,ModelPeriodEmissionLimit,RegionalModelPeriodEmissionLimit,
    CurtailmentCostFactor,TradeRoute,TradeCosts,
    TradeLossFactor,TradeRouteInstalledCapacity,TradeLossBetweenRegions,CommissionedTradeCapacity,
    TradeCapacity,TradeCapacityGrowthCosts,GrowthRateTradeCapacity,SelfSufficiency,
    RampingUpFactor,RampingDownFactor,ProductionChangeCost,MinActiveProductionPerTimeslice,
    ModalSplitByFuelAndModalType,TagTechnologyToModalType,EFactorConstruction, EFactorOM,
    EFactorManufacturing, EFactorFuelSupply, EFactorCoalJobs,CoalSupply, CoalDigging,
    RegionalAdjustmentFactor, LocalManufacturingFactor, DeclineRate,x_peakingDemand,
    TagDemandFuelToSector,TagElectricTechnology)

    return Sets, Subsets, Params, Emp_Sets
end