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
# Unless required by applicable law || agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express || implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# #############################################################

function genesysmod_equ(gm)
  
  println("Building model")

  model = gm.model
  Sets = gm.sets
  Params = gm.params
  Switch = gm.switch


  reset_timer!(to)
   ######################
   # Objective Function #
   ######################
  
  @timeit to "Building" begin
  @timeit to "Objective" build_obj(gm)


   ###############
   # Constraints #
   ###############

  
   ############### Capacity Adequacy A #############
  
  @timeit to "Cap Adequacy A1" addConstraint_CapAdequacyA1(gm)
  @timeit to "Cap Adequacy A2" addConstraint_CapAdequacyA2(gm)
  @timeit to "Cap Adequacy A3" addConstraint_CapAdequacyA3(gm)
   ############### Capacity Adequacy B #############
  
  @timeit to "Cap Adequacy B" addConstraint_CapAdequacyB(gm)
   ############### Energy Balance A #############
  
  @timeit to "Energy Balance A1" addConstraint_EnergyBalanceA1(gm)
  
  @timeit to "Energy Balance A2" addConstraint_EnergyBalanceA2(gm)

   ############### Energy Balance B #############
  
  @timeit to "Energy Balance B" addConstraint_EnergyBalanceB(gm)

   ############### Trade Capacities & Investments #############
  
  @timeit to "TradeCapacity" addConstraint_TradeCapacity(gm)
  
   ############### Trading Costs #############
  @timeit to "TradeCost" addConstraint_TradeCost(gm)
  
   ############### Accounting Technology Production/Use #############
  
  @timeit to "Acc. Tech. 1" addConstraint_AccTech1(gm)
  @timeit to "Acc. Tech. 2" addConstraint_AccTech2(gm)
 
   ############### Capital Costs #############
  @timeit to "Cap. Cost" addConstraint_CapCost(gm)
   ############### Investment & Capacity Limits #############
  @timeit to "Investment & Capacity Limits" addConstraint_InvCapLimits(gm)
 
   ############### Salvage Value #############
  
  @timeit to "Salvage" addConstraint_Salvage(gm)
  
   ############### Operating Costs #############
  
  @timeit to "Op. Cost" addConstraint_OpCost(gm)
  

   ############### Total Discounted Costs #############
  
  @timeit to "Tot. Disc. Cost" addConstraint_DiscCost(gm)
  
   ############### Total Capacity Constraints ##############
  
  @timeit to "Tot. Cap" addConstraint_capacity(gm)
  
   ############### New Capacity Constraints ##############
  
  @timeit to "New capacity" addConstraint_newcapacity(gm)

  
   ################ Annual Activity Constraints ##############
  
  @timeit to "Annual. Activity" addConstraint_AnnualActivity(gm)
  
   ################ Total Activity Constraints ##############
  
  @timeit to "Tot. Activity" addConstraint_TotalActivity(gm)

  
   ############### Reserve Margin Constraint ############## NTS: Should change demand for production
  if Switch.switch_dispatch == 0
    @timeit to "Reserve Marging" addConstraint_ReserveMargin(gm)
  end
  
   ############### RE Production Target ############## NTS: Should change demand for production
  @timeit to "RE target" begin
    @timeit to "RE target1" begin
    addConstraint_REtarget1(gm)
    end
    
    @timeit to "RE target2" begin
    addConstraint_REtarget2(gm)
    end

    @timeit to "RE target3" begin
    addConstraint_REtarget3(gm)
    end

    @timeit to "RE target4" begin
    addConstraint_REtarget4(gm)
    end

    
    if Switch.switch_dispatch == 0
      @timeit to "RE target switch_dispatch" begin
      addConstraint_REtarget_switch_dispatch(gm)
      end
    end

    @timeit to "RE target5" addConstraint_REtarget5(gm)
    @timeit to "RE target6" addConstraint_REtarget5(gm)

  end

  end

  show(to)
end



function CanFuelBeUsedByModeByTech(y, f, r,t,m)
  temp = Params.InputActivityRatio[r,t,f,m,y]*
  Params.TotalAnnualMaxCapacity[r,t,y] * 
  sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
  Params.AvailabilityFactor[r,t,y] * 
  Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
  Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y]
  if (!ismissing(temp)) && (temp > 0)
    return 1
  else
    return 0
  end
end

function CanFuelBeUsedByTech(y, f, r,t)
  temp = sum(Params.InputActivityRatio[r,t,f,m,y]*
  Params.TotalAnnualMaxCapacity[r,t,y] * 
  sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
  Params.AvailabilityFactor[r,t,y] * 
  Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
  Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation )
  if (!ismissing(temp)) && (temp > 0)
    return 1
  else
    return 0
  end
end

function CanFuelBeUsed(y, f, r)
  temp = sum(Params.InputActivityRatio[r,t,f,m,y]*
  Params.TotalAnnualMaxCapacity[r,t,y] * 
  sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
  Params.AvailabilityFactor[r,t,y] * 
  Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
  Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology)
  if (!ismissing(temp)) && (temp > 0)
    return 1
  else
    return 0
  end
end

function CanFuelBeUsedInTimeslice(y, l, f, r)
  temp = sum(Params.InputActivityRatio[r,t,f,m,y]*
  Params.TotalAnnualMaxCapacity[r,t,y] * 
  Params.CapacityFactor[r,t,l,y] *
  Params.AvailabilityFactor[r,t,y] * 
  Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
  Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology)
  if (!ismissing(temp)) && (temp > 0)
    return 1
  else
    return 0
  end
end

function CanFuelBeProducedByModeByTech(y, f, r,t,m)
  temp = Params.OutputActivityRatio[r,t,f,m,y]*
  Params.TotalAnnualMaxCapacity[r,t,y] * 
  sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
  Params.AvailabilityFactor[r,t,y] * 
  Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
  Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y]
  if (!ismissing(temp)) && (temp > 0)
    return 1
  else
    return 0
  end
end

function CanFuelBeProducedByTech(y, f, r,t)
  temp = sum(Params.OutputActivityRatio[r,t,f,m,y]*
  Params.TotalAnnualMaxCapacity[r,t,y] * 
  sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice) *
  Params.AvailabilityFactor[r,t,y] * 
  Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
  Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation)
  if (!ismissing(temp)) && (temp > 0)
    return 1
  else
    return 0
  end
end



function CanFuelBeProducedInTimeslice(y, l, f, r)
  temp = sum(Params.OutputActivityRatio[r,t,f,m,y]*
  Params.TotalAnnualMaxCapacity[r,t,y] * 
  Params.CapacityFactor[r,t,l,y] *
  Params.AvailabilityFactor[r,t,y] * 
  Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
  Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology)
  if (!ismissing(temp)) && (temp > 0)
    return 1
  else
    return 0
  end
