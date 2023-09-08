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
InputClass - Abstract type for the inputs
"""
abstract type InputClass end

"""
All the parameters read for a model run

# Fields
- **`StartYear ::Int64`**
- **`YearSplit ::JuMP.Containers.DenseAxisArray`**
- **`SpecifiedAnnualDemand ::JuMP.Containers.DenseAxisArray`**
- **`SpecifiedDemandProfile ::JuMP.Containers.DenseAxisArray`**
- **`RateOfDemand ::JuMP.Containers.DenseAxisArray`**
- **`Demand ::JuMP.Containers.DenseAxisArray`**
- **`CapacityToActivityUnit ::JuMP.Containers.DenseAxisArray`**
- **`CapacityFactor ::JuMP.Containers.DenseAxisArray`**
- **`AvailabilityFactor ::JuMP.Containers.DenseAxisArray`**
- **`OperationalLife ::JuMP.Containers.DenseAxisArray`**
- **`ResidualCapacity ::JuMP.Containers.DenseAxisArray`**
- **`InputActivityRatio ::JuMP.Containers.DenseAxisArray`**
- **`OutputActivityRatio ::JuMP.Containers.DenseAxisArray`**
- **`CapacityOfOneTechnologyUnit ::JuMP.Containers.DenseAxisArray`**
- **`TagDispatchableTechnology ::JuMP.Containers.DenseAxisArray`**
- **`BaseYearProduction ::JuMP.Containers.DenseAxisArray`**
- **`RegionalBaseYearProduction ::JuMP.Containers.DenseAxisArray`**
- **`RegionalCCSLimit ::JuMP.Containers.DenseAxisArray`**
- **`CapitalCost ::JuMP.Containers.DenseAxisArray`**
- **`VariableCost ::JuMP.Containers.DenseAxisArray`**
- **`FixedCost ::JuMP.Containers.DenseAxisArray`**
- **`StorageLevelStart ::JuMP.Containers.DenseAxisArray`**
- **`StorageMaxChargeRate ::JuMP.Containers.DenseAxisArray`**
- **`StorageMaxDischargeRate ::JuMP.Containers.DenseAxisArray`**
- **`MinStorageCharge ::JuMP.Containers.DenseAxisArray`**
- **`OperationalLifeStorage ::JuMP.Containers.DenseAxisArray`**
- **`CapitalCostStorage ::JuMP.Containers.DenseAxisArray`**
- **`ResidualStorageCapacity ::JuMP.Containers.DenseAxisArray`**
- **`TechnologyToStorage ::JuMP.Containers.DenseAxisArray`**
- **`TechnologyFromStorage ::JuMP.Containers.DenseAxisArray`**
- **`StorageMaxCapacity ::JuMP.Containers.DenseAxisArray`**
- **`TotalAnnualMaxCapacity ::JuMP.Containers.DenseAxisArray`**
- **`TotalAnnualMinCapacity ::JuMP.Containers.DenseAxisArray`**
- **`TagTechnologyToSector ::JuMP.Containers.DenseAxisArray`**
- **`AnnualSectoralEmissionLimit ::JuMP.Containers.DenseAxisArray`**
- **`TotalAnnualMaxCapacityInvestment ::JuMP.Containers.DenseAxisArray`**
- **`TotalAnnualMinCapacityInvestment ::JuMP.Containers.DenseAxisArray`**
- **`TotalTechnologyAnnualActivityUpperLimit ::JuMP.Containers.DenseAxisArray`**
- **`TotalTechnologyAnnualActivityLowerLimit ::JuMP.Containers.DenseAxisArray`**
- **`TotalTechnologyModelPeriodActivityUpperLimit ::JuMP.Containers.DenseAxisArray`**
- **`TotalTechnologyModelPeriodActivityLowerLimit ::JuMP.Containers.DenseAxisArray`**
- **`ReserveMarginTagTechnology ::JuMP.Containers.DenseAxisArray`**
- **`ReserveMarginTagFuel ::JuMP.Containers.DenseAxisArray`**
- **`ReserveMargin ::JuMP.Containers.DenseAxisArray`**
- **`RETagTechnology ::JuMP.Containers.DenseAxisArray`**
- **`RETagFuel ::JuMP.Containers.DenseAxisArray`**
- **`REMinProductionTarget ::JuMP.Containers.DenseAxisArray`**
- **`EmissionActivityRatio ::JuMP.Containers.DenseAxisArray`**
- **`EmissionContentPerFuel ::JuMP.Containers.DenseAxisArray`**
- **`EmissionsPenalty ::JuMP.Containers.DenseAxisArray`**
- **`EmissionsPenaltyTagTechnology ::JuMP.Containers.DenseAxisArray`**
- **`AnnualExogenousEmission ::JuMP.Containers.DenseAxisArray`**
- **`AnnualEmissionLimit ::JuMP.Containers.DenseAxisArray`**
- **`RegionalAnnualEmissionLimit ::JuMP.Containers.DenseAxisArray`**
- **`ModelPeriodExogenousEmission ::JuMP.Containers.DenseAxisArray`**
- **`ModelPeriodEmissionLimit ::JuMP.Containers.DenseAxisArray`**
- **`RegionalModelPeriodEmissionLimit ::JuMP.Containers.DenseAxisArray`**
- **`CurtailmentCostFactor ::JuMP.Containers.DenseAxisArray`**
- **`Readin_TradeRoute2015 ::JuMP.Containers.DenseAxisArray`**
- **`Readin_PowerTradeCapacity ::JuMP.Containers.DenseAxisArray`**
- **`TradeRoute ::JuMP.Containers.DenseAxisArray`**
- **`TradeCosts ::JuMP.Containers.DenseAxisArray`**
- **`TradeLossFactor ::JuMP.Containers.DenseAxisArray`**
- **`TradeRouteInstalledCapacity ::JuMP.Containers.DenseAxisArray`**
- **`TradeLossBetweenRegions ::JuMP.Containers.DenseAxisArray`**
- **`AdditionalTradeCapacity ::JuMP.Containers.DenseAxisArray`**
- **`TradeCapacity ::JuMP.Containers.DenseAxisArray`**
- **`TradeCapacityGrowthCosts ::JuMP.Containers.DenseAxisArray`**
- **`GrowthRateTradeCapacity ::JuMP.Containers.DenseAxisArray`**
- **`SelfSufficiency ::JuMP.Containers.DenseAxisArray`**
- **`Conversionls ::JuMP.Containers.DenseAxisArray`**
- **`Conversionld ::JuMP.Containers.DenseAxisArray`**
- **`Conversionlh ::JuMP.Containers.DenseAxisArray`**
- **`DaySplit ::JuMP.Containers.DenseAxisArray`**
- **`RampingUpFactor ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`RampingDownFactor ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`ProductionChangeCost ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`MinActiveProductionPerTimeslice ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`ModalSplitByFuelAndModalType ::JuMP.Containers.DenseAxisArray`**
- **`TagTechnologyToModalType ::JuMP.Containers.DenseAxisArray`**
- **`EFactorConstruction ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`EFactorOM ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`EFactorManufacturing ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`EFactorFuelSupply ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`EFactorCoalJobs ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`CoalSupply ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`CoalDigging ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`RegionalAdjustmentFactor ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`LocalManufacturingFactor ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`DeclineRate ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`x_peakingDemand ::Union{Nothing,JuMP.Containers.DenseAxisArray}`**
- **`TagDemandFuelToSector ::JuMP.Containers.DenseAxisArray`**
- **`TagElectricTechnology ::JuMP.Containers.DenseAxisArray`**
"""

struct Parameters <: InputClass
    StartYear ::Int64
    YearSplit ::JuMP.Containers.DenseAxisArray{<:Real}

    SpecifiedAnnualDemand ::JuMP.Containers.DenseAxisArray{<:Real}
    SpecifiedDemandProfile ::JuMP.Containers.DenseAxisArray{<:Real}
    RateOfDemand ::JuMP.Containers.DenseAxisArray{<:Real}
    Demand ::JuMP.Containers.DenseAxisArray{<:Real}

    CapacityToActivityUnit ::JuMP.Containers.DenseAxisArray{<:Real}
    CapacityFactor ::JuMP.Containers.DenseAxisArray{<:Real}
    AvailabilityFactor ::JuMP.Containers.DenseAxisArray{<:Real}
    OperationalLife ::JuMP.Containers.DenseAxisArray{<:Real}
    ResidualCapacity ::JuMP.Containers.DenseAxisArray{<:Real}
    InputActivityRatio ::JuMP.Containers.DenseAxisArray{<:Real}
    OutputActivityRatio ::JuMP.Containers.DenseAxisArray{<:Real}
    CapacityOfOneTechnologyUnit ::JuMP.Containers.DenseAxisArray{<:Real}
    TagDispatchableTechnology ::JuMP.Containers.DenseAxisArray{<:Int}
    BaseYearProduction ::JuMP.Containers.DenseAxisArray{<:Real}
    RegionalBaseYearProduction ::JuMP.Containers.DenseAxisArray{<:Real}

    RegionalCCSLimit ::JuMP.Containers.DenseAxisArray{<:Real}

    CapitalCost ::JuMP.Containers.DenseAxisArray{<:Real}
    VariableCost ::JuMP.Containers.DenseAxisArray{<:Real}
    FixedCost ::JuMP.Containers.DenseAxisArray{<:Real}

    StorageLevelStart ::JuMP.Containers.DenseAxisArray{<:Real}
    StorageMaxChargeRate ::JuMP.Containers.DenseAxisArray{<:Real}
    StorageMaxDischargeRate ::JuMP.Containers.DenseAxisArray{<:Real}
    MinStorageCharge ::JuMP.Containers.DenseAxisArray{<:Real}
    OperationalLifeStorage ::JuMP.Containers.DenseAxisArray{<:Real}
    CapitalCostStorage ::JuMP.Containers.DenseAxisArray{<:Real}
    ResidualStorageCapacity ::JuMP.Containers.DenseAxisArray{<:Real}
    TechnologyToStorage ::JuMP.Containers.DenseAxisArray{<:Real}
    TechnologyFromStorage ::JuMP.Containers.DenseAxisArray{<:Real}

    StorageMaxCapacity ::JuMP.Containers.DenseAxisArray{<:Real}

    TotalAnnualMaxCapacity ::JuMP.Containers.DenseAxisArray{<:Real}
    TotalAnnualMinCapacity ::JuMP.Containers.DenseAxisArray{<:Real}

    TagTechnologyToSector ::JuMP.Containers.DenseAxisArray{<:Real}
    AnnualSectoralEmissionLimit ::JuMP.Containers.DenseAxisArray{<:Real}

    TotalAnnualMaxCapacityInvestment ::JuMP.Containers.DenseAxisArray{<:Real}
    TotalAnnualMinCapacityInvestment ::JuMP.Containers.DenseAxisArray{<:Real}

    TotalTechnologyAnnualActivityUpperLimit ::JuMP.Containers.DenseAxisArray{<:Real}
    TotalTechnologyAnnualActivityLowerLimit ::JuMP.Containers.DenseAxisArray{<:Real}
    TotalTechnologyModelPeriodActivityUpperLimit ::JuMP.Containers.DenseAxisArray{<:Real}
    TotalTechnologyModelPeriodActivityLowerLimit ::JuMP.Containers.DenseAxisArray{<:Real}

    ReserveMarginTagTechnology ::JuMP.Containers.DenseAxisArray{<:Real}
    ReserveMarginTagFuel ::JuMP.Containers.DenseAxisArray{<:Real}
    ReserveMargin ::JuMP.Containers.DenseAxisArray{<:Real}

    RETagTechnology ::JuMP.Containers.DenseAxisArray{<:Real}
    RETagFuel ::JuMP.Containers.DenseAxisArray{<:Real}
    REMinProductionTarget ::JuMP.Containers.DenseAxisArray{<:Real}

    EmissionActivityRatio ::JuMP.Containers.DenseAxisArray{<:Real}
    EmissionContentPerFuel ::JuMP.Containers.DenseAxisArray{<:Real}
    EmissionsPenalty ::JuMP.Containers.DenseAxisArray{<:Real}
    EmissionsPenaltyTagTechnology ::JuMP.Containers.DenseAxisArray{<:Real}
    AnnualExogenousEmission ::JuMP.Containers.DenseAxisArray{<:Real}
    AnnualEmissionLimit ::JuMP.Containers.DenseAxisArray{<:Real}
    RegionalAnnualEmissionLimit ::JuMP.Containers.DenseAxisArray{<:Real}
    ModelPeriodExogenousEmission ::JuMP.Containers.DenseAxisArray{<:Real}
    ModelPeriodEmissionLimit ::JuMP.Containers.DenseAxisArray{<:Real}
    RegionalModelPeriodEmissionLimit ::JuMP.Containers.DenseAxisArray{<:Real}
    CurtailmentCostFactor ::JuMP.Containers.DenseAxisArray{<:Real}

    Readin_TradeRoute2015 ::JuMP.Containers.DenseAxisArray{<:Real}
    Readin_PowerTradeCapacity ::JuMP.Containers.DenseAxisArray{<:Real}
    TradeRoute ::JuMP.Containers.DenseAxisArray{<:Real}
    TradeCosts ::JuMP.Containers.DenseAxisArray{<:Real}
    TradeLossFactor ::JuMP.Containers.DenseAxisArray{<:Real}
    TradeRouteInstalledCapacity ::JuMP.Containers.DenseAxisArray{<:Real}
    TradeLossBetweenRegions ::JuMP.Containers.DenseAxisArray{<:Real}


    AdditionalTradeCapacity ::JuMP.Containers.DenseAxisArray{<:Real}
    TradeCapacity ::JuMP.Containers.DenseAxisArray{<:Real}
    TradeCapacityGrowthCosts ::JuMP.Containers.DenseAxisArray{<:Real}
    GrowthRateTradeCapacity ::JuMP.Containers.DenseAxisArray{<:Real}

    SelfSufficiency ::JuMP.Containers.DenseAxisArray{<:Real}

    Conversionls ::JuMP.Containers.DenseAxisArray{<:Real}
    Conversionld ::JuMP.Containers.DenseAxisArray{<:Real}
    Conversionlh ::JuMP.Containers.DenseAxisArray{<:Real}
    DaySplit ::JuMP.Containers.DenseAxisArray{<:Real}

    RampingUpFactor ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    RampingDownFactor ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    ProductionChangeCost ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    MinActiveProductionPerTimeslice ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}

    ModalSplitByFuelAndModalType ::JuMP.Containers.DenseAxisArray{<:Real}
    TagTechnologyToModalType ::JuMP.Containers.DenseAxisArray{<:Real}

    EFactorConstruction ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    EFactorOM ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    EFactorManufacturing ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    EFactorFuelSupply ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    EFactorCoalJobs ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    CoalSupply ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    CoalDigging ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    RegionalAdjustmentFactor ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    LocalManufacturingFactor ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    DeclineRate ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    x_peakingDemand ::Union{Nothing,JuMP.Containers.DenseAxisArray{<:Real}}
    
    TagDemandFuelToSector ::JuMP.Containers.DenseAxisArray{<:Real}
    TagElectricTechnology ::JuMP.Containers.DenseAxisArray{<:Real}
end

struct Settings <: InputClass
    DepreciationMethod ::JuMP.Containers.DenseAxisArray
    GeneralDiscountRate ::JuMP.Containers.DenseAxisArray
    TechnologyDiscountRate ::JuMP.Containers.DenseAxisArray
    SocialDiscountRate ::JuMP.Containers.DenseAxisArray
    DaysInDayType ::Float64
    InvestmentLimit ::Float64
    NewRESCapacity ::Float64
    ProductionGrowthLimit ::JuMP.Containers.DenseAxisArray
    StorageLimitOffset  ::Float64
    Trajectory2020UpperLimit ::Float64
    Trajectory2020LowerLimit ::Float64
    PhaseIn ::Dict
    PhaseOut ::Dict
end 

struct Sets <: InputClass
    Timeslice_full ::UnitRange{Int64}
    DailyTimeBracket ::Vector{Int}
    Year_full ::Vector{Int}
    Emission ::Vector{String}
    Technology ::Vector{String}
    Fuel ::Vector{String}
    Year ::Vector{Int}
    Timeslice ::Vector{Int}
    Mode_of_operation ::Vector{Int}
    Region_full ::Vector{String}
    Season ::Vector{Int}
    Daytype ::Vector{Int}
    Storage ::Vector{String}
    ModalType ::Vector{String}
    Sector ::Vector{String}
end

struct Emp_Sets <: InputClass
    Technology ::Union{Nothing,Array}
    Year ::Union{Nothing,Array}
    Region ::Union{Nothing,Array}
end

struct SubsetsIni <: InputClass
    Solar ::Array
    Wind ::Array
    Renewables ::Array
    CCS ::Array
    Transformation ::Array
    RenewableTransformation ::Array
    FossilFuelGeneration ::Array 
    FossilFuels ::Array
    FossilPower ::Array
    CHPs ::Array
    RenewableTransport ::Array
    Transport ::Array
    Passenger ::Array
    Freight ::Array
    TransportFuels ::Array 
    ImportTechnology ::Array
    Heat ::Array
    PowerSupply ::Array
    PowerBiomass ::Array
    Coal ::Array
    Lignite ::Array
    Gas ::Array
    StorageDummies ::Array
    SectorCoupling ::Array 
    HeatFuels ::Array
    ModalGroups ::Array
    PhaseInSet ::Array
    PhaseOutSet ::Array
    HeatSlowRamper ::Array
    HeatQuickRamper ::Array
    Hydro ::Array
    Geothermal ::Array
    Onshore ::Array 
    Offshore ::Array
    SolarUtility ::Array
    Oil ::Array
    HeatLowRes ::Array
    HeatLowInd ::Array
    HeatMedInd ::Array
    HeatHighInd ::Array
    Biomass ::Array
    Households ::Array
    Companies ::Array
    HydrogenTechnologies ::Array
    DummyTechnology ::Array
end

struct Switch <: InputClass
    StartYear :: Int16
    switch_only_load_gdx ::Int8
    switch_test_data_load ::Int8
    solver 
    DNLPsolver
    model_region ::String
    data_base_region ::String
    data_file ::String
    timeseries_data_file ::String
    threads ::Int16
    emissionPathway ::String
    emissionScenario ::String
    socialdiscountrate ::Float64
    inputdir ::String
    tempdir ::String
    resultdir ::String
    switch_infeasibility_tech :: Int8
    switch_investLimit ::Int16
    switch_ccs ::Int16
    switch_ramping ::Int16
    switch_weighted_emissions ::Int16
    switch_intertemporal ::Int16
    switch_short_term_storage ::Int16
    switch_base_year_bounds ::Int16
    switch_peaking_capacity ::Int16
    set_peaking_slack ::Float16
    set_peaking_minrun_share ::Float16
    set_peaking_res_cf ::Float16
    set_peaking_startyear ::Int16
    switch_peaking_with_storages ::Int16
    switch_peaking_with_trade ::Int16
    switch_peaking_minrun ::Int16
    switch_employment_calculation ::Int16
    switch_endogenous_employment ::Int16
    employment_data_file ::String
    switch_dispatch ::Int8
    hourly_data_file ::String
    elmod_nthhour ::Int16
    elmod_starthour ::Int16
    elmod_dunkelflaute ::Int16
    elmod_daystep ::Int16
    elmod_hourstep ::Int16
    switch_raw_results ::Int8
    switch_processed_results ::Int8
    write_reduced_timeserie ::Int8

end

struct Variable_Parameters <: InputClass
    RateOfTotalActivity ::JuMP.Containers.DenseAxisArray
    RateOfProductionByTechnologyByMode ::JuMP.Containers.DenseAxisArray
    RateOfUseByTechnologyByMode ::JuMP.Containers.DenseAxisArray
    RateOfProductionByTechnology ::JuMP.Containers.DenseAxisArray
    RateOfUseByTechnology ::JuMP.Containers.DenseAxisArray
    ProductionByTechnology ::JuMP.Containers.DenseAxisArray
    UseByTechnology ::JuMP.Containers.DenseAxisArray
    RateOfProduction ::JuMP.Containers.DenseAxisArray
    RateOfUse ::JuMP.Containers.DenseAxisArray
    Production ::JuMP.Containers.DenseAxisArray
    Use ::JuMP.Containers.DenseAxisArray
    ProductionAnnual ::JuMP.Containers.DenseAxisArray
    UseAnnual ::JuMP.Containers.DenseAxisArray
end