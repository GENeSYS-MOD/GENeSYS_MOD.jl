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
function genesysmod_dataload_two_nodes(Switch, considered_region)

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
         "Infeasibility_HHI", "Infeasibility_HRI", "Infeasibility_Mob_Passenger", "Infeasibility_Mob_Freight", "Infeasibility_CLB"])
        push!(Sector,"Infeasibility")
    end

    Considered_region = [considered_region, "ROE", "World"]
    
    Timeslice = [x for x in Timeslice_full if (x-Switch.elmod_starthour)%(Switch.elmod_nthhour) == 0]

    Sets=GENeSYS_MOD.Sets(Timeslice_full,Emission,Technology,Fuel,
        Year,Timeslice,Mode_of_operation,Considered_region,Storage,ModalType,Sector)

    Sets_full = GENeSYS_MOD.Sets(Timeslice_full,Emission,Technology,Fuel,
    Year,Timeslice,Mode_of_operation,Region_full,Storage,ModalType,Sector)

    tag_data = XLSX.readxlsx(joinpath(inputdir, "Tag_Subsets.xlsx"))
    DataFrame(XLSX.gettable(tag_data["Par_TagTechnologyToSubsets"];first_row=1))
    TagTechnologyToSubsets = read_subsets(tag_data, "Par_TagTechnologyToSubsets")
    if Switch.switch_infeasibility_tech == 1
        TagTechnologyToSubsets["DummyTechnology"] = ["Infeasibility_Power", "Infeasibility_HLI", "Infeasibility_HMI",
    "Infeasibility_HHI", "Infeasibility_HRI", "Infeasibility_Mob_Passenger", "Infeasibility_Mob_Freight", "Infeasibility_CLB"]
    end
    TagFuelToSubsets = read_subsets(tag_data, "Par_TagFuelToSubsets")
    
    # Step 2: Read parameters from regional file  -> now includes World values + aggregation of the data in two nodes
    StartYear = Switch.StartYear

    𝓡_nodes = Sets.Region_full
    𝓡_full = Sets_full.Region_full
    𝓕 = Sets.Fuel
    𝓨 = Sets.Year
    𝓣 = Sets.Technology
    𝓔 = Sets.Emission
    𝓜 = Sets.Mode_of_operation
    𝓛 = Sets.Timeslice
    𝓢 = Sets.Storage
    𝓜𝓽 = Sets.ModalType
    𝓢𝓮 = Sets.Sector


    AvailabilityFactor = create_daa(in_data, "Par_AvailabilityFactor",dbr, 𝓡_nodes, 𝓣, 𝓨; inherit_base_world=true)
    InputActivityRatio = create_daa(in_data, "Par_InputActivityRatio",dbr, 𝓡_nodes, 𝓣, 𝓕, 𝓜, 𝓨; inherit_base_world=true)

    OutputActivityRatio = create_daa(in_data, "Par_OutputActivityRatio",dbr, 𝓡_nodes, 𝓣, 𝓕, 𝓜, 𝓨; inherit_base_world=true)

    CapitalCost = create_daa(in_data, "Par_CapitalCost",dbr, 𝓡_nodes, 𝓣, 𝓨; inherit_base_world=true)
    FixedCost = create_daa(in_data, "Par_FixedCost",dbr, 𝓡_nodes, 𝓣, 𝓨; inherit_base_world=true)
    VariableCost = create_daa(in_data, "Par_VariableCost",dbr, 𝓡_nodes, 𝓣, 𝓜, 𝓨; inherit_base_world=true)

    EmissionActivityRatio = create_daa(in_data, "Par_EmissionActivityRatio",dbr, 𝓡_nodes, 𝓣, 𝓜, 𝓔, 𝓨; inherit_base_world=true)
    EmissionsPenalty = create_daa(in_data, "Par_EmissionsPenalty",dbr, 𝓡_nodes, 𝓔, 𝓨)
    EmissionsPenaltyTagTechnology = create_daa(in_data, "Par_EmissionPenaltyTagTech",dbr, 𝓡_nodes, 𝓣, 𝓔, 𝓨; inherit_base_world=true)

    #CapacityFactor = create_daa(in_data, "Par_CapacityFactor",dbr, 𝓡, 𝓣, 𝓛, 𝓨)

    ReserveMargin = create_daa(in_data,"Par_ReserveMargin",dbr, 𝓡_nodes, 𝓨; inherit_base_world=true)
    ReserveMarginTagFuel = create_daa(in_data, "Par_ReserveMarginTagFuel",dbr, 𝓡_nodes, 𝓕, 𝓨; inherit_base_world=true)
    ReserveMarginTagTechnology = create_daa(in_data, "Par_ReserveMarginTagTechnology",dbr, 𝓡_nodes, 𝓣, 𝓨;inherit_base_world=true)


    CapitalCostStorage = create_daa_init(in_data, "Par_CapitalCostStorage",dbr, 0.01, 𝓡_nodes, 𝓢, 𝓨;inherit_base_world=true)
    MinStorageCharge = create_daa(in_data, "Par_MinStorageCharge",dbr, 𝓡_nodes, 𝓢, 𝓨; copy_world=true)


    CapacityToActivityUnit = create_daa(in_data, "Par_CapacityToActivityUnit",dbr, 𝓣)
    RegionalBaseYearProductionFull = create_daa(in_data, "Par_RegionalBaseYearProduction",dbr, 𝓡_full, 𝓣, 𝓕, 𝓨)
    RegionalBaseYearProduction = aggregate_daa(RegionalBaseYearProductionFull, 𝓡_nodes, 𝓡_full, 𝓣, 𝓕, 𝓨)
    SpecifiedAnnualDemandFull = create_daa(in_data, "Par_SpecifiedAnnualDemand",dbr, 𝓡_full, 𝓕, 𝓨)
    SpecifiedAnnualDemand = aggregate_daa(SpecifiedAnnualDemandFull, 𝓡_nodes, 𝓡_full, 𝓕, 𝓨)

    AnnualEmissionLimit = create_daa(in_data,"Par_AnnualEmissionLimit",dbr, 𝓔, 𝓨)
    AnnualExogenousEmissionFull = create_daa(in_data,"Par_AnnualExogenousEmission",dbr, 𝓡_full, 𝓔, 𝓨)
    AnnualExogenousEmission = aggregate_daa(AnnualExogenousEmissionFull, 𝓡_nodes, 𝓡_full, 𝓔, 𝓨)             
    AnnualSectoralEmissionLimit = create_daa(in_data, "Par_AnnualSectoralEmissionLimit",dbr, 𝓔, 𝓢𝓮, 𝓨)
    EmissionContentPerFuel = create_daa(in_data, "Par_EmissionContentPerFuel",dbr, 𝓕, 𝓔)
    RegionalAnnualEmissionLimitFull = create_daa(in_data,"Par_RegionalAnnualEmissionLimit",dbr, 𝓡_full, 𝓔, 𝓨)
    RegionalAnnualEmissionLimit = aggregate_daa(RegionalAnnualEmissionLimitFull, 𝓡_nodes, 𝓡_full, 𝓔, 𝓨)

    GrowthRateTradeCapacityFull = create_daa(in_data, "Par_GrowthRateTradeCapacity",dbr, 𝓡_full, 𝓡_full, 𝓕, 𝓨)
    GrowthRateTradeCapacity = aggregate_cross_daa(GrowthRateTradeCapacityFull, 𝓡_nodes, 𝓡_full, 𝓕, 𝓨;mode="MEAN")
    Readin_PowerTradeCapacityFull = create_daa(in_data,"Par_TradeCapacity",dbr, 𝓡_full, 𝓡_full, 𝓕, 𝓨)
    Readin_PowerTradeCapacity = aggregate_cross_daa(Readin_PowerTradeCapacityFull, 𝓡_nodes, 𝓡_full, 𝓕, 𝓨)
    Readin_TradeRoute2015Full = create_daa(in_data,"Par_TradeRoute",dbr, 𝓡_full, 𝓡_full, 𝓕)
    Readin_TradeRoute2015 = aggregate_cross_daa(Readin_TradeRoute2015Full, 𝓡_nodes, 𝓡_full, 𝓕)
    TradeCapacityGrowthCostsFull = create_daa(in_data, "Par_TradeCapacityGrowthCosts",dbr, 𝓡_full, 𝓡_full, 𝓕)
    TradeCapacityGrowthCosts = aggregate_cross_daa(TradeCapacityGrowthCostsFull, 𝓡_nodes, 𝓡_full, 𝓕;mode="MEAN")
    TradeCostsFull = create_daa(in_data,"Par_TradeCosts",dbr, 𝓕, 𝓡_full, 𝓡_full)
    TradeCosts = JuMP.Containers.DenseAxisArray(
        zeros(length(𝓕),length(𝓡_nodes),length(𝓡_nodes)), 𝓕, 𝓡_nodes, 𝓡_nodes)
    for f in 𝓕
        TradeCosts[f,𝓡_nodes[1],𝓡_nodes[2]] = (sum(TradeCostsFull[f,𝓡_nodes[1],r] for r in 𝓡_full) - TradeCostsFull[f,𝓡_nodes[1],𝓡_nodes[1]])/(length(𝓡_full)-1)
        TradeCosts[f,𝓡_nodes[2],𝓡_nodes[1]] = (sum(TradeCostsFull[f,r,𝓡_nodes[1]] for r in 𝓡_full) - TradeCostsFull[f,𝓡_nodes[1],𝓡_nodes[1]])/(length(𝓡_full)-1)
    end

    ResidualCapacityFull = create_daa(in_data, "Par_ResidualCapacity",dbr, 𝓡_full, 𝓣, 𝓨)
    ResidualCapacity = aggregate_daa(ResidualCapacityFull, 𝓡_nodes, 𝓡_full, 𝓣, 𝓨)

    TotalAnnualMaxCapacityFull = create_daa(in_data, "Par_TotalAnnualMaxCapacity",dbr, 𝓡_full, 𝓣, 𝓨)
    TotalAnnualMinCapacityFull = create_daa(in_data, "Par_TotalAnnualMinCapacity",dbr, 𝓡_full, 𝓣, 𝓨)
    TotalAnnualMinCapacity = aggregate_daa(TotalAnnualMinCapacityFull, 𝓡_nodes, 𝓡_full, 𝓣, 𝓨)
    TotalTechnologyAnnualActivityUpperLimitFull = create_daa(in_data, "Par_TotalAnnualMaxActivity",dbr, 𝓡_full, 𝓣, 𝓨)
    TotalTechnologyAnnualActivityUpperLimit = aggregate_daa(TotalTechnologyAnnualActivityUpperLimitFull, 𝓡_nodes, 𝓡_full, 𝓣, 𝓨)
    TotalTechnologyAnnualActivityLowerLimitFull = create_daa(in_data, "Par_TotalAnnualMinActivity",dbr, 𝓡_full, 𝓣, 𝓨)
    TotalTechnologyAnnualActivityLowerLimit = aggregate_daa(TotalTechnologyAnnualActivityLowerLimitFull, 𝓡_nodes, 𝓡_full, 𝓣, 𝓨)
    TotalTechnologyModelPeriodActivityUpperLimitFull = create_daa_init(in_data, "Par_ModelPeriodActivityMaxLimit",dbr, 999999, 𝓡_full, 𝓣)
    TotalTechnologyModelPeriodActivityUpperLimit = aggregate_daa(TotalTechnologyModelPeriodActivityUpperLimitFull, 𝓡_nodes, 𝓡_full, 𝓣)

    OperationalLife = create_daa(in_data, "Par_OperationalLife",dbr, 𝓣)

    RegionalCCSLimitFull = create_daa(in_data, "Par_RegionalCCSLimit",dbr, 𝓡_full)
    RegionalCCSLimit = aggregate_daa(RegionalCCSLimitFull, 𝓡_nodes, 𝓡_full)

    OperationalLifeStorage = create_daa(in_data, "Par_OperationalLifeStorage",dbr, 𝓢)
    ResidualStorageCapacityFull = create_daa(in_data, "Par_ResidualStorageCapacity",dbr, 𝓡_full, 𝓢, 𝓨)
    ResidualStorageCapacity = aggregate_daa(ResidualStorageCapacityFull, 𝓡_nodes, 𝓡_full, 𝓢, 𝓨)
    StorageLevelStartFull = create_daa(in_data, "Par_StorageLevelStart",dbr, 𝓡_full, 𝓢)
    StorageLevelStart = aggregate_daa(StorageLevelStartFull, 𝓡_nodes, 𝓡_full, 𝓢)
    TechnologyToStorage = create_daa(in_data, "Par_TechnologyToStorage",dbr, TagTechnologyToSubsets["StorageDummies"], 𝓢, 𝓜, 𝓨)
    TechnologyFromStorage = create_daa(in_data, "Par_TechnologyFromStorage",dbr, TagTechnologyToSubsets["StorageDummies"], 𝓢, 𝓜, 𝓨)

    ModalSplitByFuelAndModalTypeFull = create_daa(in_data, "Par_ModalSplitByFuel",dbr, 𝓡_full, 𝓕, 𝓨, 𝓜𝓽)
    ModalSplitByFuelAndModalType = aggregate_daa(ModalSplitByFuelAndModalTypeFull, 𝓡_nodes, 𝓡_full, 𝓕, 𝓨, 𝓜𝓽;mode="MEAN")
    TagDemandFuelToSector = create_daa(in_data, "Par_TagDemandFuelToSector",dbr, 𝓕, 𝓢𝓮)
    TagElectricTechnology = create_daa(in_data, "Par_TagElectricTechnology",dbr, 𝓣)
    TagTechnologyToModalType = create_daa(in_data, "Par_TagTechnologyToModalType",dbr, 𝓣, 𝓜, 𝓜𝓽)
    TagTechnologyToSector = create_daa(in_data, "Par_TagTechnologyToSector",dbr, 𝓣, 𝓢𝓮)


    RateOfDemand = JuMP.Containers.DenseAxisArray(zeros(length(𝓨), length(𝓛), length(𝓕), length(𝓡_nodes)), 𝓨, 𝓛, 𝓕, 𝓡_nodes)
    Demand = JuMP.Containers.DenseAxisArray(zeros(length(𝓨), length(𝓛), length(𝓕), length(𝓡_nodes)), 𝓨, 𝓛, 𝓕, 𝓡_nodes)
    TagDispatchableTechnology = JuMP.Containers.DenseAxisArray(ones(length(𝓣)), 𝓣)
    StorageMaxCapacity = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓢), length(𝓨)), 𝓡_nodes, 𝓢, 𝓨)
    TotalAnnualMaxCapacityInvestment = JuMP.Containers.DenseAxisArray(fill(999999, length(𝓡_nodes), length(𝓣), length(𝓨)), 𝓡_nodes, 𝓣, 𝓨)
    TotalAnnualMinCapacityInvestment = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓣), length(𝓨)), 𝓡_nodes, 𝓣, 𝓨)
    TotalTechnologyModelPeriodActivityLowerLimit = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓣)), 𝓡_nodes, 𝓣)

    RETagTechnology = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓣), length(𝓨)), 𝓡_nodes, 𝓣, 𝓨)
    RETagFuel = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓕), length(𝓨)), 𝓡_nodes, 𝓕, 𝓨)
    REMinProductionTarget = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓕), length(𝓨)), 𝓡_nodes, 𝓕, 𝓨)

    ModelPeriodExogenousEmission = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓔)), 𝓡_nodes, 𝓔)
    ModelPeriodEmissionLimit = JuMP.Containers.DenseAxisArray(fill(999999, length(𝓔)), 𝓔)
    RegionalModelPeriodEmissionLimit = JuMP.Containers.DenseAxisArray(fill(999999, length(𝓔), length(𝓡_nodes)), 𝓔, 𝓡_nodes)

    CurtailmentCostFactor = JuMP.Containers.DenseAxisArray(fill(0.1,length(𝓡_nodes), length(𝓕), length(𝓨)), 𝓡_nodes, 𝓕, 𝓨)
    TradeRoute = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓡_nodes), length(𝓕), length(𝓨)), 𝓡_nodes, 𝓡_nodes, 𝓕 , 𝓨)
    TradeLossFactor = JuMP.Containers.DenseAxisArray(zeros(length(𝓕), length(𝓨)), 𝓕, 𝓨)
    TradeRouteInstalledCapacity = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓡_nodes), length(𝓕), length(𝓨)), 𝓡_nodes, 𝓡_nodes, 𝓕 , 𝓨)
    TradeLossBetweenRegions = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓡_nodes), length(𝓕), length(𝓨)), 𝓡_nodes, 𝓡_nodes, 𝓕 , 𝓨)
    TradeCapacity = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓡_nodes), length(𝓕), length(𝓨)), 𝓡_nodes, 𝓡_nodes, 𝓕 , 𝓨)

    CommissionedTradeCapacity = JuMP.Containers.DenseAxisArray(zeros(length(𝓡_nodes), length(𝓡_nodes), length(𝓕), length(𝓨)), 𝓡_nodes, 𝓡_nodes, 𝓕 , 𝓨)

    SelfSufficiency = JuMP.Containers.DenseAxisArray(zeros(length(𝓨), length(𝓕), length(𝓡_nodes)), 𝓨, 𝓕 , 𝓡_nodes)


    # delete world region from region set
    deleteat!(Sets.Region_full,findall(x->x=="World",Sets.Region_full))
    deleteat!(Sets_full.Region_full,findall(x->x=="World",Sets_full.Region_full))
    deleteat!(Considered_region,findall(x->x=="World",Considered_region))

    #
    # ####### Including Subsets #############
    #

    #Subsets = make_subsets(Sets)

    #
    # ####### Assigning TradeRoutes depending on initialized Regions and Year #############
    #

    for y ∈ 𝓨
        TradeLossFactor["Power",y] = 0.00003
        for r ∈ 𝓡_nodes for rr ∈ 𝓡_nodes
            for f ∈ 𝓕
                TradeRoute[r,rr,f,y] = Readin_TradeRoute2015[r,rr,f]
                TradeLossBetweenRegions[r,rr,f,y] = TradeLossFactor[f,y]*TradeRoute[r,rr,f,y]
                TradeCapacity[r,rr,f,y] = Readin_PowerTradeCapacity[r,rr,f,y]
            end
        end end
    end

    for r ∈ 𝓡_nodes for rr ∈ 𝓡_nodes for y ∈ 𝓨[2:end]
        GrowthRateTradeCapacity[r,rr,"Power",y] = GrowthRateTradeCapacity[r,rr,"Power",𝓨[1]]
    end end end

    #
    # ####### Correction of the max capacity value #############
    #

    for r ∈ Sets_full.Region_full for t ∈ Sets.Technology for y ∈ Sets.Year
        if ((max(TotalAnnualMaxCapacityFull[r,t,y], ResidualCapacityFull[r,t,y]) >0 )
            && (max(TotalAnnualMaxCapacityFull[r,t,y], ResidualCapacityFull[r,t,y]) < 999999))
            TotalAnnualMaxCapacityFull[r,t,y] = max(TotalAnnualMaxCapacityFull[r,t,y], ResidualCapacityFull[r,t,y])
        end
    end end end

    TotalAnnualMaxCapacity = aggregate_daa(TotalAnnualMaxCapacityFull, vcat(𝓡_nodes, "World"), vcat("World",𝓡_full), 𝓣, 𝓨)


    #
    # ######### YearValue assignment #############
    #

    if Switch.switch_ramping == 1
        RampingUpFactor = create_daa(in_data, "Par_RampingUpFactor",dbr, 𝓣,𝓨)
        RampingDownFactor = create_daa(in_data, "Par_RampingDownFactor",dbr,𝓣,𝓨)
        ProductionChangeCost = create_daa(in_data, "Par_ProductionChangeCost",dbr,𝓣,𝓨)
        MinActiveProductionPerTimeslice = JuMP.Containers.DenseAxisArray(zeros(length(𝓨), length(𝓛), length(𝓕), length(𝓣), length(𝓡_nodes)), 𝓨, 𝓛, 𝓕, 𝓣, 𝓡_nodes)
    
        MinActiveProductionPerTimeslice[:,:,"Power","RES_Hydro_Large",:] .= 0.1
        MinActiveProductionPerTimeslice[:,:,"Power","RES_Hydro_Small",:] .= 0.05
    else
        RampingUpFactor = nothing
        RampingDownFactor = nothing
        ProductionChangeCost = nothing
        MinActiveProductionPerTimeslice = nothing
    end

    # supposes employment calculation = 0

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


    #
    # ####### Load from hourly Data #############
    #
    # timeseries computed on all the regions
    SpecifiedDemandProfileFull, CapacityFactorFull, x_peakingDemandFull, YearSplit = GENeSYS_MOD.timeseries_reduction(Sets_full, TagTechnologyToSubsets, Switch, SpecifiedAnnualDemandFull)

    # aggregation of the timeseries data (with ponderation for the demand profile adn the peaking demand)
    SpecifiedDemandProfile = JuMP.Containers.DenseAxisArray(zeros(length(Considered_region),length(𝓕), length(𝓛), length(𝓨)), Considered_region, 𝓕, 𝓛, 𝓨)
    for f in 𝓕 for l in 𝓛 for y in 𝓨
        sum_demand = sum(SpecifiedAnnualDemandFull[r,f,y] for r in Sets_full.Region_full if r!=Considered_region[1])
        if sum_demand!=0
            SpecifiedDemandProfile[Considered_region[2],f,l,y] = 
            sum(SpecifiedDemandProfileFull[r,f,l,y]*SpecifiedAnnualDemandFull[r,f,y] for r in Sets_full.Region_full if r!=Considered_region[1])/sum_demand
        end
        SpecifiedDemandProfile[Considered_region[1],f,l,y] = SpecifiedDemandProfileFull[Considered_region[1],f,l,y]
    end end end
    CapacityFactor = aggregate_daa(CapacityFactorFull, 𝓡_nodes, 𝓡_full, 𝓣, 𝓛, 𝓨;mode="MEAN")
    
    # no peaking constraint for the dispatch
    x_peakingDemand = aggregate_daa(x_peakingDemandFull,𝓡_nodes, 𝓡_full, 𝓢𝓮;mode="MEAN" )

    for y ∈ 𝓨 for l ∈ 𝓛 for r ∈ 𝓡_nodes
        for f ∈ 𝓕
            RateOfDemand[y,l,f,r] = SpecifiedAnnualDemand[r,f,y]*SpecifiedDemandProfile[r,f,l,y] / YearSplit[l,y]
            Demand[y,l,f,r] = RateOfDemand[y,l,f,r] * YearSplit[l,y]
            if Demand[y,l,f,r] < 0.000001
                Demand[y,l,f,r] = 0
            end
        end
        for t ∈ 𝓣
            if CapacityFactor[r,t,l,y] < 0.000001
                CapacityFactor[r,t,l,y] = 0
            end
        end
    end end end

        #
    # ####### Dummy-Technologies [enable for test purposes, if model runs infeasible] #############
    #

    if Switch.switch_infeasibility_tech == 1
        TagTechnologyToSector[TagTechnologyToSubsets["DummyTechnology"],"Infeasibility"] .= 1
        AvailabilityFactor[:,TagTechnologyToSubsets["DummyTechnology"],:] .= 0

        OutputActivityRatio[:,"Infeasibility_HLI","Heat_Low_Industrial",1,:] .= 1
        OutputActivityRatio[:,"Infeasibility_HMI","Heat_Medium_Industrial",1,:] .= 1
        OutputActivityRatio[:,"Infeasibility_HHI","Heat_High_Industrial",1,:] .= 1
        OutputActivityRatio[:,"Infeasibility_HRI","Heat_Low_Residential",1,:] .= 1
        OutputActivityRatio[:,"Infeasibility_Power","Power",1,:] .= 1
        OutputActivityRatio[:,"Infeasibility_Mob_Passenger","Mobility_Passenger",1,:] .= 1 
        OutputActivityRatio[:,"Infeasibility_Mob_Freight","Mobility_Freight",1,:] .= 1 
        OutputActivityRatio[:,"Infeasibility_CLB","Cool_Low_Building",1,:] .= 1

        CapacityToActivityUnit[TagTechnologyToSubsets["DummyTechnology"]] .= 31.56
        TotalAnnualMaxCapacity[:,TagTechnologyToSubsets["DummyTechnology"],:] .= 999999
        FixedCost[:,TagTechnologyToSubsets["DummyTechnology"],:] .= 999
        CapitalCost[:,TagTechnologyToSubsets["DummyTechnology"],:] .= 999
        VariableCost[:,TagTechnologyToSubsets["DummyTechnology"],:,:] .= 999
        AvailabilityFactor[:,TagTechnologyToSubsets["DummyTechnology"],:] .= 1
        CapacityFactor[:,TagTechnologyToSubsets["DummyTechnology"],:,:] .= 1 
        OperationalLife[TagTechnologyToSubsets["DummyTechnology"]] .= 1 
        EmissionActivityRatio[:,TagTechnologyToSubsets["DummyTechnology"],:,:,:] .= 0

        TagTechnologyToModalType["Infeasibility_Mob_Passenger",1,"MT_PSNG_ROAD"] .= 1
        TagTechnologyToModalType["Infeasibility_Mob_Passenger",1,"MT_PSNG_RAIL"] .= 1
        TagTechnologyToModalType["Infeasibility_Mob_Passenger",1,"MT_PSNG_AIR"] .= 1
        TagTechnologyToModalType["Infeasibility_Mob_Freight",1,"MT_FRT_ROAD"] .= 1
        TagTechnologyToModalType["Infeasibility_Mob_Freight",1,"MT_FRT_RAIL"] .= 1
        TagTechnologyToModalType["Infeasibility_Mob_Freight",1,"MT_FRT_SHIP"] .= 1

    end

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
    TagDemandFuelToSector,TagElectricTechnology, TagTechnologyToSubsets, TagFuelToSubsets)

    Params_full = GENeSYS_MOD.Parameters(StartYear,YearSplit,SpecifiedAnnualDemandFull,
    SpecifiedDemandProfileFull,RateOfDemand,Demand,CapacityToActivityUnit,CapacityFactorFull,
    AvailabilityFactor,OperationalLife,ResidualCapacityFull,InputActivityRatio,OutputActivityRatio,
    TagDispatchableTechnology,
    RegionalBaseYearProductionFull,RegionalCCSLimitFull,CapitalCost,VariableCost,FixedCost,
    StorageLevelStartFull,MinStorageCharge,
    OperationalLifeStorage,CapitalCostStorage,ResidualStorageCapacityFull,TechnologyToStorage,
    TechnologyFromStorage,StorageMaxCapacity,TotalAnnualMaxCapacityFull,TotalAnnualMinCapacityFull,
    TagTechnologyToSector,AnnualSectoralEmissionLimit,TotalAnnualMaxCapacityInvestment,
    TotalAnnualMinCapacityInvestment,TotalTechnologyAnnualActivityUpperLimitFull,
    TotalTechnologyAnnualActivityLowerLimitFull, TotalTechnologyModelPeriodActivityUpperLimitFull,
    TotalTechnologyModelPeriodActivityLowerLimit,ReserveMarginTagTechnology,
    ReserveMarginTagFuel,ReserveMargin,RETagTechnology,RETagFuel,REMinProductionTarget,
    EmissionActivityRatio, EmissionContentPerFuel,EmissionsPenalty,EmissionsPenaltyTagTechnology,
    AnnualExogenousEmissionFull,AnnualEmissionLimit,RegionalAnnualEmissionLimitFull,
    ModelPeriodExogenousEmission,ModelPeriodEmissionLimit,RegionalModelPeriodEmissionLimit,
    CurtailmentCostFactor,TradeRoute,TradeCostsFull,
    TradeLossFactor,TradeRouteInstalledCapacity,TradeLossBetweenRegions,CommissionedTradeCapacity,
    TradeCapacity,TradeCapacityGrowthCostsFull,GrowthRateTradeCapacityFull,SelfSufficiency,
    RampingUpFactor,RampingDownFactor,ProductionChangeCost,MinActiveProductionPerTimeslice,
    ModalSplitByFuelAndModalTypeFull,TagTechnologyToModalType,EFactorConstruction, EFactorOM,
    EFactorManufacturing, EFactorFuelSupply, EFactorCoalJobs,CoalSupply, CoalDigging,
    RegionalAdjustmentFactor, LocalManufacturingFactor, DeclineRate,x_peakingDemandFull,
    TagDemandFuelToSector,TagElectricTechnology, TagTechnologyToSubsets, TagFuelToSubsets)

    return Sets, Params, Emp_Sets, Sets_full.Region_full, Params_full
end