end



function PureDemandFuel(y, f, r);
  if CanFuelBeUsed(y,f,r) == 0 && Params.SpecifiedAnnualDemand[r,f,y] > 0
    return 1
  else
    return 0
  end
end


 
#   @timeit to "Cstr: Em. Acc. 1" begin
#   for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
#     if CanBuildTechnology[y,t,r] > 0
#       for e ∈ Sets.Emission for m ∈ Sets.Mode_of_operation
#         @constraint(model, Params.EmissionActivityRatio[r,t,e,m,y]*sum((model[:TotalAnnualTechnologyActivityByMode][y,t,m,r]*Params.EmissionContentPerFuel[f,e]*Params.InputActivityRatio[r,t,f,m,y]) for f ∈ Sets.Fuel) == model[:AnnualTechnologyEmissionByMode][y,t,e,m,r] , base_name="E1_AnnualEmissionProductionByMode_$(y)_$(t)_$(e)_$(m)_$(r)" )
#       end end
#     else
#       for m ∈ Sets.Mode_of_operation for e ∈ Sets.Emission
#         JuMP.fix(model[:AnnualTechnologyEmissionByMode][y,t,e,m,r],0; force=true)
#       end end
#     end
#   end end end
#   end

#   @timeit to "Cstr: Em. Acc. 2" begin
#   for y ∈ Sets.Year for r ∈ Sets.Region_full
#     for t ∈ Sets.Technology
#       for e ∈ Sets.Emission
#         @constraint(model, sum(model[:AnnualTechnologyEmissionByMode][y,t,e,m,r] for m ∈ Sets.Mode_of_operation) == model[:AnnualTechnologyEmission][y,t,e,r],
#         base_name="E2_AnnualEmissionProduction_$(y)_$(t)_$(e)_$(r)")

#         @constraint(model, (model[:AnnualTechnologyEmission][y,t,e,r]*Params.EmissionsPenalty[r,e,y]*Params.EmissionsPenaltyTagTechnology[r,t,e,y])*YearlyDifferenceMultiplier(y,Sets) == model[:AnnualTechnologyEmissionPenaltyByEmission][y,t,e,r],
#         base_name="E3_EmissionsPenaltyByTechAndEmission_$(y)_$(t)_$(e)_$(r)")
#       end

#       @constraint(model, sum(model[:AnnualTechnologyEmissionPenaltyByEmission][y,t,e,r] for e ∈ Sets.Emission) == model[:AnnualTechnologyEmissionsPenalty][y,t,r],
#       base_name="E4_EmissionsPenaltyByTechnology_$(y)_$(t)_$(r)")

#       @constraint(model, model[:AnnualTechnologyEmissionsPenalty][y,t,r]/((1+Settings.SocialDiscountRate[r])^(y-Switch.StartYear+0.5)) == model[:DiscountedTechnologyEmissionsPenalty][y,t,r],
#       base_name="E5_DiscountedEmissionsPenaltyByTechnology_$(y)_$(t)_$(r)")
#     end
#   end end 

#   for e ∈ Sets.Emission
#     for y ∈ Sets.Year
#       for r ∈ Sets.Region_full
#         @constraint(model, sum(model[:AnnualTechnologyEmission][y,t,e,r] for t ∈ Sets.Technology) == model[:AnnualEmissions][y,e,r], 
#         base_name="E6_EmissionsAccounting1_$(y)_$(e)_$(r)")

#         @constraint(model, model[:AnnualEmissions][y,e,r]+Params.AnnualExogenousEmission[r,e,y] <= Params.RegionalAnnualEmissionLimit[r,e,y], 
#         base_name="E8_RegionalAnnualEmissionsLimit_$(y)_$(e)_$(r)")
#       end
#       @constraint(model, sum(model[:AnnualEmissions][y,e,r]+Params.AnnualExogenousEmission[r,e,y] for r ∈ Sets.Region_full) <= Params.AnnualEmissionLimit[e,y],
#       base_name="E9_AnnualEmissionsLimit_$(y)_$(e)")
#     end
#     @constraint(model, sum(model[:ModelPeriodEmissions][e,r] for r ∈ Sets.Region_full) <= Params.ModelPeriodEmissionLimit[e],
#     base_name="E10_ModelPeriodEmissionsLimit_$(e)")
#   end
#   end

#   @timeit to "Cstr: Em. Acc. 3" begin
#   for e ∈ Sets.Emission for r ∈ Sets.Region_full
#     if Params.RegionalModelPeriodEmissionLimit[e,r] < 999999
#       @constraint(model, model[:ModelPeriodEmissions][e,r] <= Params.RegionalModelPeriodEmissionLimit[e,r] ,base_name="E11_RegionalModelPeriodEmissionsLimit" )
#     end
#   end end
#   end

#   @timeit to "Cstr: Em. Acc. 4" begin
#   if Switch.switch_weighted_emissions == 1
#     for e ∈ Sets.Emission for r ∈ Sets.Region_full
#       @constraint(model,
#       sum(model[:WeightedAnnualEmissions][Sets.Year[i],e,r]*(Sets.Year[i+1]-Sets.Year[i]) for i ∈ 1:length(Sets.Year)-1 if Sets.Year[i+1]-Sets.Year[i] > 0) +  model[:WeightedAnnualEmissions][Sets.Year[end],e,r] == model[:ModelPeriodEmissions][e,r]- Params.ModelPeriodExogenousEmission[r,e],
#       base_name="E7_EmissionsAccounting2_$(e)_$(r)")

#       @constraint(model,
#       model[:AnnualEmissions][Sets.Year[end],e,r] == model[:WeightedAnnualEmissions][Sets.Year[end],e,r],
#       base_name="E12b_WeightedLastYearEmissions_$(Sets.Year[end])_$(e)_$(r)")
#       for i ∈ 1:length(Sets.Year)-1
#         @constraint(model,
#         (model[:AnnualEmissions][Sets.Year[i],e,r]+model[:AnnualEmissions][Sets.Year[i+1],e,r])/2 == model[:WeightedAnnualEmissions][Sets.Year[i],e,r],
#         base_name="E12a_WeightedEmissions_$(Sets.Year[i])_$(e)_$(r)")
#       end
#     end end
#   else
#     for e ∈ Sets.Emission for r ∈ Sets.Region_full
#       @constraint(model, sum( model[:AnnualEmissions][Sets.Year[ind],e,r]*(Sets.Year[ind+1]-Sets.Year[ind]) for ind ∈ 1:(length(Sets.Year)-1) if Sets.Year[ind+1]-Sets.Year[ind]>0)
#       +  model[:AnnualEmissions][Sets.Year[end],e,r] == model[:ModelPeriodEmissions][e,r]- Params.ModelPeriodExogenousEmission[r,e],
#       base_name="E7_EmissionsAccounting2_$(e)_$(r)")
#     end end
#   end
#   end
   
