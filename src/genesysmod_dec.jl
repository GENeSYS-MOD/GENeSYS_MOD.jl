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
Internal function used in the run process to define the model variables.
"""
function genesysmod_dec(model,Sets, Subsets, Params,Switch)

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

    ############### Capacity Variables ############*
    @variable(model, NewCapacity[𝓨,𝓣,𝓡] >= 0)
    @variable(model, AccumulatedNewCapacity[𝓨,𝓣,𝓡] >= 0)
    @variable(model, TotalCapacityAnnual[𝓨,𝓣,𝓡] >= 0)

    ############### Activity Variables #############

    @variable(model, RateOfActivity[𝓨,𝓛,𝓣,𝓜,𝓡] >= 0)
    @variable(model, TotalTechnologyAnnualActivity[𝓨,𝓣,𝓡] >= 0)
    
    @variable(model, TotalAnnualTechnologyActivityByMode[𝓨,𝓣,𝓜,𝓡] >= 0)
    
    @variable(model, ProductionByTechnologyAnnual[𝓨,𝓣,𝓕,𝓡] >= 0)
    
    @variable(model, UseByTechnologyAnnual[𝓨,𝓣,𝓕,𝓡] >= 0)
    
    @variable(model, TotalActivityPerYear[𝓡,𝓛,𝓣,𝓨] >= 0)
    @variable(model, CurtailedEnergyAnnual[𝓨,𝓕,𝓡] >= 0)
    @variable(model, CurtailedCapacity[𝓡,𝓛,𝓣,𝓨] >= 0)
    @variable(model, DispatchDummy[𝓡,𝓛,𝓣,𝓨] >= 0)

    
    ############### Costing Variables #############

    @variable(model, CapitalInvestment[𝓨,𝓣,𝓡] >= 0)
    @variable(model, DiscountedCapitalInvestment[𝓨,𝓣,𝓡] >= 0)
    @variable(model, SalvageValue[𝓨,𝓣,𝓡] >= 0)
    @variable(model, DiscountedSalvageValue[𝓨,𝓣,𝓡] >= 0)
    @variable(model, OperatingCost[𝓨,𝓣,𝓡] >= 0)
    @variable(model, DiscountedOperatingCost[𝓨,𝓣,𝓡] >= 0)
    @variable(model, AnnualVariableOperatingCost[𝓨,𝓣,𝓡] >= 0)
    @variable(model, AnnualFixedOperatingCost[𝓨,𝓣,𝓡] >= 0)
    @variable(model, VariableOperatingCost[𝓨,𝓛,𝓣,𝓡] >= 0)
    @variable(model, TotalDiscountedCost[𝓨,𝓡] >= 0)
    @variable(model, TotalDiscountedCostByTechnology[𝓨,𝓣,𝓡] >= 0)
    @variable(model, ModelPeriodCostByRegion[𝓡] >= 0)

    @variable(model, AnnualCurtailmentCost[𝓨,𝓕,𝓡] >= 0)
    @variable(model, DiscountedAnnualCurtailmentCost[𝓨,𝓕,𝓡] >= 0)

    

    ############### Storage Variables #############

    @variable(model, StorageLevelYearStart[𝓢,𝓨,𝓡] >= 0)
    @variable(model, StorageLevelTSStart[𝓢,𝓨,𝓛,𝓡] >= 0)

    @variable(model, AccumulatedNewStorageCapacity[𝓢,𝓨,𝓡] >= 0) 
    @variable(model, NewStorageCapacity[𝓢,𝓨,𝓡] >= 0) 
    @variable(model, CapitalInvestmentStorage[𝓢,𝓨,𝓡] >= 0) 
    @variable(model, DiscountedCapitalInvestmentStorage[𝓢,𝓨,𝓡] >= 0) 
    @variable(model, SalvageValueStorage[𝓢,𝓨,𝓡] >= 0) 
    @variable(model, DiscountedSalvageValueStorage[𝓢,𝓨,𝓡] >= 0) 
    @variable(model, TotalDiscountedStorageCost[𝓢,𝓨,𝓡] >= 0) 

    

    ######## Reserve Margin #############

    if Switch.switch_dispatch == 0
        @variable(model, TotalActivityInReserveMargin[𝓡,𝓨,𝓛] >= 0)
        @variable(model, DemandNeedingReserveMargin[𝓨,𝓛,𝓡] >= 0) 
    end

    

    ######## RE Gen Target #############

    @variable(model, TotalREProductionAnnual[𝓨,𝓡,𝓕]) 
    @variable(model, RETotalDemandOfTargetFuelAnnual[𝓨,𝓡,𝓕]) 
    @variable(model, TotalTechnologyModelPeriodActivity[𝓣,𝓡]) 
    @variable(model, RETargetMin[𝓨,𝓡] >= 0) 

    

    ######## Emissions #############

    @variable(model, AnnualTechnologyEmissionByMode[𝓨,𝓣,𝓔,𝓜,𝓡]) 
    @variable(model, AnnualTechnologyEmission[𝓨,𝓣,𝓔,𝓡]) 
    @variable(model, AnnualTechnologyEmissionPenaltyByEmission[𝓨,𝓣,𝓔,𝓡]) 
    @variable(model, AnnualTechnologyEmissionsPenalty[𝓨,𝓣,𝓡]) 
    @variable(model, DiscountedTechnologyEmissionsPenalty[𝓨,𝓣,𝓡]) 
    @variable(model, AnnualEmissions[𝓨,𝓔,𝓡]) 
    @variable(model, ModelPeriodEmissions[𝓔,𝓡]) 
    @variable(model, WeightedAnnualEmissions[𝓨,𝓔,𝓡])

    


    ######### SectoralEmissions #############

    @variable(model, AnnualSectoralEmissions[𝓨,𝓔,𝓢𝓮,𝓡]) 

    

    ######### Trade #############

    @variable(model, Import[𝓨,𝓛,𝓕,𝓡,𝓡] >= 0) 
    @variable(model, Export[𝓨,𝓛,𝓕,𝓡,𝓡] >= 0) 

    @variable(model, NewTradeCapacity[𝓨, 𝓕, 𝓡, 𝓡] >= 0) 
    @variable(model, TotalTradeCapacity[𝓨, 𝓕, 𝓡, 𝓡] >= 0) 
    @variable(model, NewTradeCapacityCosts[𝓨, 𝓕, 𝓡, 𝓡] >= 0) 
    @variable(model, DiscountedNewTradeCapacityCosts[𝓨, 𝓕, 𝓡, 𝓡] >= 0) 

    @variable(model, NetTrade[𝓨,𝓛,𝓕,𝓡]) 
    @variable(model, NetTradeAnnual[𝓨,𝓕,𝓡]) 
    @variable(model, TotalTradeCosts[𝓨,𝓛,𝓡]) 
    @variable(model, AnnualTotalTradeCosts[𝓨,𝓡]) 
    @variable(model, DiscountedAnnualTotalTradeCosts[𝓨,𝓡]) 

    

    ######### Transportation #############


    #TrajectoryLowerLimit(𝓨) 
    #TrajectoryUpperLimit(𝓨) 

    @variable(model, DemandSplitByModalType[𝓜𝓽,𝓛,𝓡,Subsets.TransportFuels,𝓨]) 
    @variable(model, ProductionSplitByModalType[𝓜𝓽,𝓛,𝓡,Subsets.TransportFuels,𝓨]) 

    if Switch.switch_ramping == 1

        ######## Ramping #############      
        @variable(model, ProductionUpChangeInTimeslice[𝓨,𝓛,𝓕,𝓣,𝓡] >= 0) 
        @variable(model, ProductionDownChangeInTimeslice[𝓨,𝓛,𝓕,𝓣,𝓡] >= 0)     
        @variable(model, AnnualProductionChangeCost[𝓨,𝓣,𝓡] >= 0) 
        @variable(model, DiscountedAnnualProductionChangeCost[𝓨,𝓣,𝓡] >= 0) 
    end

    if Switch.switch_intertemporal == 1
        @variable(model, RateOfTotalActivity[𝓨,𝓛,𝓣,𝓡])
    end

    @variable(model, BaseYearSlack[𝓕]) 
    @variable(model, BaseYearOvershoot[𝓡,𝓣,𝓕,𝓨] >= 0)
    @variable(model, DiscountedSalvageValueTransmission[𝓨,𝓡] >= 0) 
    
end

