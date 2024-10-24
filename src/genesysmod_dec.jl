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
function def_daa(sets...)
    daa = DenseArray{Union{Float64,VariableRef}}(
        undef, sets...);
    fill!(daa,0.0);

#=     for i in eachindex(sets...)
        if sets...[i] == Sets.Technology & any(x -> x == Sets.Mode_of_operation, sets...[i:end])
            M = findfirst(x -> x == Sets.Mode_of_operation, sets...[i:end])
            
    end
    for x... in sets... =#

    return daa
end

"""
Internal function used in the run process to define the model variables.
"""
function genesysmod_dec(model,Sets, Params,Switch, Maps)

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

    #####################
    # Model Variables #
    #####################

    ############### Capacity Variables ############
    
    NewCapacity = @variable(model, NewCapacity[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    AccumulatedNewCapacity = @variable(model, AccumulatedNewCapacity[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    TotalCapacityAnnual = @variable(model, TotalCapacityAnnual[𝓨,𝓣,𝓡] >= 0, container=DenseArray)

    ############### Activity Variables #############

    RateOfActivity = def_daa(𝓨,𝓛,𝓣,𝓜,𝓡)
    TotalAnnualTechnologyActivityByMode = def_daa(𝓨,𝓣,𝓜,𝓡)
    ProductionByTechnologyAnnual = def_daa(𝓨,𝓣,𝓕,𝓡)
    UseByTechnologyAnnual = def_daa(𝓨,𝓣,𝓕,𝓡)
    for y ∈ 𝓨 for r ∈ 𝓡 for t ∈ 𝓣
        for m ∈ Maps.Tech_MO[t]
            for l ∈ 𝓛
                RateOfActivity[y,l,t,m,r] = @variable(model, lower_bound = 0, base_name= "RateOfActivity[$y,$l,$t,$m,$r]")
            end
            TotalAnnualTechnologyActivityByMode[y,t,m,r] = @variable(model, lower_bound = 0, base_name= "TotalAnnualTechnologyActivityByMode[$y,$t,$m,$r]")
        end 
        for f ∈ Maps.Tech_Fuel[t]
            ProductionByTechnologyAnnual[y,t,f,r] = @variable(model, lower_bound = 0, base_name= "ProductionByTechnologyAnnual[$y,$t,$f,$r]")
            UseByTechnologyAnnual[y,t,f,r] = @variable(model, lower_bound = 0, base_name= "UseByTechnologyAnnual[$y,$t,$f,$r]")
        end
    end end end 
    model[:RateOfActivity] = RateOfActivity
    model[:TotalAnnualTechnologyActivityByMode] = TotalAnnualTechnologyActivityByMode
    model[:ProductionByTechnologyAnnual] = ProductionByTechnologyAnnual
    model[:UseByTechnologyAnnual] = UseByTechnologyAnnual

    @variable(model, TotalTechnologyAnnualActivity[𝓨,𝓣,𝓡] >= 0)
                
    @variable(model, TotalActivityPerYear[𝓡,𝓛,𝓣,𝓨] >= 0)
    @variable(model, CurtailedEnergyAnnual[𝓨,𝓕,𝓡] >= 0)
    @variable(model, CurtailedCapacity[𝓡,𝓛,𝓣,𝓨] >= 0)
    @variable(model, CurtailedEnergy[𝓨,𝓛,𝓕,𝓡] >= 0)
    @variable(model, DispatchDummy[𝓡,𝓛,𝓣,𝓨] >= 0)

    
    ############### Costing Variables #############

    CapitalInvestment = @variable(model, CapitalInvestment[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    DiscountedCapitalInvestment = @variable(model, DiscountedCapitalInvestment[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    SalvageValue = @variable(model, SalvageValue[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    DiscountedSalvageValue = @variable(model, DiscountedSalvageValue[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    OperatingCost = @variable(model, OperatingCost[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    DiscountedOperatingCost = @variable(model, DiscountedOperatingCost[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    AnnualVariableOperatingCost = @variable(model, AnnualVariableOperatingCost[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    AnnualFixedOperatingCost = @variable(model, AnnualFixedOperatingCost[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    VariableOperatingCost = @variable(model, VariableOperatingCost[𝓨,𝓛,𝓣,𝓡] >= 0, container=DenseArray)
    TotalDiscountedCost = @variable(model, TotalDiscountedCost[𝓨,𝓡] >= 0, container=DenseArray)
    TotalDiscountedCostByTechnology = @variable(model, TotalDiscountedCostByTechnology[𝓨,𝓣,𝓡] >= 0, container=DenseArray)
    ModelPeriodCostByRegion = @variable(model, ModelPeriodCostByRegion[𝓡] >= 0, container=DenseArray)

    AnnualCurtailmentCost = @variable(model, AnnualCurtailmentCost[𝓨,𝓕,𝓡] >= 0, container=DenseArray)
    DiscountedAnnualCurtailmentCost = @variable(model, DiscountedAnnualCurtailmentCost[𝓨,𝓕,𝓡] >= 0, container=DenseArray)

    

    ############### Storage Variables #############

    StorageLevelYearStart = @variable(model, StorageLevelYearStart[𝓢,𝓨,𝓡] >= 0, container=DenseArray)
    StorageLevelYearFinish = @variable(model, StorageLevelYearFinish[𝓢,𝓨,𝓡] >= 0, container=DenseArray)
    StorageLevelTSStart = @variable(model, StorageLevelTSStart[𝓢,𝓨,𝓛,𝓡] >= 0, container=DenseArray)
    AccumulatedNewStorageCapacity = @variable(model, AccumulatedNewStorageCapacity[𝓢,𝓨,𝓡] >= 0, container=DenseArray) 
    NewStorageCapacity = @variable(model, NewStorageCapacity[𝓢,𝓨,𝓡] >= 0, container=DenseArray) 
    CapitalInvestmentStorage = @variable(model, CapitalInvestmentStorage[𝓢,𝓨,𝓡] >= 0, container=DenseArray) 
    DiscountedCapitalInvestmentStorage = @variable(model, DiscountedCapitalInvestmentStorage[𝓢,𝓨,𝓡] >= 0, container=DenseArray) 
    SalvageValueStorage = @variable(model, SalvageValueStorage[𝓢,𝓨,𝓡] >= 0, container=DenseArray) 
    DiscountedSalvageValueStorage = @variable(model, DiscountedSalvageValueStorage[𝓢,𝓨,𝓡] >= 0, container=DenseArray) 
    TotalDiscountedStorageCost = @variable(model, TotalDiscountedStorageCost[𝓢,𝓨,𝓡] >= 0, container=DenseArray) 

    

    ######## Reserve Margin #############

    if Switch.switch_dispatch isa NoDispatch && Switch.switch_reserve == 1
        TotalActivityInReserveMargin=@variable(model, TotalActivityInReserveMargin[𝓡,𝓨,𝓛] >= 0, container=DenseArray)
        DemandNeedingReserveMargin=@variable(model, DemandNeedingReserveMargin[𝓨,𝓛,𝓡] >= 0, container=DenseArray) 
    else
        TotalActivityInReserveMargin = nothing
        DemandNeedingReserveMargin = nothing
    end

    

    ######## RE Gen Target #############

    TotalREProductionAnnual = @variable(model, TotalREProductionAnnual[𝓨,𝓡,𝓕], container=DenseArray) 
    RETotalDemandOfTargetFuelAnnual = @variable(model, RETotalDemandOfTargetFuelAnnual[𝓨,𝓡,𝓕], container=DenseArray) 
    TotalTechnologyModelPeriodActivity = @variable(model, TotalTechnologyModelPeriodActivity[𝓣,𝓡], container=DenseArray) 
    RETargetMin = @variable(model, RETargetMin[𝓨,𝓡] >= 0, container=DenseArray) 

    

    ######## Emissions #############

    AnnualTechnologyEmissionByMode = def_daa(𝓨,𝓣,𝓔,𝓜,𝓡)
    for y ∈ 𝓨 for r ∈ 𝓡 for t ∈ 𝓣 for e ∈ 𝓔 
        for m ∈ Maps.Tech_MO[t]
            AnnualTechnologyEmissionByMode[y,t,e,m,r] = @variable(model, lower_bound = 0, base_name= "AnnualTechnologyEmissionByMode[$y,$t,$e,$m,$r]")
        end
    end end end end 
    model[:AnnualTechnologyEmissionByMode] = AnnualTechnologyEmissionByMode

    AnnualTechnologyEmission = @variable(model, AnnualTechnologyEmission[𝓨,𝓣,𝓔,𝓡], container=DenseArray) 
    AnnualTechnologyEmissionPenaltyByEmission = @variable(model, AnnualTechnologyEmissionPenaltyByEmission[𝓨,𝓣,𝓔,𝓡], container=DenseArray) 
    AnnualTechnologyEmissionsPenalty = @variable(model, AnnualTechnologyEmissionsPenalty[𝓨,𝓣,𝓡], container=DenseArray) 
    DiscountedTechnologyEmissionsPenalty = @variable(model, DiscountedTechnologyEmissionsPenalty[𝓨,𝓣,𝓡], container=DenseArray) 
    AnnualEmissions = @variable(model, AnnualEmissions[𝓨,𝓔,𝓡], container=DenseArray) 
    ModelPeriodEmissions = @variable(model, ModelPeriodEmissions[𝓔,𝓡], container=DenseArray) 
    WeightedAnnualEmissions = @variable(model, WeightedAnnualEmissions[𝓨,𝓔,𝓡], container=DenseArray)

    
    ######### SectoralEmissions #############

    AnnualSectoralEmissions = @variable(model, AnnualSectoralEmissions[𝓨,𝓔,𝓢𝓮,𝓡], container=DenseArray) 

    

    ######### Trade #############
    Import = def_daa(𝓨,𝓛,𝓕,𝓡,𝓡)
    Export = def_daa(𝓨,𝓛,𝓕,𝓡,𝓡)
    NewTradeCapacity = def_daa(𝓨,𝓕,𝓡,𝓡)
    TotalTradeCapacity = def_daa(𝓨,𝓕,𝓡,𝓡)
    NewTradeCapacityCosts = def_daa(𝓨,𝓕,𝓡,𝓡)
    DiscountedNewTradeCapacityCosts = def_daa(𝓨,𝓕,𝓡,𝓡)
    for y ∈ 𝓨 for f ∈ 𝓕 for r1 ∈ 𝓡 for r2 ∈ 𝓡
        if Params.TradeRoute[r1,r2,f,y] != 0
            for l ∈ 𝓛
                Import[y,l,f,r1,r2] = @variable(model, lower_bound= 0, base_name="Import[$y,$l,$f,$r1,$r2]") 
                Export[y,l,f,r1,r2] = @variable(model, lower_bound= 0, base_name="Export[$y,$l,$f,$r1,$r2]") 
            end
            NewTradeCapacity[y,f,r1,r2] = @variable(model, lower_bound= 0, base_name="NewTradeCapacity[$y,$f,$r1,$r2]") 
            TotalTradeCapacity[y,f,r1,r2] = @variable(model, lower_bound= 0, base_name="TotalTradeCapacity[$y,$f,$r1,$r2]") 
            NewTradeCapacityCosts[y,f,r1,r2] = @variable(model, lower_bound= 0, base_name="NewTradeCapacityCosts[$y,$f,$r1,$r2]") 
            DiscountedNewTradeCapacityCosts[y,f,r1,r2] = @variable(model, lower_bound= 0, base_name="DiscountedNewTradeCapacityCosts[$y,$f,$r1,$r2]") 
        end
    end end end end
    model[:Import] = Import
    model[:Export] = Export
    model[:NewTradeCapacity] = NewTradeCapacity
    model[:TotalTradeCapacity] = TotalTradeCapacity
    model[:NewTradeCapacityCosts] = NewTradeCapacityCosts
    model[:DiscountedNewTradeCapacityCosts] = DiscountedNewTradeCapacityCosts

    NetTrade = @variable(model, NetTrade[𝓨,𝓛,𝓕,𝓡], container=DenseArray) 
    NetTradeAnnual = @variable(model, NetTradeAnnual[𝓨,𝓕,𝓡], container=DenseArray) 
    TotalTradeCosts = @variable(model, TotalTradeCosts[𝓨,𝓛,𝓡], container=DenseArray) 
    AnnualTotalTradeCosts = @variable(model, AnnualTotalTradeCosts[𝓨,𝓡], container=DenseArray) 
    DiscountedAnnualTotalTradeCosts = @variable(model, DiscountedAnnualTotalTradeCosts[𝓨,𝓡], container=DenseArray) 

    ######### Peaking #############
    if Switch.switch_peaking_capacity == 1
        PeakingDemand = @variable(model, PeakingDemand[𝓨,𝓡], container=DenseArray)
        PeakingCapacity = @variable(model, PeakingCapacity[𝓨,𝓡], container=DenseArray)
    else
        PeakingDemand=nothing
        PeakingCapacity=nothing
    end

    ######### Transportation #############


    #TrajectoryLowerLimit(𝓨) 
    #TrajectoryUpperLimit(𝓨) 

    DemandSplitByModalType = @variable(model, DemandSplitByModalType[𝓜𝓽,𝓛,𝓡,Params.Tags.TagFuelToSubsets["TransportFuels"],𝓨], container=DenseArray) 
    ProductionSplitByModalType = @variable(model, ProductionSplitByModalType[𝓜𝓽,𝓛,𝓡,Params.Tags.TagFuelToSubsets["TransportFuels"],𝓨], container=DenseArray) 

    if Switch.switch_ramping == 1

        ######## Ramping #############    
        ProductionUpChangeInTimeslice = def_daa(𝓨,𝓛,𝓕,𝓣,𝓡)
        ProductionDownChangeInTimeslice = def_daa(𝓨,𝓛,𝓕,𝓣,𝓡)
        for y ∈ 𝓨 for r ∈ 𝓡 for f ∈ 𝓕 for l ∈ 𝓛
            for t ∈ Maps.Fuel_Tech[f]
                ProductionUpChangeInTimeslice[y,l,f,t,r] = @variable(model, lower_bound = 0, base_name= "ProductionUpChangeInTimeslice[$y,$l,$f,$t,$r]")
                ProductionDownChangeInTimeslice[y,l,f,t,r] = @variable(model, lower_bound = 0, base_name= "ProductionDownChangeInTimeslice[$y,$l,$f,$t,$r]")
            end
        end end end end 
        model[:ProductionUpChangeInTimeslice] = ProductionUpChangeInTimeslice
        model[:ProductionDownChangeInTimeslice] = ProductionDownChangeInTimeslice
        @variable(model, AnnualProductionChangeCost[𝓨,𝓣,𝓡] >= 0, container=DenseArray) 
        @variable(model, DiscountedAnnualProductionChangeCost[𝓨,𝓣,𝓡] >= 0, container=DenseArray) 
    else
        ProductionUpChangeInTimeslice=nothing
        ProductionDownChangeInTimeslice=nothing
        AnnualProductionChangeCost=nothing
        DiscountedAnnualProductionChangeCost=nothing
    end

    if Switch.switch_intertemporal == 1
        RateOfTotalActivity = @variable(model, RateOfTotalActivity[𝓨,𝓛,𝓣,𝓡], container=DenseArray)
    else
        RateOfTotalActivity=nothing
    end

    BaseYearSlack= @variable(model, BaseYearSlack[𝓕], container=DenseArray) 
    BaseYearBounds_TooLow = def_daa(𝓡,𝓣,𝓕,𝓨)
    BaseYearBounds_TooHigh = def_daa(𝓡,𝓣,𝓕,𝓨)
    for y ∈ 𝓨 for r ∈ 𝓡 for t ∈ 𝓣
        for f ∈ Maps.Tech_Fuel[t]
            BaseYearBounds_TooLow[r,t,f,y] = @variable(model, lower_bound = 0, base_name= "BaseYearBounds_TooLow[$r,$t,$f,$y]")
            BaseYearBounds_TooHigh[r,t,f,y] = @variable(model, lower_bound = 0, base_name= "BaseYearBounds_TooHigh[$r,$t,$f,$y]")
            if Switch.switch_base_year_bounds_debugging == 0
                JuMP.fix(BaseYearBounds_TooLow[r,t,f,y], 0;force=true)
                JuMP.fix(BaseYearBounds_TooHigh[r,t,f,y], 0;force=true)
            end
        end
    end end end
    model[:BaseYearBounds_TooLow] = BaseYearBounds_TooLow
    model[:BaseYearBounds_TooHigh] = BaseYearBounds_TooHigh
    DiscountedSalvageValueTransmission= @variable(model, DiscountedSalvageValueTransmission[𝓨,𝓡] >= 0, container=DenseArray) 
    
    Vars = GENeSYS_MOD.Variables(NewCapacity,AccumulatedNewCapacity,TotalCapacityAnnual,
    RateOfActivity,TotalAnnualTechnologyActivityByMode,ProductionByTechnologyAnnual,
    UseByTechnologyAnnual,TotalTechnologyAnnualActivity,TotalActivityPerYear,CurtailedEnergyAnnual,
    CurtailedCapacity,CurtailedEnergy,DispatchDummy,CapitalInvestment,DiscountedCapitalInvestment,
    SalvageValue,DiscountedSalvageValue,OperatingCost,DiscountedOperatingCost,AnnualVariableOperatingCost,
    AnnualFixedOperatingCost,VariableOperatingCost,TotalDiscountedCost,TotalDiscountedCostByTechnology,
    ModelPeriodCostByRegion,AnnualCurtailmentCost,DiscountedAnnualCurtailmentCost,
    StorageLevelYearStart,StorageLevelYearFinish,StorageLevelTSStart,AccumulatedNewStorageCapacity,NewStorageCapacity,
    CapitalInvestmentStorage,DiscountedCapitalInvestmentStorage,SalvageValueStorage,
    DiscountedSalvageValueStorage,TotalDiscountedStorageCost,TotalActivityInReserveMargin,
    DemandNeedingReserveMargin,TotalREProductionAnnual,RETotalDemandOfTargetFuelAnnual,
    TotalTechnologyModelPeriodActivity,RETargetMin,AnnualTechnologyEmissionByMode,
    AnnualTechnologyEmission,AnnualTechnologyEmissionPenaltyByEmission,AnnualTechnologyEmissionsPenalty,
    DiscountedTechnologyEmissionsPenalty,AnnualEmissions,ModelPeriodEmissions,WeightedAnnualEmissions,
    AnnualSectoralEmissions,Import,Export,NewTradeCapacity,TotalTradeCapacity,NewTradeCapacityCosts,
    DiscountedNewTradeCapacityCosts,NetTrade,NetTradeAnnual,TotalTradeCosts,AnnualTotalTradeCosts,
    DiscountedAnnualTotalTradeCosts,DemandSplitByModalType,ProductionSplitByModalType,
    ProductionUpChangeInTimeslice,ProductionDownChangeInTimeslice,
    RateOfTotalActivity,BaseYearSlack,BaseYearBounds_TooLow,BaseYearBounds_TooHigh, DiscountedSalvageValueTransmission,PeakingDemand,PeakingCapacity,
    AnnualProductionChangeCost,DiscountedAnnualProductionChangeCost)
    return Vars
end