#    ################ Sectoral Emissions Accounting ##############
#    start=Dates.now()

#    for y ∈ Sets.Year for e ∈ Sets.Emission for se ∈ Sets.Sector
#      for r ∈ Sets.Region_full
#        @constraint(model,
#        sum(model[:AnnualTechnologyEmission][y,t,e,r] for t ∈ Sets.Technology if Params.TagTechnologyToSector[t,se] != 0) == model[:AnnualSectoralEmissions][y,e,se,r],
#        base_name="ES1_AnnualSectorEmissions_$(y)_$(e)_$(se)_$(r)")
#      end
 
#      @constraint(model,
#      sum(model[:AnnualSectoralEmissions][y,e,se,r] for r ∈ Sets.Region_full ) <= Params.AnnualSectoralEmissionLimit[e,se,y],
#      base_name="ES2_AnnualSectorEmissionsLimit_$(y)_$(e)_$(se)")
#    end end end
 
#    print("Cstr: ES: ",Dates.now()-start,"\n")
#     ######### Short-Term Storage Constraints #############
#     start=Dates.now()
 
#    if Switch.switch_short_term_storage == 1 #new storage formulation
#      for r ∈ Sets.Region_full for s ∈ Sets.Storage for i ∈ 1:length(Sets.Year)
#        if i == 1
#          JuMP.fix(model[:StorageLevelYearStart][s, Sets.Year[i], r], Params.StorageLevelStart[r,s];force=true)
#        else
#          @constraint(model, 
#          model[:StorageLevelYearStart][s,Sets.Year[i-1],r] + sum((sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r] * Params.TechnologyToStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies if Params.TechnologyToStorage[Sets.Year[i],m,t,s]>0)
#              - sum( model[:RateOfActivity][Sets.Year[i],l,t,m,r] / Params.TechnologyFromStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies if Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0)) * Params.YearSplit[l,Sets.Year[i]] for l ∈ Sets.Timeslice)
#          == model[:StorageLevelYearStart][s,Sets.Year[i],r],
#          base_name="S1_StorageLevelYearStart_$(r)_$(s)_$(Sets.Year[i])")
         
#          JuMP.fix(model[:StorageLevelYearStart][s, Sets.Year[i], r], 0;force=true)
#        end
       
#        @constraint(model,
#        sum((sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r] * Params.TechnologyToStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies if Params.TechnologyToStorage[Sets.Year[i],m,t,s]>0)
#                  - sum(model[:RateOfActivity][Sets.Year[i],l,t,m,r] / Params.TechnologyFromStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies if Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0)) for l ∈ Sets.Timeslice) == 0,
#                  base_name="S3_StorageRefilling_$(r)_$(s)_$(Sets.Year[i])")
 
#        for j ∈ 1:length(Sets.Timeslice)
#  #=         @constraint(model,
#          (j>1 ? model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j-1],r] +
#              (sum(model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j-1],t,m,r] * Params.TechnologyToStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology if Params.TechnologyToStorage[Sets.Year[i],m,t,s]>0)
#            - sum(model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j-1],t,m,r] / Params.TechnologyFromStorage[Sets.Year[i],m,t,s] for m ∈ Sets.Mode_of_operation for t ∈ Sets.Technology if Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0) * Params.YearSplit[Sets.Timeslice[j-1],Sets.Year[i]]) : 0)
#            + (j == 1 ? model[:StorageLevelYearStart][s,Sets.Year[i],r] : 0)   == model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
#            base_name="S2_StorageLevelTSStart_$(r)_$(s)_$(Sets.Year[i])_$(Sets.Timeslice[j])") =#
 
#          @constraint(model,
#          (j>1 ? model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j-1],r] + 
#          (sum((Params.TechnologyToStorage[Sets.Year[i],m,t,s]>0 ? model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j-1],t,m,r] * Params.TechnologyToStorage[Sets.Year[i],m,t,s] : 0) for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies)
#            - sum((Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0 ? model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j-1],t,m,r] / Params.TechnologyFromStorage[Sets.Year[i],m,t,s] : 0 ) for m ∈ Sets.Mode_of_operation for t ∈ Subsets.StorageDummies)) * Params.YearSplit[Sets.Timeslice[j-1],Sets.Year[i]] : 0)
#            + (j == 1 ? model[:StorageLevelYearStart][s,Sets.Year[i],r] : 0)   == model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
#            base_name="S2_StorageLevelTSStart_$(r)_$(s)_$(Sets.Year[i])_$(Sets.Timeslice[j])")
 
#          @constraint(model,
#          sum(model[:NewStorageCapacity][s,Sets.Year[i],r] + Params.ResidualStorageCapacity[r,s,Sets.Year[i]] for yy ∈ Sets.Year if (Sets.Year[i]-yy < Params.OperationalLifeStorage[r,s,yy] && Sets.Year[i]-yy >= 0))
#          >= model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
#          base_name="SC2_UpperLimit_$(s)_$(Sets.Year[i])_$(Sets.Timeslice[j])_$(r)")
 
#        end
 
