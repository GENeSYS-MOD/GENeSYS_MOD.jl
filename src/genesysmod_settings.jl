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
function genesysmod_settings(Sets, Subsets, Params, socialdiscountrate)

    DepreciationMethod=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full)), Sets.Region_full)
    GeneralDiscountRate=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full)), Sets.Region_full)
    TechnologyDiscountRate=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Sets.Technology)), Sets.Region_full, Sets.Technology)
    SocialDiscountRate=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full)), Sets.Region_full)
    for r ∈ Sets.Region_full
        DepreciationMethod[r] = 1
        GeneralDiscountRate[r] = Float64(0.05)
        for t ∈ Subsets.Companies
            TechnologyDiscountRate[r,t] = Float64(0.05)
        end
        for t ∈ Subsets.Households
            TechnologyDiscountRate[r,t] = Float64(0.05)
        end
        SocialDiscountRate[r] = socialdiscountrate
    end

    InvestmentLimit = Float64(1.8)  #Freedom for investment choices to spread across periods. A value of 1 would mean equal share for each period.
    NewRESCapacity = Float64(0.1)
    ProductionGrowthLimit=JuMP.Containers.DenseAxisArray(zeros(length(Sets.Year), length(Sets.Fuel)), Sets.Year, Sets.Fuel)
    for y ∈ Sets.Year for f ∈ Sets.Fuel
        if f ∈ vcat(["Power"],Subsets.HeatFuels,Subsets.TransportFuels)
            ProductionGrowthLimit[y,f] = Float64(0.05)
        end
        if f == "Air"
            ProductionGrowthLimit[y,f] = Float64(0.025)
        end
    end end
    StorageLimitOffset = Float64(0.015)

    Trajectory2020UpperLimit = 3
    Trajectory2020LowerLimit = Float64(0.7)
    for y ∈ Sets.Year for r ∈ Sets.Region_full for rr ∈ Sets.Region_full
        Params.GrowthRateTradeCapacity[y,"Power",r,rr]=0.1 #to remove in favor of the excel after testing
    end end end
    #GrowthRateTradeCapacity(y,'Power',r,rr) = 0.1;

    BaseYearSlack = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Fuel)), Sets.Fuel)
    BaseYearSlack[Sets.Fuel] .= 0.03
    BaseYearSlack["Power"] = 0.03

    PhaseOut = Dict(2020=>2, 2025=>2, 2030=>2, 2035=>2, 2040=>2 ,2045=>2, 2050=>2)# this is an upper limit for fossil generation based on the previous year - to remove choose large value

    PhaseIn = Dict(2020=>1, 2025=>0.85, 2030=>0.85, 2035=>0.85, 2040=>0.85 ,2045=>0.85, 2050=>0.85) # this is a lower bound for renewable integration based on the previous year - to remove choose 0

    Settings=GENeSYS_MOD.Settings(DepreciationMethod,GeneralDiscountRate,TechnologyDiscountRate,SocialDiscountRate,InvestmentLimit,NewRESCapacity,
    ProductionGrowthLimit,StorageLimitOffset,Trajectory2020UpperLimit,Trajectory2020LowerLimit, BaseYearSlack, PhaseIn, PhaseOut)
    return Settings
end
