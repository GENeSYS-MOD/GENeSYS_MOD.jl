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
# test
"""
Internal function used in the run process to set run settings such as dicount rates.
"""
function genesysmod_scenariodata(model, Sets, Params, Vars, Settings, Switch)
  
  for f ∈ Sets.Fuel for r ∈ Sets.Region_full for rr ∈ Sets.Region_full
    Params.TradeCapacityGrowthCosts[r,rr,"Gas_Natural"] = 0.0039
    Params.TradeCapacityGrowthCosts[r,rr,"H2"] = 0.0053
    Params.TradeCapacityGrowthCosts[r,rr,"LSG"] = 0.0053
    Params.TradeCapacityGrowthCosts[r,rr,"LH2"] = 0.0053
  end end end
  
  for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full for rr ∈ Sets.Region_full  
    Params.GrowthRateTradeCapacity[r,rr,"Gas_Natural",y] = 0.1
    Params.GrowthRateTradeCapacity[r,rr,"H2",y] = 0.15
  end end end end
  ######Availability Factor Gas to zero
  for r ∈ Sets.Region_full 
    Params.AvailabilityFactor[r,"Z_Import_Gas",2018] = 0
  end
  ############################### Settings 2025 ###############################################
  #####  Solar Capacity Cap for 2025
  @constraint(model, 
    sum(Vars.TotalCapacityAnnual[2025, t, r] for r in Sets.Region_full, t in Params.TagTechnologyToSubsets["Solar"]) <= 13, 
    base_name="JH_PvRestriction_Total_2025")
  #####
  #####  Wind Capacity Cap for 2025
  @constraint(model, 
    sum(Vars.TotalCapacityAnnual[2025, t, r] for r in Sets.Region_full, t in Params.TagTechnologyToSubsets["Wind"]) <= 9, 
    base_name="JH_WindRestriction_Total_2025")
  #####

  #####  Hydro Capacity Cap for 2025
  @constraint(model, 
    sum(Vars.TotalCapacityAnnual[2025, t, r] for r in Sets.Region_full, t in Params.TagTechnologyToSubsets["Hydro"]) <= 4, 
    base_name="JH_HydroRestriction_Total_2025")
  #####

  ###### P_Gas_OCGT Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"P_Gas_OCGT", r] for r in Sets.Region_full) <= 5, 
  base_name="JH_Gas_1_Restriction_Total_2025")
  #####
  
  ###### P_Gas_CCGT Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"P_Gas_CCGT", r] for r in Sets.Region_full) <= 0.1, 
  base_name="JH_Gas_2_Restriction_Total_2025")
  #####  

  ###### CHP_Gas_CCGT_Natural Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"CHP_Gas_CCGT_Natural", r] for r in Sets.Region_full) <= 0.1, 
  base_name="JH_Gas_3_Restriction_Total_2025")
  #####  

  ###### P_Gas_Engines Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"P_Gas_Engines", r] for r in Sets.Region_full) <= 0.1, 
  base_name="JH_Gas_4_Restriction_Total_2025")
  #####  

  ###### CHP_Gas_CCGT_Biogas Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"CHP_Gas_CCGT_Biogas", r] for r in Sets.Region_full) <= 0.1, 
  base_name="JH_Gas_5_Restriction_Total_2025")
  #####  

  ###### CHP_Gas_CCGT_SynGas Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"CHP_Gas_CCGT_SynGas", r] for r in Sets.Region_full) <= 0.1, 
  base_name="JH_Gas_6_Restriction_Total_2025")
  #####  

  ###### RES_Wind_Offshore_Transitional Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"RES_Wind_Offshore_Transitional", r] for r in Sets.Region_full) <= 0.1, 
  base_name="JH_Wind_offshore_Transitional_Restriction_Total_2025")
  #####  
  ###### RES_Wind_Offshore_Shallow Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"RES_Wind_Offshore_Shallow", r] for r in Sets.Region_full) <= 0.1, 
  base_name="JH_Wind_offshore_Shallow_Restriction_Total_2025")
  #####  
  ###### RES_Wind_Offshore_Deep Cap for 2025
  @constraint(model, 
  sum(Vars.TotalCapacityAnnual[2025,"RES_Wind_Offshore_Deep", r] for r in Sets.Region_full) <= 0.1, 
  base_name="JH_Wind_offshore_Deep_Restriction_Total_2025")
  #####  



  #No new PV technologies in 2018 & 2025
  #tracking not allowed
  for r ∈ Sets.Region_full
    Params.AvailabilityFactor[r,"RES_PV_Utility_HSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_PV_Utility_THSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_PV_Utility_VSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_PV_Utility_DAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_HSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_THSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_VSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_DAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_PV_Utility_HSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_PV_Utility_THSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_PV_Utility_VSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_PV_Utility_DAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_HSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_THSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_VSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_DAT",2025] = 0
  end
  
  #bifacial not allowed
  for r ∈ Sets.Region_full
    Params.AvailabilityFactor[r,"RES_BPV_Utility_HSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_THSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_VSAT",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_DAT",2018] = 0 
    Params.AvailabilityFactor[r,"RES_BPV_Utility_90",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_Opt",2018] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_HSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_THSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_VSAT",2025] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_DAT",2025] = 0 
    Params.AvailabilityFactor[r,"RES_BPV_Utility_90",2025] = 0
    Params.AvailabilityFactor[r,"RES_BPV_Utility_Opt",2025] = 0

  end


  for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
    if (t in Params.TagTechnologyToSubsets["SolarUtility"]) && (Params.TotalAnnualMaxCapacity[r,t,y] < 999999) && (Params.TotalAnnualMaxCapacity[r,t,y] > 0)
      @constraint(model, sum(Vars.TotalCapacityAnnual[y, tt, r] for tt in Params.TagTechnologyToSubsets["SolarUtility"]) 
      <= Params.TotalAnnualMaxCapacity[r,t,y], base_name="TCC1_SolarUtilityTotalAnnualMaxCapacityConstraint_$(y)_$(t)_$(r)")    
    elseif (Params.TotalAnnualMaxCapacity[r,t,y] < 999999) && (Params.TotalAnnualMaxCapacity[r,t,y] > 0)
      @constraint(model, Vars.TotalCapacityAnnual[y,t,r] <= Params.TotalAnnualMaxCapacity[r,t,y], base_name="TCC1_TotalAnnualMaxCapacityConstraint_$(y)_$(t)_$(r)")
    elseif Params.TotalAnnualMaxCapacity[r,t,y] == 0
      JuMP.fix(Vars.TotalCapacityAnnual[y,t,r],0; force=true)
    end
  end end end

  #Nuclear
  for y ∈ Sets.Year for r ∈ Sets.Region_full
    Params.TotalAnnualMaxCapacity[r,"P_Nuclear",y] = Params.ResidualCapacity[r,"P_Nuclear",y]
  end end

  #Scenrios
  #2degree emission pathway
  if Switch.switch_2degree == 1
    Params.AnnualEmissionLimit["CO2", 2018] = 310
    Params.AnnualEmissionLimit["CO2", 2025] = 240
    Params.AnnualEmissionLimit["CO2", 2030] = 170
    Params.AnnualEmissionLimit["CO2", 2035] = 100
    Params.AnnualEmissionLimit["CO2", 2040] = 40
    Params.AnnualEmissionLimit["CO2", 2045] = 20
    Params.AnnualEmissionLimit["CO2", 2050] = 0.1
  end

  #hydrogen demand
  if Switch.switch_highH2 == 1
    Params.SpecifiedAnnualDemand["SA-EC", "H2", 2018] = 0.0025
    Params.SpecifiedAnnualDemand["SA-KW", "H2", 2018] = 0.0025
    Params.SpecifiedAnnualDemand["SA-NC", "H2", 2018] = 0.0025
    Params.SpecifiedAnnualDemand["SA-WC", "H2", 2018] = 0.0025
    
    Params.SpecifiedAnnualDemand["SA-EC", "H2", 2025] = 0.0025
    Params.SpecifiedAnnualDemand["SA-KW", "H2", 2025] = 0.0025
    Params.SpecifiedAnnualDemand["SA-NC", "H2", 2025] = 0.0025
    Params.SpecifiedAnnualDemand["SA-WC", "H2", 2025] = 0.0025
    
    Params.SpecifiedAnnualDemand["SA-EC", "H2", 2030] = 41.25
    Params.SpecifiedAnnualDemand["SA-KW", "H2", 2030] = 41.25
    Params.SpecifiedAnnualDemand["SA-NC", "H2", 2030] = 41.25
    Params.SpecifiedAnnualDemand["SA-WC", "H2", 2030] = 41.25
    
    Params.SpecifiedAnnualDemand["SA-EC", "H2", 2035] = 60.75
    Params.SpecifiedAnnualDemand["SA-KW", "H2", 2035] = 60.75
    Params.SpecifiedAnnualDemand["SA-NC", "H2", 2035] = 60.75
    Params.SpecifiedAnnualDemand["SA-WC", "H2", 2035] = 60.75
    
    Params.SpecifiedAnnualDemand["SA-EC", "H2", 2040] = 80
    Params.SpecifiedAnnualDemand["SA-KW", "H2", 2040] = 80
    Params.SpecifiedAnnualDemand["SA-NC", "H2", 2040] = 80
    Params.SpecifiedAnnualDemand["SA-WC", "H2", 2040] = 80
    
    Params.SpecifiedAnnualDemand["SA-EC", "H2", 2045] = 88.5
    Params.SpecifiedAnnualDemand["SA-KW", "H2", 2045] = 88.5
    Params.SpecifiedAnnualDemand["SA-NC", "H2", 2045] = 88.5
    Params.SpecifiedAnnualDemand["SA-WC", "H2", 2045] = 88.5
    
    Params.SpecifiedAnnualDemand["SA-EC", "H2", 2050] = 112.5
    Params.SpecifiedAnnualDemand["SA-KW", "H2", 2050] = 112.5
    Params.SpecifiedAnnualDemand["SA-NC", "H2", 2050] = 112.5
    Params.SpecifiedAnnualDemand["SA-WC", "H2", 2050] = 112.5
    for y ∈ Sets.Year for r ∈ Sets.Region_full
      Params.AvailabilityFactor[r,"Z_Import_H2",y] = 0
    end end
  end

  #tracking not allowed
  if Switch.switch_PVtracking == 0
    for y ∈ Sets.Year for r ∈ Sets.Region_full
      Params.AvailabilityFactor[r,"RES_PV_Utility_HSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_PV_Utility_THSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_PV_Utility_VSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_PV_Utility_DAT",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_HSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_THSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_VSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_DAT",y] = 0
    end end
  end

  #bifacial not allowed
  if Switch.switch_bifacialPV == 0
    for y ∈ Sets.Year for r ∈ Sets.Region_full
      Params.AvailabilityFactor[r,"RES_BPV_Utility_HSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_THSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_VSAT",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_DAT",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_90",y] = 0
      Params.AvailabilityFactor[r,"RES_BPV_Utility_Opt",y] = 0
    end end
  end

end