#        @constraint(model,
#        Params.CapitalCostStorage[r,s,Sets.Year[i]] * model[:NewStorageCapacity][s,Sets.Year[i],r] == model[:CapitalInvestmentStorage][s,Sets.Year[i],r],
#        base_name="SI4_UndiscountedCapitalInvestmentStorage_$(s)_$(Sets.Year[i])_$(r)")
#        @constraint(model,
#        model[:CapitalInvestmentStorage][s,Sets.Year[i],r]/((1+Settings.GeneralDiscountRate[r])^(Sets.Year[i]-Switch.StartYear+0.5)) == model[:DiscountedCapitalInvestmentStorage][s,Sets.Year[i],r],
#        base_name="SI5_DiscountingCapitalInvestmentStorage_$(s)_$(Sets.Year[i])_$(r)")
#        if ((Sets.Year[i]+Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1) <= Sets.Year[end] )
#          @constraint(model,
#          model[:SalvageValueStorage][s,Sets.Year[i],r] == 0,
#          base_name="SI6_SalvageValueStorageAtEndOfPeriod1_$(s)_$(Sets.Year[i])_$(r)")
#        end
#        if ((Settings.DepreciationMethod[r]==1 && (Sets.Year[i]+Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]==0) || (Settings.DepreciationMethod[r]==2 && (Sets.Year[i]+Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]==0))
#          @constraint(model,
#          model[:CapitalInvestmentStorage][s,Sets.Year[i],r]*(1- Sets.Year[end] - Sets.Year[i]+1)/Params.OperationalLifeStorage[r,s,Sets.Year[i]] == model[:SalvageValueStorage][s,Sets.Year[i],r],
#          base_name="SI7_SalvageValueStorageAtEndOfPeriod2_$(s)_$(Sets.Year[i])_$(r)")
#        end
#        if (Settings.DepreciationMethod[r]==1 && ((Sets.Year[i]+Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]>0))
#          @constraint(model,
#          model[:CapitalInvestmentStorage][s,Sets.Year[i],r]*(1-((1+Settings.GeneralDiscountRate[r])^(Sets.Year[end] - Sets.Year[i]+1)-1)/((1+Settings.GeneralDiscountRate[r])^Params.OperationalLifeStorage[r,s,Sets.Year[i]]-1)) == model[:SalvageValueStorage][s,Sets.Year[i],r],
#          base_name="SI8_SalvageValueStorageAtEndOfPeriod3_$(s)_$(Sets.Year[i])_$(r)")
#        end
#        @constraint(model,
#        model[:SalvageValueStorage][s,Sets.Year[i],r]/((1+Settings.GeneralDiscountRate[r])^(1+max(Sets.Year...) - Switch.StartYear)) == model[:DiscountedSalvageValueStorage][s,Sets.Year[i],r],
#        base_name="SI9_SalvageValueStorageDiscountedToStartYear_$(s)_$(Sets.Year[i])_$(r)")
#        @constraint(model,
#        model[:DiscountedCapitalInvestmentStorage][s,Sets.Year[i],r]-model[:DiscountedSalvageValueStorage][s,Sets.Year[i],r] == model[:TotalDiscountedStorageCost][s,Sets.Year[i],r],
#        base_name="SI10_TotalDiscountedCostByStorage_$(s)_$(Sets.Year[i])_$(r)")
#      end end end
 
#      for s ∈ Sets.Storage for i ∈ 1:length(Sets.Year)
#        for r ∈ Sets.Region_full 
#          if Params.MinStorageCharge[r,s,Sets.Year[i]] > 0
#            for j ∈ 1:length(Sets.Timeslice)
#              @constraint(model, 
#              Params.MinStorageCharge[r,s,Sets.Year[i]]*sum(model[:NewStorageCapacity][s,Sets.Year[i],r] + Params.ResidualStorageCapacity[r,s,Sets.Year[i]] for yy ∈ Sets.Year if (Sets.Year[i]-yy < Params.OperationalLifeStorage[r,s,yy] && Sets.Year[i]-yy >= 0))
#              <= model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
#              base_name="SC1_LowerLimit_$(s)_$(Sets.Year[i])_$(Sets.Timeslice[j])_$(r)")
#            end
#          end
#        end
 
#        for t ∈ Subsets.StorageDummies for m ∈ Sets.Mode_of_operation
#          if Params.TechnologyFromStorage[Sets.Year[i],m,t,s]>0
#            for r ∈ Sets.Region_full for j ∈ 1:length(Sets.Timeslice)
#              @constraint(model,
#              model[:RateOfActivity][Sets.Year[i],Sets.Timeslice[j],t,m,r]/Params.TechnologyFromStorage[Sets.Year[i],m,t,s]*Params.YearSplit[Sets.Timeslice[j],Sets.Year[i]] <= model[:StorageLevelTSStart][s,Sets.Year[i],Sets.Timeslice[j],r],
#              base_name="SC9d_StorageActivityLimit_$(s)_$(t)_$(Sets.Year[i])_$(Sets.Timeslice[j])_$(r)_$(m)")
#            end end
#          end
#        end end
#      end end
#      print("Cstr: Storage 1 : ",Dates.now()-start,"\n")
 
#    else #Formaulation from Osemosys
 
#      @variable(model, NumberOfStorageUnits[Sets.Region_full,Sets.Year,Sets.Storage])
     
#      ######### Storage Constraints #############
#      start=Dates.now()
 
#      for s ∈ Sets.Storage for k ∈ 1:length(Sets.Year) for r ∈ Sets.Region_full
 
#        ######### Storage Investments #############
 
#        @constraint(model,
#        model[:AccumulatedNewStorageCapacity][s,Sets.Year[k],r]+Params.ResidualStorageCapacity[r,s,Sets.Year[k]] == model[:StorageUpperLimit][s,Sets.Year[k],r],
#        base_name="SI1_StorageUpperLimit_$(s)_$(Sets.Year[k])_$(r)")
#        @constraint(model,
#        Params.MinStorageCharge[r,s,Sets.Year[k]]*model[:StorageUpperLimit][s,Sets.Year[k],r] == model[:StorageLowerLimit][s,Sets.Year[k],r],
#        base_name="SI2_StorageLowerLimit_$(s)_$(Sets.Year[k])_$(r)")
#        @constraint(model,
#        sum(model[:NewStorageCapacity][s,yy,r] for yy ∈ Sets.Year if (Sets.Year[k]-yy < Params.OperationalLifeStorage[r,s,yy] && Sets.Year[k]-yy >= 0)) == model[:AccumulatedNewStorageCapacity][s,Sets.Year[k],r],
#        base_name="SI3_TotalNewStorage_$(s)_$(Sets.Year[k])_$(r)")
#        @constraint(model,
#        Params.CapitalCostStorage[r,s,Sets.Year[k]] * model[:NewStorageCapacity][s,Sets.Year[k],r] == model[:CapitalInvestmentStorage][s,Sets.Year[k],r],
#        base_name="SI4_UndiscountedCapitalInvestmentStorage_$(s)_$(Sets.Year[k])_$(r)")
#        @constraint(model,
#        model[:CapitalInvestmentStorage][s,Sets.Year[k],r]/((1+Settings.GeneralDiscountRate[r])^(Sets.Year[k]-Switch.StartYear+0.5)) == model[:DiscountedCapitalInvestmentStorage][s,Sets.Year[k],r],
#        base_name="SI5_DiscountingCapitalInvestmentStorage_$(s)_$(Sets.Year[k])_$(r)")
#        if (Sets.Year[k]+Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1) <= Sets.Year[end]
#          @constraint(model,
#          0 == model[:SalvageValueStorage][s,Sets.Year[k],r],
#          base_name="SI6_SalvageValueStorageAtEndOfPeriod1_$(s)_$(Sets.Year[k])_$(r)")
#        end
#        if  (Settings.DepreciationMethod[r]==1 && (Sets.Year[k]+Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]==0) || (Settings.DepreciationMethod[r]==2 && (Sets.Year[k]+Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]==0)
#          @constraint(model,
#          model[:CapitalInvestmentStorage][s,Sets.Year[k],r]*(1- Sets.Year[end]  - Sets.Year[k]+1)/Params.OperationalLifeStorage[r,s,Sets.Year[k]] == model[:SalvageValueStorage][s,Sets.Year[k],r],
#          base_name="SI7_SalvageValueStorageAtEndOfPeriod2_$(s)_$(Sets.Year[k])_$(r)")
#        end
#        if Settings.DepreciationMethod[r]==1 && ((Sets.Year[k]+Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1) > Sets.Year[end] && Settings.GeneralDiscountRate[r]>0)
#          @constraint(model,
#          model[:CapitalInvestmentStorage][s,Sets.Year[k],r]*(1-(((1+Settings.GeneralDiscountRate[r])^(Sets.Year[end] - Sets.Year[k]+1)-1)/((1+Settings.GeneralDiscountRate[r])^Params.OperationalLifeStorage[r,s,Sets.Year[k]]-1))) == model[:SalvageValueStorage][s,Sets.Year[k],r],
#          base_name="SI8_SalvageValueStorageAtEndOfPeriod3_$(s)_$(Sets.Year[k])_$(r)")
#        end
#        @constraint(model,
#        model[:SalvageValueStorage][s,Sets.Year[k],r]/((1+Settings.GeneralDiscountRate[r])^(1+max(Sets.Year...) - Switch.StartYear)) == model[:DiscountedSalvageValueStorage][s,Sets.Year[k],r],
#        base_name="SI9_SalvageValueStorageDiscountedToStartYear_$(s)_$(Sets.Year[k])_$(r)")
#        @constraint(model,
#        model[:DiscountedCapitalInvestmentStorage][s,Sets.Year[k],r]-model[:DiscountedSalvageValueStorage][s,Sets.Year[k],r] == model[:TotalDiscountedStorageCost][s,Sets.Year[k],r],
#        base_name="SI10_TotalDiscountedCostByStorage_$(s)_$(Sets.Year[k])_$(r)")
 
