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
Internal function used in the run process to set run settings such as dicount rates.
"""
function genesysmod_settings(Sets, Params, socialdiscountrate)

    DepreciationMethod=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full)), Sets.Region_full)
    GeneralDiscountRate=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full)), Sets.Region_full)
    TechnologyDiscountRate=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Technology)), Sets.Region_full, Sets.Technology)
    SocialDiscountRate=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full)), Sets.Region_full)
    for r ∈ Sets.Region_full
        DepreciationMethod[r] = 1
        GeneralDiscountRate[r] = Float64(0.05)
        for t ∈ setdiff(Sets.Technology,Params.TagTechnologyToSubsets["Households"])
            TechnologyDiscountRate[r,t] = Float64(0.05)
        end
        for t ∈ Params.TagTechnologyToSubsets["Households"]
            TechnologyDiscountRate[r,t] = Float64(0.05)
        end
        SocialDiscountRate[r] = socialdiscountrate
    end

    InvestmentLimit = Float64(1.9)  #Freedom for investment choices to spread across periods. A value of 1 would mean equal share for each period.1.9
    NewRESCapacity = Float64(0.1)  #0.1
    ProductionGrowthLimit=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel)), Sets.Year, Sets.Fuel)
    for y ∈ Sets.Year for f ∈ Sets.Fuel
        if f ∈ vcat(["Power"],Params.TagFuelToSubsets["HeatFuels"],Params.TagFuelToSubsets["TransportFuels"])
            ProductionGrowthLimit[y,f] = Float64(0.09)
        end
        if f == "Air"
            ProductionGrowthLimit[y,f] = Float64(0.025)
        end
    end end
    StorageLimitOffset = Float64(0.015)

    Trajectory2020UpperLimit = 3
    Trajectory2020LowerLimit = Float64(0.7)

    BaseYearSlack = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Fuel)), Sets.Fuel)
    BaseYearSlack[Sets.Fuel] .= 0.035
    BaseYearSlack["Power"] = 0.035

    PhaseOut = Dict(2020=>3, 2025=>3, 2030=>3, 2035=>2.5, 2040=>2.5 ,2045=>2, 2050=>2)# this is an upper limit for fossil generation based on the previous year - to remove choose large value

    PhaseIn = Dict(2020=>1, 2025=>0.8, 2030=>0.7, 2035=>0.7, 2040=>0.7 ,2045=>0.6, 2050=>0.5) # this is a lower bound for renewable integration based on the previous year - to remove choose 0

    StorageLevelYearStartUpperLimit = Float64(0.75)
    StorageLevelYearStartLowerLimit = Float64(0.75)


    Settings=GENeSYS_MOD.Settings(DepreciationMethod,GeneralDiscountRate,TechnologyDiscountRate,SocialDiscountRate,InvestmentLimit,NewRESCapacity,
    ProductionGrowthLimit,StorageLimitOffset,Trajectory2020UpperLimit,Trajectory2020LowerLimit, BaseYearSlack, PhaseIn, PhaseOut, StorageLevelYearStartUpperLimit, StorageLevelYearStartLowerLimit)
    return Settings
end
