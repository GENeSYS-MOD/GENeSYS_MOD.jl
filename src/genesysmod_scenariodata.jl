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
function genesysmod_scenariodata(model, Sets, Params, Vars, Settings, Switch)


    for y ∈ Sets.Year
        Params.TradeCapacity["DE_Nord","DE_SH","Power",y] = 5
        Params.TradeCapacity["DE_Nord","DE_NI","Power",y] = 5
        Params.TradeCapacity["DE_Baltic","DE_SH","Power",y] = 2.5
        Params.TradeCapacity["DE_Baltic","DE_MV","Power",y] = 2.5
    end

    # if Switch.switch_ccs == 0
    #     offshore_nordic = [:DE_Nord, :DE_NI, :DE_SH]
    #     #offshore_baltic = [:DE_Baltic, :DE_MV, :DE_SH]
    #     for y ∈ Sets.Year
    #         constraint(model,sum((model[:TotalCapacityAnnual][2025,t,r] for r ∈ offshore_nordic for t ∈ Subsets.Offshore) => 9.4), basename="menounderstand")
    #     end
    # end


    
    # for r ∈ Sets.Region_full
    #     JuMP.fix(Vars.ProductionByTechnologyAnnual[2018,"RES_PV_Utility_Opt","Power",r], 0.1; force=true)
    # end

    for f ∈ Sets.Fuel for y ∈ Sets.Year
        @constraint(model,
        sum(Vars.ProductionByTechnologyAnnual[y,"N_Import_Power", "Power", r] for r ∈ ["DE_MV", "DE_BB", "DE_SN"]) <= Params.ImportFromNeighbours["DE_BB","Power",y],
        base_name="NI_PL1_PowerImportFromPoland$(y)_$(f)")
    end end





    
  

    
end