#        ######### Storage Equations #############
#        if k==1
#          JuMP.fix(model[:StorageLevelYearStart][s, Sets.Year[k], r], Params.StorageLevelStart[r,s]; force=true)
#        end
#        if k>1
#          @constraint(model,
#          model[:StorageLevelYearStart][s,Sets.Year[k-1],r] + sum(model[:NetChargeWithinYear][s,Sets.Year[k-1],ls,ld,lh,r] for ls ∈ Sets.Season for ld ∈ Sets.Daytype for lh ∈ Sets.DailyTimeBracket) == model[:StorageLevelYearStart][s,Sets.Year[k],r],
#          base_name="S5_StorageLeveYearStart_$(s)_$(Sets.Year[k])_$(r)")
#        end
#        if k<=length(Sets.Year)-1
#          @constraint(model,
#          model[:StorageLevelYearStart][s,Sets.Year[k+1],r] ==  model[:StorageLevelYearFinish][s,Sets.Year[k],r],
#          base_name="S7_StorageLevelYearFinish_$(s)_$(Sets.Year[k])_$(r)")
#        end
#        if k==length(Sets.Year)
#          @constraint(model,
#          model[:StorageLevelYearStart][s,Sets.Year[k],r] + sum(model[:NetChargeWithinYear][s,Sets.Year[k],ls,ld,lh,r] for ls ∈ Sets.Season for ld ∈ Sets.Daytype for lh ∈ Sets.DailyTimeBracket) == model[:StorageLevelYearFinish][s,Sets.Year[k],r],
#          base_name="S8_StorageLevelYearFinish_$(s)_$(Sets.Year[k])_$(r)")
#        end
 
#        for j ∈ 1:length(Sets.Season)
#          for i ∈ 1:length(Sets.Daytype)
#            for lh ∈ Sets.DailyTimeBracket
 
#              @constraint(model,
#              0 <= (model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r]+sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh > 0)))-model[:StorageLowerLimit][s,Sets.Year[k],r],
#              base_name="SC1_LowerLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              (model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r]+sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh > 0)))-model[:StorageUpperLimit][s,Sets.Year[k],r] <= 0,
#              base_name="SC1_UpperLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              0 <= (i>1 ? model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r]-sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],lhlh,r]  for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh < 0)) : 0) - model[:StorageLowerLimit][s,Sets.Year[k],r],
#              base_name="SC2_LowerLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              (i>1 ? model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r]-sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh < 0)) : 0) - model[:StorageUpperLimit][s,Sets.Year[k],r] <= 0,
#              base_name="SC2_UpperLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              0 <= (model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r] - sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh < 0)))-model[:StorageLowerLimit][s,Sets.Year[k],r],
#              base_name="SC3_LowerLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              (model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r] - sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh < 0)))-model[:StorageUpperLimit][s,Sets.Year[k],r] <= 0,
#              base_name="SC3_UpperLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              0 <= (i>1 ? model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],r]+sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh > 0)) : 0) - model[:StorageLowerLimit][s,Sets.Year[k],r],
#              base_name="SC4_LowerLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              (i>1 ? model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],r]+sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lhlh,r] for lhlh ∈ Sets.DailyTimeBracket if (lh-lhlh > 0)) : 0) - model[:StorageUpperLimit][s,Sets.Year[k],r] <= 0,
#              base_name="SC4_UpperLimit_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              model[:RateOfStorageCharge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r] <= Params.StorageMaxChargeRate[r,s]*model[:StorageUpperLimit][s,Sets.Year[k],r],
#              base_name="SC5_MaxChargeConstraint_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              model[:RateOfStorageDischarge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r] <= Params.StorageMaxDischargeRate[r,s]*model[:StorageUpperLimit][s,Sets.Year[k],r],
#              base_name="SC6_MaxDischargeConstraint_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
 
