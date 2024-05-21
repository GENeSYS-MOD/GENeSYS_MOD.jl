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
# #############################################################

"""
Internal function used in the run process to set run settings such as dicount rates.
"""
function genesysmod_scenariodata(model, Sets, Params,Vars, Settings, Switch)
    # for y ∈ Sets.Year for r ∈ Sets.Region_full
    #     Params.AvailabilityFactor[r,"P_Biomass",y] = 0
    # end end

    # for r ∈ Sets.Region_full for t ∈ Sets.Technology for y ∈ Sets.Year
    #     Params.CapitalCost[r,"RES_Wind_Onshore_Avg",y] = 5000
    #     Params.CapitalCost[r,"RES_Wind_Onshore_Inf",y] = 5000
    #     Params.CapitalCost[r,"RES_Wind_Onshore_Opt",y] = 5000
    # end end end
    
    for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
        if (t in Params.TagTechnologyToSubsets["SolarUtility"]) && (Params.TotalAnnualMaxCapacity[r,t,y] < 999999) && (Params.TotalAnnualMaxCapacity[r,t,y] > 0)
          @constraint(model, sum(Vars.TotalCapacityAnnual[y, tt, r] for tt in Params.TagTechnologyToSubsets["SolarUtility"]) <= Params.TotalAnnualMaxCapacity[r,t,y], base_name="TCC1_SolarUtilityTotalAnnualMaxCapacityConstraint_$(y)_$(t)_$(r)")    
        elseif (Params.TotalAnnualMaxCapacity[r,t,y] < 999999) && (Params.TotalAnnualMaxCapacity[r,t,y] > 0)
          @constraint(model, Vars.TotalCapacityAnnual[y,t,r] <= Params.TotalAnnualMaxCapacity[r,t,y], base_name="TCC1_TotalAnnualMaxCapacityConstraint_$(y)_$(t)_$(r)")
        elseif Params.TotalAnnualMaxCapacity[r,t,y] == 0
          JuMP.fix(Vars.TotalCapacityAnnual[y,t,r],0; force=true)
        end
    end end end

    # if Switch.switch_ccs == 0
    #     offshore_nordic = [:DE_Nord, :DE_NI, :DE_SH]
    #     #offshore_baltic = [:DE_Baltic, :DE_MV, :DE_SH]
    #     for y ∈ Sets.Year
    #         constraint(model,sum((model[:TotalCapacityAnnual][2025,t,r] for r ∈ offshore_nordic for t ∈ Subsets.Offshore) => 9.4), basename="menounderstand")
    #     end
    # end
        
end
