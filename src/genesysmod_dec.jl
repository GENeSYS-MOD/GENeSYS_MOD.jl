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

function genesysmod_dec(model,Sets, Subsets, Params,Switch)


    #####################
    # Model Variables #
    #####################

    ############### Capacity Variables ############
    @variable(model, NewCapacity[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, AccumulatedNewCapacity[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, TotalCapacityAnnual[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)

    ############### Activity Variables #############

    @variable(model, RateOfActivity[Sets.Year,Sets.Timeslice,Sets.Technology,Sets.Mode_of_operation,Sets.Region_full] >= 0)
    @variable(model, TotalTechnologyAnnualActivity[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    
    @variable(model, TotalAnnualTechnologyActivityByMode[Sets.Year,Sets.Technology,Sets.Mode_of_operation,Sets.Region_full] >= 0)
    
    @variable(model, ProductionByTechnologyAnnual[Sets.Year,Sets.Technology,Sets.Fuel,Sets.Region_full] >= 0)
    
    @variable(model, UseByTechnologyAnnual[Sets.Year,Sets.Technology,Sets.Fuel,Sets.Region_full] >= 0)
    
    @variable(model, TotalActivityPerYear[Sets.Region_full,Sets.Timeslice,Sets.Technology,Sets.Year] >= 0)
    @variable(model, Curtailment[Sets.Year,Sets.Timeslice,Sets.Fuel,Sets.Region_full] >= 0)
    @variable(model, CurtailmentAnnual[Sets.Year,Sets.Fuel,Sets.Region_full] >= 0)
    @variable(model, DispatchDummy[Sets.Region_full,Sets.Timeslice,Sets.Technology,Sets.Year] >= 0)

    
    ############### Costing Variables #############

    @variable(model, CapitalInvestment[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, DiscountedCapitalInvestment[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, SalvageValue[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, DiscountedSalvageValue[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, OperatingCost[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, DiscountedOperatingCost[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, AnnualVariableOperatingCost[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, AnnualFixedOperatingCost[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, VariableOperatingCost[Sets.Year,Sets.Timeslice,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, TotalDiscountedCost[Sets.Year,Sets.Region_full] >= 0)
    @variable(model, TotalDiscountedCostByTechnology[Sets.Year,Sets.Technology,Sets.Region_full] >= 0)
    @variable(model, ModelPeriodCostByRegion[Sets.Region_full] >= 0)

    @variable(model, AnnualCurtailmentCost[Sets.Year,Sets.Fuel,Sets.Region_full] >= 0)
    @variable(model, DiscountedAnnualCurtailmentCost[Sets.Year,Sets.Fuel,Sets.Region_full] >= 0)

    

    ############### Storage Variables #############

    if Switch.switch_short_term_storage == 0
        @variable(model,RateOfStorageCharge[Sets.Storage,Sets.Year,Sets.Season,Sets.Daytype,Sets.DailyTimeBracket,Sets.Region_full])
        @variable(model,RateOfStorageDischarge[Sets.Storage,Sets.Year,Sets.Season,Sets.Daytype,Sets.DailyTimeBracket,Sets.Region_full])
        @variable(model,NetChargeWithinYear[Sets.Storage,Sets.Year,Sets.Season,Sets.Daytype,Sets.DailyTimeBracket,Sets.Region_full])
        @variable(model,NetChargeWithinDay[Sets.Storage,Sets.Year,Sets.Season,Sets.Daytype,Sets.DailyTimeBracket,Sets.Region_full])
        @variable(model, StorageLevelYearFinish[Sets.Storage,Sets.Year,Sets.Region_full] >= 0)
        @variable(model, StorageLevelSeasonStart[Sets.Storage,Sets.Year,Sets.Season,Sets.Region_full] >= 0)
        @variable(model, StorageLevelDayTypeStart[Sets.Storage,Sets.Year,Sets.Season,Sets.Daytype,Sets.Region_full] >= 0)
        @variable(model, StorageLevelDayTypeFinish[Sets.Storage,Sets.Year,Sets.Season,Sets.Daytype,Sets.Region_full] >= 0)
        @variable(model, StorageLowerLimit[Sets.Storage,Sets.Year,Sets.Region_full] >= 0)
        @variable(model, StorageUpperLimit[Sets.Storage,Sets.Year,Sets.Region_full] >= 0)
    else
        @variable(model, StorageLevelYearStart[Sets.Storage,Sets.Year,Sets.Region_full] >= 0)
        @variable(model, StorageLevelTSStart[Sets.Storage,Sets.Year,Sets.Timeslice,Sets.Region_full] >= 0)
    end

    @variable(model, AccumulatedNewStorageCapacity[Sets.Storage,Sets.Year,Sets.Region_full] >= 0) 
    @variable(model, NewStorageCapacity[Sets.Storage,Sets.Year,Sets.Region_full] >= 0) 
    @variable(model, CapitalInvestmentStorage[Sets.Storage,Sets.Year,Sets.Region_full] >= 0) 
    @variable(model, DiscountedCapitalInvestmentStorage[Sets.Storage,Sets.Year,Sets.Region_full] >= 0) 
    @variable(model, SalvageValueStorage[Sets.Storage,Sets.Year,Sets.Region_full] >= 0) 
    @variable(model, DiscountedSalvageValueStorage[Sets.Storage,Sets.Year,Sets.Region_full] >= 0) 
    @variable(model, TotalDiscountedStorageCost[Sets.Storage,Sets.Year,Sets.Region_full] >= 0) 

    

    ######## Reserve Margin #############

    if Switch.switch_dispatch == 0
        @variable(model, TotalActivityInReserveMargin[Sets.Region_full,Sets.Year,Sets.Timeslice] >= 0)
        @variable(model, DemandNeedingReserveMargin[Sets.Year,Sets.Timeslice,Sets.Region_full] >= 0) 
    end

    

    ######## RE Gen Target #############

    @variable(model, TotalREProductionAnnual[Sets.Year,Sets.Region_full,Sets.Fuel]) 
    @variable(model, RETotalDemandOfTargetFuelAnnual[Sets.Year,Sets.Region_full,Sets.Fuel]) 
    @variable(model, TotalTechnologyModelPeriodActivity[Sets.Technology,Sets.Region_full]) 
    @variable(model, RETargetMin[Sets.Year,Sets.Region_full] >= 0) 

    

    ######## Emissions #############

    @variable(model, AnnualTechnologyEmissionByMode[Sets.Year,Sets.Technology,Sets.Emission,Sets.Mode_of_operation,Sets.Region_full]) 
    @variable(model, AnnualTechnologyEmission[Sets.Year,Sets.Technology,Sets.Emission,Sets.Region_full]) 
    @variable(model, AnnualTechnologyEmissionPenaltyByEmission[Sets.Year,Sets.Technology,Sets.Emission,Sets.Region_full]) 
    @variable(model, AnnualTechnologyEmissionsPenalty[Sets.Year,Sets.Technology,Sets.Region_full]) 
    @variable(model, DiscountedTechnologyEmissionsPenalty[Sets.Year,Sets.Technology,Sets.Region_full]) 
    @variable(model, AnnualEmissions[Sets.Year,Sets.Emission,Sets.Region_full]) 
    @variable(model, ModelPeriodEmissions[Sets.Emission,Sets.Region_full]) 
    @variable(model, WeightedAnnualEmissions[Sets.Year_full,Sets.Emission,Sets.Region_full])

    


    ######### SectoralEmissions #############

    @variable(model, AnnualSectoralEmissions[Sets.Year,Sets.Emission,Sets.Sector,Sets.Region_full]) 

    

    ######### Trade #############

    @variable(model, Import[Sets.Year,Sets.Timeslice,Sets.Fuel,Sets.Region_full,Sets.Region_full] >= 0) 
    @variable(model, Export[Sets.Year,Sets.Timeslice,Sets.Fuel,Sets.Region_full,Sets.Region_full] >= 0) 

    @variable(model, NewTradeCapacity[Sets.Year, Sets.Fuel, Sets.Region_full, Sets.Region_full] >= 0) 
    @variable(model, TotalTradeCapacity[Sets.Year, Sets.Fuel, Sets.Region_full, Sets.Region_full] >= 0) 
    @variable(model, NewTradeCapacityCosts[Sets.Year, Sets.Fuel, Sets.Region_full, Sets.Region_full] >= 0) 
    @variable(model, DiscountedNewTradeCapacityCosts[Sets.Year, Sets.Fuel, Sets.Region_full, Sets.Region_full] >= 0) 

    @variable(model, NetTrade[Sets.Year,Sets.Timeslice,Sets.Fuel,Sets.Region_full]) 
    @variable(model, NetTradeAnnual[Sets.Year,Sets.Fuel,Sets.Region_full]) 
    @variable(model, TotalTradeCosts[Sets.Year,Sets.Timeslice,Sets.Region_full]) 
    @variable(model, AnnualTotalTradeCosts[Sets.Year,Sets.Region_full]) 
    @variable(model, DiscountedAnnualTotalTradeCosts[Sets.Year,Sets.Region_full]) 

    

    ######### Transportation #############


    #TrajectoryLowerLimit(Sets.Year) 
    #TrajectoryUpperLimit(Sets.Year) 

    @variable(model, DemandSplitByModalType[Sets.ModalType,Sets.Timeslice,Sets.Region_full,Subsets.TransportFuels,Sets.Year]) 
    @variable(model, ProductionSplitByModalType[Sets.ModalType,Sets.Timeslice,Sets.Region_full,Subsets.TransportFuels,Sets.Year]) 

    if Switch.switch_ramping == 1

    ######## Ramping #############  
        RampingUpFactor(Sets.Region_full,Sets.Technology,Sets.Year) 
        RampingDownFactor(Sets.Region_full,Sets.Technology,Sets.Year)   
        ProductionChangeCost(Sets.Region_full,Sets.Technology,Sets.Year)    
        MinActiveProductionPerTimeslice(Sets.Year,Sets.Timeslice,Sets.Fuel,Sets.Technology,Sets.Region_full)    
        @variable(model, ProductionUpChangeInTimeslice[Sets.Year,Sets.Timeslice,Sets.Fuel,Sets.Technology,Sets.Region_full] >= 0) 
        @variable(model, ProductionDownChangeInTimeslice[Sets.Year,Sets.Timeslice,Sets.Fuel,Sets.Technology,Sets.Region_full] >= 0)     
        @variable(model, AnnualProductionChangeCost[Sets.Year,Sets.Technology,Sets.Region_full] >= 0) 
        @variable(model, DiscountedAnnualProductionChangeCost[Sets.Year,Sets.Technology,Sets.Region_full] >= 0) 
    end

    if Switch.switch_intertemporal == 1
        @variable(model, RateOfTotalActivity[Sets.Year,Sets.Timeslice,Sets.Technology,Sets.Region_full])
    end

    @variable(model, BaseYearSlack[Sets.Fuel]) 
    @variable(model, BaseYearOvershoot[Sets.Region_full,Sets.Technology,Sets.Fuel,Sets.Year] >= 0) 
    
end