#              @constraint(model,
#              sum(model[:RateOfActivity][Sets.Year[k],l,t,m,r] * Params.TechnologyToStorage[Sets.Year[k],m,t,s] * Params.Conversionls[l,Sets.Season[j]] * Params.Conversionld[l,Sets.Daytype[i]] * Params.Conversionlh[l,lh] for t ∈ Subsets.StorageDummies for m ∈ Sets.Mode_of_operation for l ∈ Sets.Timeslice if Params.TechnologyToStorage[Sets.Year[k],m,t,s]>0) == model[:RateOfStorageCharge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r],
#              base_name="S1_RateOfStorageCharge_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              sum(model[:RateOfActivity][Sets.Year[k],l,t,m,r] * Params.TechnologyFromStorage[Sets.Year[k],m,t,s] * Params.Conversionls[l,Sets.Season[j]] * Params.Conversionld[l,Sets.Daytype[i]] * Params.Conversionlh[l,lh] for t ∈ Subsets.StorageDummies for m ∈ Sets.Mode_of_operation for l ∈ Sets.Timeslice if Params.TechnologyFromStorage[Sets.Year[k],m,t,s]>0) == model[:RateOfStorageDischarge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r],
#              base_name="S2_RateOfStorageDischarge_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              sum((model[:RateOfStorageCharge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r] - model[:RateOfStorageDischarge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r]) * Params.YearSplit[l,Sets.Year[k]] * Params.Conversionls[l,Sets.Season[j]] * Params.Conversionld[l,Sets.Daytype[i]] * Params.Conversionlh[l,lh] for l ∈ Sets.Timeslice if (Params.Conversionls[l,Sets.Season[j]]>0 && Params.Conversionld[l,Sets.Daytype[i]]>0 && Params.Conversionlh[l,lh]>0) ) == model[:NetChargeWithinYear][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r],
#              base_name="S3_NetChargeWithinYear_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#              @constraint(model,
#              (model[:RateOfStorageCharge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r] - model[:RateOfStorageDischarge][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r]) * sum(Params.DaySplit[Sets.Year[k],l] * Params.Conversionls[l,Sets.Season[j]] * Params.Conversionld[l,Sets.Daytype[i]] * Params.Conversionlh[l,lh] for l ∈ Sets.Timeslice) == model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],lh,r],
#              base_name="S4_NetChargeWithinDay_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(lh)_$(r)")
#            end
#            if i==1
#              @constraint(model,
#              model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j],r] ==  model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
#              base_name="S11_StorageLevelDayTypeStart_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
#            elseif i>1
#              @constraint(model,
#              model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],r] + sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1],lh,r] * Params.DaysInDayType[Sets.Year[k],Sets.Season[j],Sets.Daytype[i-1]] for lh ∈ Sets.DailyTimeBracket)  ==  model[:StorageLevelDayTypeStart][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
#              base_name="S12_StorageLevelDayTypeStart_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
#            end
#            if j==length(Sets.Season) && i == length(Sets.Daytype)
#              @constraint(model,
#              model[:StorageLevelYearFinish][s,Sets.Year[k],r] == model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
#              base_name="S13_StorageLevelDayTypeFinish_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
#            end
#            if j <= length(Sets.Season)-1 && i == length(Sets.Daytype)
#              @constraint(model,
#              model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j+1],r] == model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
#              base_name="S14_StorageLevelDayTypeFinish_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
#            end
#            if j <= length(Sets.Season)-1 && i <= length(Sets.Daytype)-1
#              @constraint(model,
#              model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i+1],r] - sum(model[:NetChargeWithinDay][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i+1],lh,r]  * Params.DaysInDayType[Sets.Year[k],Sets.Season[j],Sets.Daytype[i+1]] for lh ∈ Sets.DailyTimeBracket) == model[:StorageLevelDayTypeFinish][s,Sets.Year[k],Sets.Season[j],Sets.Daytype[i],r],
#              base_name="S15_StorageLevelDayTypeFinish_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(Sets.Daytype[i])_$(r)")
#            end
#          end
#          if j == 1
#            @constraint(model,
#            model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j],r] == model[:StorageLevelYearStart][s,Sets.Year[k],r],
#            base_name="S9_StorageLevelSeasonStart_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(r)")
#          else
#            @constraint(model,
#            model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j],r] == model[:StorageLevelSeasonStart][s,Sets.Year[k],Sets.Season[j-1],r] + sum(model[:NetChargeWithinYear][s,Sets.Year[k],Sets.Season[j-1],ld,lh,r] for ld ∈ Sets.Daytype for lh ∈ Sets.DailyTimeBracket) ,
#            base_name="S10_StorageLevelSeasonStart_$(s)_$(Sets.Year[k])_$(Sets.Season[j])_$(r)")
#          end
#        end
#      end end end
     
#      print("Cstr: Storage 4 : ",Dates.now()-start,"\n")
#    end
 
   
#     ######### Transportation Equations #############
#     start=Dates.now()
#    for r ∈ Sets.Region_full for y ∈ Sets.Year
#      for f ∈ Subsets.TransportFuels
#        if Params.SpecifiedAnnualDemand[r,f,y] != 0
#          for l ∈ Sets.Timeslice for mt ∈ Sets.ModalType  
#            @constraint(model,
#            Params.SpecifiedAnnualDemand[r,f,y]*Params.ModalSplitByFuelAndModalType[r,f,y,mt]*Params.SpecifiedDemandProfile[r,f,l,y] == model[:DemandSplitByModalType][mt,l,r,f,y],
#            base_name="T1a_SpecifiedAnnualDemandByModalSplit_$(mt)_$(l)_$(r)_$(f)_$(y)")
#          end end
#        end
     
#        for mt ∈ Sets.ModalType
#          if sum(Params.TagTechnologyToModalType[:,:,mt]) != 0
#            for l ∈ Sets.Timeslice
#              @constraint(model,
#              sum(Params.TagTechnologyToModalType[t,m,mt]*model[:RateOfActivity][y,l,t,m,r]*Params.OutputActivityRatio[r,t,f,m,y]*Params.YearSplit[l,y] for (t,m) ∈ LoopSetOutput[(r,f,y)]) == model[:ProductionSplitByModalType][mt,l,r,f,y],
#              base_name="T2_ProductionOfTechnologyByModalSplit_$(mt)_$(l)_$(r)_$(f)_$(y)")
#              @constraint(model,
#              model[:ProductionSplitByModalType][mt,l,r,f,y] >= model[:DemandSplitByModalType][mt,l,r,f,y],
#              base_name="T3_ModalSplitBalance_$(mt)_$(l)_$(r)_$(f)_$(y)")
#            end
#          end
#        end
#      end
 
#      for l ∈ Sets.Timeslice 
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_SHIP_RE",l,r,"Mobility_Passenger",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_ROAD_RE",l,r,"Mobility_Passenger",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_RAIL_RE",l,r,"Mobility_Passenger",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_SHIP_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_ROAD_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_FRT_RAIL_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_AIR_RE",l,r,"Mobility_Freight",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_ROAD_RE",l,r,"Mobility_Freight",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_RAIL_RE",l,r,"Mobility_Freight",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_AIR_CONV",l,r,"Mobility_Freight",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_ROAD_CONV",l,r,"Mobility_Freight",y], 0; force=true)
#        JuMP.fix(model[:ProductionSplitByModalType]["MT_PSNG_RAIL_CONV",l,r,"Mobility_Freight",y], 0; force=true)
#      end
#    end end
 
#    print("Cstr: transport: ",Dates.now()-start,"\n")
#    if Switch.switch_ramping == 1
   
#      ############### Ramping #############
#      start=Dates.now()
#      for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
#        for f ∈ Sets.Fuel
#          for i ∈ 1:length(Sets.Timeslice)
#            if i>1
#              if Params.TagDispatchableTechnology[t]==1 && (Params.RampingUpFactor[r,t,y] != 0 || Params.RampingDownFactor[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0)
#                @constraint(model,
#                ((sum(model[:RateOfActivity][y,Sets.Timeslice[i],t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,t,f,m,y] != 0)*Params.YearSplit[Sets.Timeslice[i],y]) - (sum(model[:RateOfActivity][y,Sets.Timeslice[i-1],t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,t,f,m,y] != 0)*Params.YearSplit[Sets.Timeslice[i-1],y]))
#                == model[:ProductionUpChangeInTimeslice][y,Sets.Timeslice[i],f,t,r] - model[:ProductionDownChangeInTimeslice][y,Sets.Timeslice[i],f,t,r],
#                base_name="R1_ProductionChange_$(y)_$(Sets.Timeslice[i])_$(f)_$(t)_$(r)")
#              end
#              if Params.TagDispatchableTechnology[t]==1 && Params.RampingUpFactor[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
#                @constraint(model,
#                model[:ProductionUpChangeInTimeslice][y,Sets.Timeslice[i],f,t,r] <= model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t]*Params.RampingUpFactor[r,t,y]*Params.YearSplit[Sets.Timeslice[i],y],
#                base_name="R2_RampingUpLimit_$(y)_$(Sets.Timeslice[i])_$(f)_$(t)_$(r)")
#              end
#              if Params.TagDispatchableTechnology[t]==1 && Params.RampingDownFactor[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
#                @constraint(model,
#                model[:ProductionDownChangeInTimeslice][y,Sets.Timeslice[i],f,t,r] <= model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t]*Params.RampingDownFactor[r,t,y]*Params.YearSplit[Sets.Timeslice[i],y],
#                base_name="R3_RampingDownLimit_$(y)_$(Sets.Timeslice[i])_$(f)_$(t)_$(r)")
#              end
#            end
#            ############### Min Runing Constraint #############
#            if Params.MinActiveProductionPerTimeslice[y,Sets.Timeslice[i],f,t,r] > 0
#              @constraint(model,
#              sum(model[:RateOfActivity][y,Sets.Timeslice[i],t,m,r]*Params.OutputActivityRatio[r,t,f,m,y] for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,t,f,m,y] != 0) >= 
#              model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t]*Params.MinActiveProductionPerTimeslice[y,Sets.Timeslice[i],f,t,r],
#              base_name="MRC1_MinRunningConstraint_$(y)_$(Sets.Timeslice[i])_$(f)_$(t)_$(r)")
#            end
#          end
 
#          ############### Ramping Costs #############
#          if Params.TagDispatchableTechnology[t]==1 && Params.ProductionChangeCost[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
#            @constraint(model,
#            sum((model[:ProductionUpChangeInTimeslice][y,l,f,t,r] + model[:ProductionDownChangeInTimeslice][y,l,f,t,r])*Params.ProductionChangeCost[r,t,y] for l ∈ Sets.Timeslice) == model[:AnnualProductionChangeCost][y,t,r],
#            base_name="RC1_AnnualProductionChangeCosts_$(y)_$(f)_$(t)_$(r)")
#          end
#          if Params.TagDispatchableTechnology[t]==1 && Params.ProductionChangeCost[r,t,y] != 0 && Params.AvailabilityFactor[r,t,y] > 0 && Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
#            @constraint(model,
#            model[:AnnualProductionChangeCost][y,t,r]/((1+Settings.TechnologyDiscountRate[r,t])^(y-Switch.StartYear+0.5)) == Discountedmodel[:AnnualProductionChangeCost][y,t,r],
#            base_name="RC2_DiscountedAnnualProductionChangeCost_$(y)_$(f)_$(t)_$(r)")
#          end
#        end
#        if (Params.TagDispatchableTechnology[t] == 0 || sum((m,f), Params.OutputActivityRatio[r,t,f,m,y]) == 0 || Params.ProductionChangeCost[r,t,y] == 0 || Params.AvailabilityFactor[r,t,y] == 0 || Params.TotalAnnualMaxCapacity[r,t,y] == 0 || Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] == 0)
#          JuMP.fix(model[:DiscountedAnnualProductionChangeCost][y,t,r], 0; force=true)
#          JuMP.fix(model[:AnnualProductionChangeCost][y,t,r], 0; force=true)
#        end
#      end end end
     
#    print("Cstr: Ramping : ",Dates.now()-start,"\n")
#    end
 
#     ############### Curtailment Costs #############
#    start=Dates.now()
#    for y ∈ Sets.Year for f ∈ Sets.Fuel for r ∈ Sets.Region_full
#      @constraint(model,
#      sum(model[:Curtailment][y,l,f,r]*Params.CurtailmentCostFactor[r,f,y] for l ∈ Sets.Timeslice ) == model[:AnnualCurtailmentCost][y,f,r],
#      base_name="CC1_AnnualCurtailmentCosts_$(y)_$(f)_$(r)")
#      @constraint(model,
#      model[:AnnualCurtailmentCost][y,f,r]/((1+Settings.GeneralDiscountRate[r])^(y-Switch.StartYear+0.5)) == model[:DiscountedAnnualCurtailmentCost][y,f,r],
#      base_name="CC2_DiscountedAnnualCurtailmentCosts_$(y)_$(f)_$(r)")
#    end end end
 
#    print("Cstr: Curtailment : ",Dates.now()-start,"\n")
 
#    if Switch.switch_base_year_bounds == 1
   
#     ############### General BaseYear Limits && trajectories #############
#     start=Dates.now()
#      for y ∈ Sets.Year for t ∈ Sets.Technology for r ∈ Sets.Region_full
#        for f ∈ Sets.Fuel
#          if Params.RegionalBaseYearProduction[r,t,f,y] != 0
#            @constraint(model,
#            model[:ProductionByTechnologyAnnual][y,t,f,r] >= Params.RegionalBaseYearProduction[r,t,f,y]*(1-model[:BaseYearSlack][f]) - model[:RegionalBaseYearProduction_neg][y,r,t,f],
#            base_name="B4a_RegionalBaseYearProductionLowerBound_$(y)_$(r)_$(t)_$(f)")
#          end
#        end
#        if Params.RegionalBaseYearProduction[r,t,"Power",y] != 0
#          @constraint(model,
#          model[:ProductionByTechnologyAnnual][y,t,"Power",r] <= Params.RegionalBaseYearProduction[r,t,"Power",y]+model[:BaseYearOvershoot][r,t,"Power",y],
#          base_name="B4b_RegionalBaseYearProductionUpperBound_$(y)_$(r)_$(t)_Power")
#        end
#      end end end
#      print("Cstr: Baseyear : ",Dates.now()-start,"\n")
#    end
   
#     ######### Peaking Equations #############
#     start=Dates.now()
#    if Switch.switch_peaking_capacity == 1
#      @variable(model, PeakingDemand[Sets.Year,Sets.Region_full])
#      @variable(model, PeakingCapacity[Sets.Year,Sets.Region_full])
#      GWh_to_PJ = 0.0036
#      PeakingSlack = Switch.set_peaking_slack
#      MinRunShare = Switch.set_peaking_minrun_share
#      RenewableCapacityFactorReduction = Switch.set_peaking_res_cf
#      for y ∈ Sets.Year for r ∈ Sets.Region_full
#        @constraint(model,
#        model[:PeakingDemand][y,r] ==
#          sum(model[:UseByTechnologyAnnual][y,t,"Power",r]/GWh_to_PJ*Params.x_peakingDemand[r,se]/8760
#            #Demand per Year in PJ             to Gwh     Highest peak hour value   /number hours per year
#          for se ∈ Sets.Sector for t ∈ setdiff(Sets.Technology,Subsets.StorageDummies) if Params.x_peakingDemand[r,se] != 0 && Params.TagTechnologyToSector[t,se] != 0)
#        + Params.SpecifiedAnnualDemand[r,"Power",y]/GWh_to_PJ*Params.x_peakingDemand[r,"Power"]/8760,
#        base_name="PC1_PowerPeakingDemand_$(y)_$(r)")
 
#        @constraint(model,
#        model[:PeakingCapacity][y,r] ==
#          sum((sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice ) < length(Sets.Timeslice) ? model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y]*RenewableCapacityFactorReduction*(sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice)/length(Sets.Timeslice)) : 0)
#          + (sum(Params.CapacityFactor[r,t,l,y] for l ∈ Sets.Timeslice ) >= length(Sets.Timeslice) ? model[:TotalCapacityAnnual][y,t,r]*Params.AvailabilityFactor[r,t,y] : 0)
#          for t ∈ setdiff(Sets.Technology,Subsets.StorageDummies) if (sum(Params.OutputActivityRatio[r,t,"Power",m,y] for m ∈ Sets.Mode_of_operation) != 0)),
#          base_name="PC2_PowerPeakingCapacity_$(y)_$(r)")
 
#        if y >Switch.set_peaking_startyear
#          @constraint(model,
#          model[:PeakingCapacity][y,r] + (Switch.switch_peaking_with_trade == 1 ? sum(model[:TotalTradeCapacity][y,"Power",rr,r] for rr ∈ Sets.Region_full) : 0)
#          + (Switch.switch_peaking_with_storages == 1 ? sum(model[:TotalCapacityAnnual][y,t,r] for t ∈ setdiff(Sets.Technology,Subsets.StorageDummies) if (sum(Params.OutputActivityRatio[r,t,"Power",m,y] for m ∈ Sets.Mode_of_operation) != 0)) : 0)
#          >= model[:PeakingDemand][y,r]*PeakingSlack,
#          base_name="PC3_PeakingConstraint_$(y)_$(r)")
#        end
       
#        if Switch.switch_peaking_minrun == 1
#          for t ∈ Sets.Technology
#            if (Params.TagTechnologyToSector[t,"Power"]==1 && Params.AvailabilityFactor[r,t,y]<=1 && 
#              Params.TagDispatchableTechnology[t]==1 && Params.AvailabilityFactor[r,t,y] > 0 && 
#              Params.TotalAnnualMaxCapacity[r,t,y] > 0 && Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 && 
#              ((((JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])) && (JuMP.upper_bound(model[:TotalCapacityAnnual][y,t,r]) > 0)) ||
#              ((!JuMP.has_upper_bound(model[:TotalCapacityAnnual][y,t,r])) && (!JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r]))) ||
#              ((JuMP.is_fixed(model[:TotalCapacityAnnual][y,t,r])) && (JuMP.fix_value(model[:TotalCapacityAnnual][y,t,r]) > 0)))) && 
#              y > Switch.set_peaking_startyear)
#              @constraint(model,
#              sum(sum(model[:RateOfActivity][y,l,t,m,r] for m ∈ Sets.Mode_of_operation)*Params.YearSplit[l,y] for l ∈ Sets.Timeslice ) >= 
#              sum(model[:TotalCapacityAnnual][y,t,r]*Params.CapacityFactor[r,t,l,y]*Params.YearSplit[l,y]*Params.AvailabilityFactor[r,t,y]*Params.CapacityToActivityUnit[r,t] for l ∈ Sets.Timeslice )*MinRunShare,
#              base_name="PC4_MinRunConstraint_$(y)_$(t)_$(r)")
#            end
#          end
#        end
#      end end
#    end
#    print("Cstr: Peaking : ",Dates.now()-start,"\n")
 
 
#    if Switch.switch_endogenous_employment == 1
 
#     ############### Employment effects #############
   
#      @variable(model, TotalJobs[Sets.Region_full, Sets.Year])
 
#      genesysmod_employment(model,Params,Emp_Sets)
#      for r ∈ Sets.Region_full for y ∈ Sets.Year
#        @constraint(model,
#        sum(((model[:NewCapacity][y,t,r]*Emp_Params.EFactorManufacturing[t,y]*Emp_Params.RegionalAdjustmentFactor[Switch.model_region,y]*Emp_Params.LocalManufacturingFactor[Switch.model_region,y])
#        +(model[:NewCapacity][y,t,r]*Emp_Params.EFactorConstruction[t,y]*Emp_Params.RegionalAdjustmentFactor[Switch.model_region,y])
#        +(model[:TotalCapacityAnnual][y,t,r]*Emp_Params.EFactorOM[t,y]*Emp_Params.RegionalAdjustmentFactor[Switch.model_region,y])
#        +(model[:UseByTechnologyAnnual][y,t,f,r]*Emp_Params.EFactorFuelSupply[t,y]))*(1-Emp_Params.DeclineRate[t,y])^YearlyDifferenceMultiplier(y,Sets)
#        +((model[:UseByTechnologyAnnual][y,"HLI_Hardcoal","Hardcoal",r]+model[:UseByTechnologyAnnual][y,"HMI_HardCoal","Hardcoal",r]
#        +(model[:UseByTechnologyAnnual][y,"HHI_BF_BOF","Hardcoal",r])*Emp_Params.EFactorCoalJobs["Coal_Heat",y]*Emp_Params.CoalSupply[r,y]))
#        +(Emp_Params.CoalSupply[r,y]*Emp_Params.CoalDigging[Switch.model_region,"Coal_Export","$(Switch.emissionPathway)_$(Switch.emissionScenario)",y]*Emp_Params.EFactorCoalJobs["Coal_Export",y]) for t ∈ Sets.Technology for f ∈ Sets.Fuel)
#        == model[:TotalJobs][r,y],
#        base_name="Jobs1_TotalJobs_$(r)_$(y)")
#      end end
#    end