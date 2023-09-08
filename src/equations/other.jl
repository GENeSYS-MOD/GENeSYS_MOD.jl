
function preparation(gm)
    @variable(gm.model, RegionalBaseYearProduction_neg[gm.sets.Year,gm.sets.Region_full,gm.sets.Technology,gm.sets.Fuel])

    for y ∈ gm.sets.Year, r ∈ gm.sets.Region_full, t ∈ gm.sets.Technology, f ∈ gm.sets.Fuel
    JuMP.fix(gm.model[:RegionalBaseYearProduction_neg][y,r,t,f], 0;force=true)
    end 
    #########################
    # Parameter assignments #
    #########################


    for y ∈ gm.sets.Year, l ∈ gm.sets.Timeslice, f ∈ gm.sets.Fuel, r ∈ gm.sets.Region_full
    gm.params.RateOfDemand[y,l,f,r] = gm.params.SpecifiedAnnualDemand[r,f,y]*gm.params.SpecifiedDemandProfile[r,f,l,y] / gm.params.YearSplit[l,y]
    gm.params.Demand[y,l,f,r] = gm.params.RateOfDemand[y,l,f,r] * gm.params.YearSplit[l,y]
    if gm.params.Demand[y,l,f,r] < 0.000001
        gm.params.Demand[y,l,f,r] = 0
    end
    end


    gm.other_params[:LoopSetOutput] = LoopSetOutput = Dict(
    (r,f,y) => [(x[1],x[2]) for x in keys(gm.params.OutputActivityRatio[r,:,f,:,y]) if gm.params.OutputActivityRatio[r,x[1],f,x[2],y] > 0]
    for y ∈ gm.sets.Year for f ∈ gm.sets.Fuel for r ∈ gm.sets.Region_full
    )

    gm.other_params[:LoopSetInput] = LoopSetInput = Dict(
    (r,f,y) => [(x[1],x[2]) for x in keys(gm.params.InputActivityRatio[r,:,f,:,y]) if gm.params.InputActivityRatio[r,x[1],f,x[2],y] > 0]
    for y ∈ gm.sets.Year for f ∈ gm.sets.Fuel for r ∈ gm.sets.Region_full
    )

    
    gm.other_params[:CanFuelBeUsedOrDemanded] = CanFuelBeUsedOrDemanded = JuMP.Containers.DenseAxisArray(zeros(length(gm.sets.Year), length(gm.sets.Fuel), length(gm.sets.Region_full)), gm.sets.Year, gm.sets.Fuel, gm.sets.Region_full)
  for y ∈ gm.sets.Year, f ∈ gm.sets.Fuel, r ∈ gm.sets.Region_full
    temp = (isempty(LoopSetInput[(r,f,y)]) ? 0 : sum(gm.params.InputActivityRatio[r,t,f,m,y]*
    gm.params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(gm.params.CapacityFactor[r,t,l,y] for l ∈ gm.sets.Timeslice) *
    gm.params.AvailabilityFactor[r,t,y] * 
    gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    gm.params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for (t,m) ∈ LoopSetInput[(r,f,y)]))
    if (!ismissing(temp)) && (temp > 0) || gm.params.SpecifiedAnnualDemand[r,f,y] > 0
      CanFuelBeUsedOrDemanded[y,f,r] = 1
    end
  end


  
  gm.other_params[:CanFuelBeProduced] = CanFuelBeProduced = JuMP.Containers.DenseAxisArray(zeros(length(gm.sets.Year), length(gm.sets.Fuel), length(gm.sets.Region_full)), gm.sets.Year, gm.sets.Fuel, gm.sets.Region_full)
  for y ∈ gm.sets.Year, f ∈ gm.sets.Fuel, r ∈ gm.sets.Region_full
    temp = (isempty(LoopSetOutput[(r,f,y)]) ? 0 : sum(gm.params.OutputActivityRatio[r,t,f,m,y]*
    gm.params.TotalAnnualMaxCapacity[r,t,y] * 
    sum(gm.params.CapacityFactor[r,t,l,y] for l ∈ gm.sets.Timeslice) *
    gm.params.AvailabilityFactor[r,t,y] * 
    gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    gm.params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] for (t,m) ∈ LoopSetOutput[(r,f,y)]))
    if (temp > 0)
      CanFuelBeProduced[y,f,r] = 1
    end
  end

  gm.other_params[:IgnoreFuel] = IgnoreFuel = JuMP.Containers.DenseAxisArray(zeros(length(gm.sets.Year), length(gm.sets.Fuel), length(gm.sets.Region_full)), gm.sets.Year, gm.sets.Fuel, gm.sets.Region_full)
  for y ∈ gm.sets.Year, f ∈ gm.sets.Fuel, r ∈ gm.sets.Region_full
    if CanFuelBeUsedOrDemanded[y,f,r] == 1 && CanFuelBeProduced[y,f,r] == 0
      IgnoreFuel[y,f,r] = 1
    end
  end


  gm.other_params[:CanBuildTechnology] = CanBuildTechnology = JuMP.Containers.DenseAxisArray(zeros(length(gm.sets.Year), length(gm.sets.Technology), length(gm.sets.Region_full)), gm.sets.Year, gm.sets.Technology, gm.sets.Region_full)
  for y ∈ gm.sets.Year, t ∈ gm.sets.Technology, r ∈ gm.sets.Region_full
    temp=  (gm.params.TotalAnnualMaxCapacity[r,t,y] *
    sum(gm.params.CapacityFactor[r,t,l,y] for l ∈ gm.sets.Timeslice) *
    gm.params.AvailabilityFactor[r,t,y] * 
    gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] * 
    gm.params.TotalTechnologyAnnualActivityUpperLimit[r,t,y])
    if (temp > 0) && ((!JuMP.is_fixed(gm.model[:TotalCapacityAnnual][y,t,r]) && !JuMP.has_upper_bound(gm.model[:TotalCapacityAnnual][y,t,r])) || (JuMP.is_fixed(gm.model[:TotalCapacityAnnual][y,t,r]) && (JuMP.fix_value(gm.model[:TotalCapacityAnnual][y,t,r]) > 0)) || (JuMP.has_upper_bound(gm.model[:TotalCapacityAnnual][y,t,r]) && (JuMP.upper_bound(gm.model[:TotalCapacityAnnual][y,t,r]) > 0)))
      CanBuildTechnology[y,t,r] = 1
    end
  end
end

function remaining_equa(gm)
    
  @timeit to "Cstr: Em. Acc. 1" begin
    for y ∈ gm.sets.Year for t ∈ gm.sets.Technology for r ∈ gm.sets.Region_full
      if gm.other_params[:CanBuildTechnology][y,t,r] > 0
        for e ∈ gm.sets.Emission for m ∈ gm.sets.Mode_of_operation
          @constraint(gm.model, gm.params.EmissionActivityRatio[r,t,e,m,y]*sum((gm.model[:TotalAnnualTechnologyActivityByMode][y,t,m,r]*gm.params.EmissionContentPerFuel[f,e]*gm.params.InputActivityRatio[r,t,f,m,y]) for f ∈ gm.sets.Fuel) == gm.model[:AnnualTechnologyEmissionByMode][y,t,e,m,r] , base_name="E1_AnnualEmissionProductionByMode_$(y)_$(t)_$(e)_$(m)_$(r)" )
        end end
      else
        for m ∈ gm.sets.Mode_of_operation for e ∈ gm.sets.Emission
          JuMP.fix(gm.model[:AnnualTechnologyEmissionByMode][y,t,e,m,r],0; force=true)
        end end
      end
    end end end
    end
  
    @timeit to "Cstr: Em. Acc. 2" begin
    for y ∈ gm.sets.Year for r ∈ gm.sets.Region_full
      for t ∈ gm.sets.Technology
        for e ∈ gm.sets.Emission
          @constraint(gm.model, sum(gm.model[:AnnualTechnologyEmissionByMode][y,t,e,m,r] for m ∈ gm.sets.Mode_of_operation) == gm.model[:AnnualTechnologyEmission][y,t,e,r],
          base_name="E2_AnnualEmissionProduction_$(y)_$(t)_$(e)_$(r)")
  
          @constraint(gm.model, (gm.model[:AnnualTechnologyEmission][y,t,e,r]*gm.params.EmissionsPenalty[r,e,y]*gm.params.EmissionsPenaltyTagTechnology[r,t,e,y])*YearlyDifferenceMultiplier(y,gm.sets) == gm.model[:AnnualTechnologyEmissionPenaltyByEmission][y,t,e,r],
          base_name="E3_EmissionsPenaltyByTechAndEmission_$(y)_$(t)_$(e)_$(r)")
        end
  
        @constraint(gm.model, sum(gm.model[:AnnualTechnologyEmissionPenaltyByEmission][y,t,e,r] for e ∈ gm.sets.Emission) == gm.model[:AnnualTechnologyEmissionsPenalty][y,t,r],
        base_name="E4_EmissionsPenaltyByTechnology_$(y)_$(t)_$(r)")
  
        @constraint(gm.model, gm.model[:AnnualTechnologyEmissionsPenalty][y,t,r]/((1+gm.settings.SocialDiscountRate[r])^(y-gm.switch.StartYear+0.5)) == gm.model[:DiscountedTechnologyEmissionsPenalty][y,t,r],
        base_name="E5_DiscountedEmissionsPenaltyByTechnology_$(y)_$(t)_$(r)")
      end
    end end 
  
    for e ∈ gm.sets.Emission
      for y ∈ gm.sets.Year
        for r ∈ gm.sets.Region_full
          @constraint(gm.model, sum(gm.model[:AnnualTechnologyEmission][y,t,e,r] for t ∈ gm.sets.Technology) == gm.model[:AnnualEmissions][y,e,r], 
          base_name="E6_EmissionsAccounting1_$(y)_$(e)_$(r)")
  
          @constraint(gm.model, gm.model[:AnnualEmissions][y,e,r]+gm.params.AnnualExogenousEmission[r,e,y] <= gm.params.RegionalAnnualEmissionLimit[r,e,y], 
          base_name="E8_RegionalAnnualEmissionsLimit_$(y)_$(e)_$(r)")
        end
        @constraint(gm.model, sum(gm.model[:AnnualEmissions][y,e,r]+gm.params.AnnualExogenousEmission[r,e,y] for r ∈ gm.sets.Region_full) <= gm.params.AnnualEmissionLimit[e,y],
        base_name="E9_AnnualEmissionsLimit_$(y)_$(e)")
      end
      @constraint(gm.model, sum(gm.model[:ModelPeriodEmissions][e,r] for r ∈ gm.sets.Region_full) <= gm.params.ModelPeriodEmissionLimit[e],
      base_name="E10_ModelPeriodEmissionsLimit_$(e)")
    end
    end
  
    @timeit to "Cstr: Em. Acc. 3" begin
    for e ∈ gm.sets.Emission for r ∈ gm.sets.Region_full
      if gm.params.RegionalModelPeriodEmissionLimit[e,r] < 999999
        @constraint(gm.model, gm.model[:ModelPeriodEmissions][e,r] <= gm.params.RegionalModelPeriodEmissionLimit[e,r] ,base_name="E11_RegionalModelPeriodEmissionsLimit" )
      end
    end end
    end
  
    @timeit to "Cstr: Em. Acc. 4" begin
    if gm.switch.switch_weighted_emissions == 1
      for e ∈ gm.sets.Emission for r ∈ gm.sets.Region_full
        @constraint(gm.model,
        sum(gm.model[:WeightedAnnualEmissions][gm.sets.Year[i],e,r]*(gm.sets.Year[i+1]-gm.sets.Year[i]) for i ∈ 1:length(gm.sets.Year)-1 if gm.sets.Year[i+1]-gm.sets.Year[i] > 0) +  gm.model[:WeightedAnnualEmissions][gm.sets.Year[end],e,r] == gm.model[:ModelPeriodEmissions][e,r]- gm.params.ModelPeriodExogenousEmission[r,e],
        base_name="E7_EmissionsAccounting2_$(e)_$(r)")
  
        @constraint(gm.model,
        gm.model[:AnnualEmissions][gm.sets.Year[end],e,r] == gm.model[:WeightedAnnualEmissions][gm.sets.Year[end],e,r],
        base_name="E12b_WeightedLastYearEmissions_$(gm.sets.Year[end])_$(e)_$(r)")
        for i ∈ 1:length(gm.sets.Year)-1
          @constraint(gm.model,
          (gm.model[:AnnualEmissions][gm.sets.Year[i],e,r]+gm.model[:AnnualEmissions][gm.sets.Year[i+1],e,r])/2 == gm.model[:WeightedAnnualEmissions][gm.sets.Year[i],e,r],
          base_name="E12a_WeightedEmissions_$(gm.sets.Year[i])_$(e)_$(r)")
        end
      end end
    else
      for e ∈ gm.sets.Emission for r ∈ gm.sets.Region_full
        @constraint(gm.model, sum( gm.model[:AnnualEmissions][gm.sets.Year[ind],e,r]*(gm.sets.Year[ind+1]-gm.sets.Year[ind]) for ind ∈ 1:(length(gm.sets.Year)-1) if gm.sets.Year[ind+1]-gm.sets.Year[ind]>0)
        +  gm.model[:AnnualEmissions][gm.sets.Year[end],e,r] == gm.model[:ModelPeriodEmissions][e,r]- gm.params.ModelPeriodExogenousEmission[r,e],
        base_name="E7_EmissionsAccounting2_$(e)_$(r)")
      end end
    end
    end
     
     ################ Sectoral Emissions Accounting ##############
     start=Dates.now()
  
     for y ∈ gm.sets.Year for e ∈ gm.sets.Emission for se ∈ gm.sets.Sector
       for r ∈ gm.sets.Region_full
         @constraint(gm.model,
         sum(gm.model[:AnnualTechnologyEmission][y,t,e,r] for t ∈ gm.sets.Technology if gm.params.TagTechnologyToSector[t,se] != 0) == gm.model[:AnnualSectoralEmissions][y,e,se,r],
         base_name="ES1_AnnualSectorEmissions_$(y)_$(e)_$(se)_$(r)")
       end
   
       @constraint(gm.model,
       sum(gm.model[:AnnualSectoralEmissions][y,e,se,r] for r ∈ gm.sets.Region_full ) <= gm.params.AnnualSectoralEmissionLimit[e,se,y],
       base_name="ES2_AnnualSectorEmissionsLimit_$(y)_$(e)_$(se)")
     end end end
   
     print("Cstr: ES: ",Dates.now()-start,"\n")
      ######### Short-Term Storage Constraints #############
      start=Dates.now()
   
     if gm.switch.switch_short_term_storage == 1 #new storage formulation
       for r ∈ gm.sets.Region_full for s ∈ gm.sets.Storage for i ∈ 1:length(gm.sets.Year)
         if i == 1
           JuMP.fix(gm.model[:StorageLevelYearStart][s, gm.sets.Year[i], r], gm.params.StorageLevelStart[r,s];force=true)
         else
           @constraint(gm.model, 
           gm.model[:StorageLevelYearStart][s,gm.sets.Year[i-1],r] + sum((sum(gm.model[:RateOfActivity][gm.sets.Year[i],l,t,m,r] * gm.params.TechnologyToStorage[gm.sets.Year[i],m,t,s] for m ∈ gm.sets.Mode_of_operation for t ∈ gm.subsets.StorageDummies if gm.params.TechnologyToStorage[gm.sets.Year[i],m,t,s]>0)
               - sum( gm.model[:RateOfActivity][gm.sets.Year[i],l,t,m,r] / gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s] for m ∈ gm.sets.Mode_of_operation for t ∈ gm.subsets.StorageDummies if gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s]>0)) * gm.params.YearSplit[l,gm.sets.Year[i]] for l ∈ gm.sets.Timeslice)
           == gm.model[:StorageLevelYearStart][s,gm.sets.Year[i],r],
           base_name="S1_StorageLevelYearStart_$(r)_$(s)_$(gm.sets.Year[i])")
           
           JuMP.fix(gm.model[:StorageLevelYearStart][s, gm.sets.Year[i], r], 0;force=true)
         end
         
         @constraint(gm.model,
         sum((sum(gm.model[:RateOfActivity][gm.sets.Year[i],l,t,m,r] * gm.params.TechnologyToStorage[gm.sets.Year[i],m,t,s] for m ∈ gm.sets.Mode_of_operation for t ∈ gm.subsets.StorageDummies if gm.params.TechnologyToStorage[gm.sets.Year[i],m,t,s]>0)
                   - sum(gm.model[:RateOfActivity][gm.sets.Year[i],l,t,m,r] / gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s] for m ∈ gm.sets.Mode_of_operation for t ∈ gm.subsets.StorageDummies if gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s]>0)) for l ∈ gm.sets.Timeslice) == 0,
                   base_name="S3_StorageRefilling_$(r)_$(s)_$(gm.sets.Year[i])")
   
         for j ∈ 1:length(gm.sets.Timeslice)
   #=         @constraint(gm.model,
           (j>1 ? gm.model[:StorageLevelTSStart][s,gm.sets.Year[i],gm.sets.Timeslice[j-1],r] +
               (sum(gm.model[:RateOfActivity][gm.sets.Year[i],gm.sets.Timeslice[j-1],t,m,r] * gm.params.TechnologyToStorage[gm.sets.Year[i],m,t,s] for m ∈ gm.sets.Mode_of_operation for t ∈ gm.sets.Technology if gm.params.TechnologyToStorage[gm.sets.Year[i],m,t,s]>0)
             - sum(gm.model[:RateOfActivity][gm.sets.Year[i],gm.sets.Timeslice[j-1],t,m,r] / gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s] for m ∈ gm.sets.Mode_of_operation for t ∈ gm.sets.Technology if gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s]>0) * gm.params.YearSplit[gm.sets.Timeslice[j-1],gm.sets.Year[i]]) : 0)
             + (j == 1 ? gm.model[:StorageLevelYearStart][s,gm.sets.Year[i],r] : 0)   == gm.model[:StorageLevelTSStart][s,gm.sets.Year[i],gm.sets.Timeslice[j],r],
             base_name="S2_StorageLevelTSStart_$(r)_$(s)_$(gm.sets.Year[i])_$(gm.sets.Timeslice[j])") =#
   
           @constraint(gm.model,
           (j>1 ? gm.model[:StorageLevelTSStart][s,gm.sets.Year[i],gm.sets.Timeslice[j-1],r] + 
           (sum((gm.params.TechnologyToStorage[gm.sets.Year[i],m,t,s]>0 ? gm.model[:RateOfActivity][gm.sets.Year[i],gm.sets.Timeslice[j-1],t,m,r] * gm.params.TechnologyToStorage[gm.sets.Year[i],m,t,s] : 0) for m ∈ gm.sets.Mode_of_operation for t ∈ gm.subsets.StorageDummies)
             - sum((gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s]>0 ? gm.model[:RateOfActivity][gm.sets.Year[i],gm.sets.Timeslice[j-1],t,m,r] / gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s] : 0 ) for m ∈ gm.sets.Mode_of_operation for t ∈ gm.subsets.StorageDummies)) * gm.params.YearSplit[gm.sets.Timeslice[j-1],gm.sets.Year[i]] : 0)
             + (j == 1 ? gm.model[:StorageLevelYearStart][s,gm.sets.Year[i],r] : 0)   == gm.model[:StorageLevelTSStart][s,gm.sets.Year[i],gm.sets.Timeslice[j],r],
             base_name="S2_StorageLevelTSStart_$(r)_$(s)_$(gm.sets.Year[i])_$(gm.sets.Timeslice[j])")
   
           @constraint(gm.model,
           sum(gm.model[:NewStorageCapacity][s,gm.sets.Year[i],r] + gm.params.ResidualStorageCapacity[r,s,gm.sets.Year[i]] for yy ∈ gm.sets.Year if (gm.sets.Year[i]-yy < gm.params.OperationalLifeStorage[r,s,yy] && gm.sets.Year[i]-yy >= 0))
           >= gm.model[:StorageLevelTSStart][s,gm.sets.Year[i],gm.sets.Timeslice[j],r],
           base_name="SC2_UpperLimit_$(s)_$(gm.sets.Year[i])_$(gm.sets.Timeslice[j])_$(r)")
   
         end
   
         @constraint(gm.model,
         gm.params.CapitalCostStorage[r,s,gm.sets.Year[i]] * gm.model[:NewStorageCapacity][s,gm.sets.Year[i],r] == gm.model[:CapitalInvestmentStorage][s,gm.sets.Year[i],r],
         base_name="SI4_UndiscountedCapitalInvestmentStorage_$(s)_$(gm.sets.Year[i])_$(r)")
         @constraint(gm.model,
         gm.model[:CapitalInvestmentStorage][s,gm.sets.Year[i],r]/((1+gm.settings.GeneralDiscountRate[r])^(gm.sets.Year[i]-gm.switch.StartYear+0.5)) == gm.model[:DiscountedCapitalInvestmentStorage][s,gm.sets.Year[i],r],
         base_name="SI5_DiscountingCapitalInvestmentStorage_$(s)_$(gm.sets.Year[i])_$(r)")
         if ((gm.sets.Year[i]+gm.params.OperationalLifeStorage[r,s,gm.sets.Year[i]]-1) <= gm.sets.Year[end] )
           @constraint(gm.model,
           gm.model[:SalvageValueStorage][s,gm.sets.Year[i],r] == 0,
           base_name="SI6_SalvageValueStorageAtEndOfPeriod1_$(s)_$(gm.sets.Year[i])_$(r)")
         end
         if ((gm.settings.DepreciationMethod[r]==1 && (gm.sets.Year[i]+gm.params.OperationalLifeStorage[r,s,gm.sets.Year[i]]-1) > gm.sets.Year[end] && gm.settings.GeneralDiscountRate[r]==0) || (gm.settings.DepreciationMethod[r]==2 && (gm.sets.Year[i]+gm.params.OperationalLifeStorage[r,s,gm.sets.Year[i]]-1) > gm.sets.Year[end] && gm.settings.GeneralDiscountRate[r]==0))
           @constraint(gm.model,
           gm.model[:CapitalInvestmentStorage][s,gm.sets.Year[i],r]*(1- gm.sets.Year[end] - gm.sets.Year[i]+1)/gm.params.OperationalLifeStorage[r,s,gm.sets.Year[i]] == gm.model[:SalvageValueStorage][s,gm.sets.Year[i],r],
           base_name="SI7_SalvageValueStorageAtEndOfPeriod2_$(s)_$(gm.sets.Year[i])_$(r)")
         end
         if (gm.settings.DepreciationMethod[r]==1 && ((gm.sets.Year[i]+gm.params.OperationalLifeStorage[r,s,gm.sets.Year[i]]-1) > gm.sets.Year[end] && gm.settings.GeneralDiscountRate[r]>0))
           @constraint(gm.model,
           gm.model[:CapitalInvestmentStorage][s,gm.sets.Year[i],r]*(1-((1+gm.settings.GeneralDiscountRate[r])^(gm.sets.Year[end] - gm.sets.Year[i]+1)-1)/((1+gm.settings.GeneralDiscountRate[r])^gm.params.OperationalLifeStorage[r,s,gm.sets.Year[i]]-1)) == gm.model[:SalvageValueStorage][s,gm.sets.Year[i],r],
           base_name="SI8_SalvageValueStorageAtEndOfPeriod3_$(s)_$(gm.sets.Year[i])_$(r)")
         end
         @constraint(gm.model,
         gm.model[:SalvageValueStorage][s,gm.sets.Year[i],r]/((1+gm.settings.GeneralDiscountRate[r])^(1+max(gm.sets.Year...) - gm.switch.StartYear)) == gm.model[:DiscountedSalvageValueStorage][s,gm.sets.Year[i],r],
         base_name="SI9_SalvageValueStorageDiscountedToStartYear_$(s)_$(gm.sets.Year[i])_$(r)")
         @constraint(gm.model,
         gm.model[:DiscountedCapitalInvestmentStorage][s,gm.sets.Year[i],r]-gm.model[:DiscountedSalvageValueStorage][s,gm.sets.Year[i],r] == gm.model[:TotalDiscountedStorageCost][s,gm.sets.Year[i],r],
         base_name="SI10_TotalDiscountedCostByStorage_$(s)_$(gm.sets.Year[i])_$(r)")
       end end end
   
       for s ∈ gm.sets.Storage for i ∈ 1:length(gm.sets.Year)
         for r ∈ gm.sets.Region_full 
           if gm.params.MinStorageCharge[r,s,gm.sets.Year[i]] > 0
             for j ∈ 1:length(gm.sets.Timeslice)
               @constraint(gm.model, 
               gm.params.MinStorageCharge[r,s,gm.sets.Year[i]]*sum(gm.model[:NewStorageCapacity][s,gm.sets.Year[i],r] + gm.params.ResidualStorageCapacity[r,s,gm.sets.Year[i]] for yy ∈ gm.sets.Year if (gm.sets.Year[i]-yy < gm.params.OperationalLifeStorage[r,s,yy] && gm.sets.Year[i]-yy >= 0))
               <= gm.model[:StorageLevelTSStart][s,gm.sets.Year[i],gm.sets.Timeslice[j],r],
               base_name="SC1_LowerLimit_$(s)_$(gm.sets.Year[i])_$(gm.sets.Timeslice[j])_$(r)")
             end
           end
         end
   
         for t ∈ gm.subsets.StorageDummies for m ∈ gm.sets.Mode_of_operation
           if gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s]>0
             for r ∈ gm.sets.Region_full for j ∈ 1:length(gm.sets.Timeslice)
               @constraint(gm.model,
               gm.model[:RateOfActivity][gm.sets.Year[i],gm.sets.Timeslice[j],t,m,r]/gm.params.TechnologyFromStorage[gm.sets.Year[i],m,t,s]*gm.params.YearSplit[gm.sets.Timeslice[j],gm.sets.Year[i]] <= gm.model[:StorageLevelTSStart][s,gm.sets.Year[i],gm.sets.Timeslice[j],r],
               base_name="SC9d_StorageActivityLimit_$(s)_$(t)_$(gm.sets.Year[i])_$(gm.sets.Timeslice[j])_$(r)_$(m)")
             end end
           end
         end end
       end end
       print("Cstr: Storage 1 : ",Dates.now()-start,"\n")
   
     else #Formaulation from Osemosys
   
       @variable(gm.model, NumberOfStorageUnits[gm.sets.Region_full,gm.sets.Year,gm.sets.Storage])
       
       ######### Storage Constraints #############
       start=Dates.now()
   
       for s ∈ gm.sets.Storage for k ∈ 1:length(gm.sets.Year) for r ∈ gm.sets.Region_full
   
         ######### Storage Investments #############
   
         @constraint(gm.model,
         gm.model[:AccumulatedNewStorageCapacity][s,gm.sets.Year[k],r]+gm.params.ResidualStorageCapacity[r,s,gm.sets.Year[k]] == gm.model[:StorageUpperLimit][s,gm.sets.Year[k],r],
         base_name="SI1_StorageUpperLimit_$(s)_$(gm.sets.Year[k])_$(r)")
         @constraint(gm.model,
         gm.params.MinStorageCharge[r,s,gm.sets.Year[k]]*gm.model[:StorageUpperLimit][s,gm.sets.Year[k],r] == gm.model[:StorageLowerLimit][s,gm.sets.Year[k],r],
         base_name="SI2_StorageLowerLimit_$(s)_$(gm.sets.Year[k])_$(r)")
         @constraint(gm.model,
         sum(gm.model[:NewStorageCapacity][s,yy,r] for yy ∈ gm.sets.Year if (gm.sets.Year[k]-yy < gm.params.OperationalLifeStorage[r,s,yy] && gm.sets.Year[k]-yy >= 0)) == gm.model[:AccumulatedNewStorageCapacity][s,gm.sets.Year[k],r],
         base_name="SI3_TotalNewStorage_$(s)_$(gm.sets.Year[k])_$(r)")
         @constraint(gm.model,
         gm.params.CapitalCostStorage[r,s,gm.sets.Year[k]] * gm.model[:NewStorageCapacity][s,gm.sets.Year[k],r] == gm.model[:CapitalInvestmentStorage][s,gm.sets.Year[k],r],
         base_name="SI4_UndiscountedCapitalInvestmentStorage_$(s)_$(gm.sets.Year[k])_$(r)")
         @constraint(gm.model,
         gm.model[:CapitalInvestmentStorage][s,gm.sets.Year[k],r]/((1+gm.settings.GeneralDiscountRate[r])^(gm.sets.Year[k]-gm.switch.StartYear+0.5)) == gm.model[:DiscountedCapitalInvestmentStorage][s,gm.sets.Year[k],r],
         base_name="SI5_DiscountingCapitalInvestmentStorage_$(s)_$(gm.sets.Year[k])_$(r)")
         if (gm.sets.Year[k]+gm.params.OperationalLifeStorage[r,s,gm.sets.Year[k]]-1) <= gm.sets.Year[end]
           @constraint(gm.model,
           0 == gm.model[:SalvageValueStorage][s,gm.sets.Year[k],r],
           base_name="SI6_SalvageValueStorageAtEndOfPeriod1_$(s)_$(gm.sets.Year[k])_$(r)")
         end
         if  (gm.settings.DepreciationMethod[r]==1 && (gm.sets.Year[k]+gm.params.OperationalLifeStorage[r,s,gm.sets.Year[k]]-1) > gm.sets.Year[end] && gm.settings.GeneralDiscountRate[r]==0) || (gm.settings.DepreciationMethod[r]==2 && (gm.sets.Year[k]+gm.params.OperationalLifeStorage[r,s,gm.sets.Year[k]]-1) > gm.sets.Year[end] && gm.settings.GeneralDiscountRate[r]==0)
           @constraint(gm.model,
           gm.model[:CapitalInvestmentStorage][s,gm.sets.Year[k],r]*(1- gm.sets.Year[end]  - gm.sets.Year[k]+1)/gm.params.OperationalLifeStorage[r,s,gm.sets.Year[k]] == gm.model[:SalvageValueStorage][s,gm.sets.Year[k],r],
           base_name="SI7_SalvageValueStorageAtEndOfPeriod2_$(s)_$(gm.sets.Year[k])_$(r)")
         end
         if gm.settings.DepreciationMethod[r]==1 && ((gm.sets.Year[k]+gm.params.OperationalLifeStorage[r,s,gm.sets.Year[k]]-1) > gm.sets.Year[end] && gm.settings.GeneralDiscountRate[r]>0)
           @constraint(gm.model,
           gm.model[:CapitalInvestmentStorage][s,gm.sets.Year[k],r]*(1-(((1+gm.settings.GeneralDiscountRate[r])^(gm.sets.Year[end] - gm.sets.Year[k]+1)-1)/((1+gm.settings.GeneralDiscountRate[r])^gm.params.OperationalLifeStorage[r,s,gm.sets.Year[k]]-1))) == gm.model[:SalvageValueStorage][s,gm.sets.Year[k],r],
           base_name="SI8_SalvageValueStorageAtEndOfPeriod3_$(s)_$(gm.sets.Year[k])_$(r)")
         end
         @constraint(gm.model,
         gm.model[:SalvageValueStorage][s,gm.sets.Year[k],r]/((1+gm.settings.GeneralDiscountRate[r])^(1+max(gm.sets.Year...) - gm.switch.StartYear)) == gm.model[:DiscountedSalvageValueStorage][s,gm.sets.Year[k],r],
         base_name="SI9_SalvageValueStorageDiscountedToStartYear_$(s)_$(gm.sets.Year[k])_$(r)")
         @constraint(gm.model,
         gm.model[:DiscountedCapitalInvestmentStorage][s,gm.sets.Year[k],r]-gm.model[:DiscountedSalvageValueStorage][s,gm.sets.Year[k],r] == gm.model[:TotalDiscountedStorageCost][s,gm.sets.Year[k],r],
         base_name="SI10_TotalDiscountedCostByStorage_$(s)_$(gm.sets.Year[k])_$(r)")
   
         ######### Storage Equations #############
         if k==1
           JuMP.fix(gm.model[:StorageLevelYearStart][s, gm.sets.Year[k], r], gm.params.StorageLevelStart[r,s]; force=true)
         end
         if k>1
           @constraint(gm.model,
           gm.model[:StorageLevelYearStart][s,gm.sets.Year[k-1],r] + sum(gm.model[:NetChargeWithinYear][s,gm.sets.Year[k-1],ls,ld,lh,r] for ls ∈ gm.sets.Season for ld ∈ gm.sets.Daytype for lh ∈ gm.sets.DailyTimeBracket) == gm.model[:StorageLevelYearStart][s,gm.sets.Year[k],r],
           base_name="S5_StorageLeveYearStart_$(s)_$(gm.sets.Year[k])_$(r)")
         end
         if k<=length(gm.sets.Year)-1
           @constraint(gm.model,
           gm.model[:StorageLevelYearStart][s,gm.sets.Year[k+1],r] ==  gm.model[:StorageLevelYearFinish][s,gm.sets.Year[k],r],
           base_name="S7_StorageLevelYearFinish_$(s)_$(gm.sets.Year[k])_$(r)")
         end
         if k==length(gm.sets.Year)
           @constraint(gm.model,
           gm.model[:StorageLevelYearStart][s,gm.sets.Year[k],r] + sum(gm.model[:NetChargeWithinYear][s,gm.sets.Year[k],ls,ld,lh,r] for ls ∈ gm.sets.Season for ld ∈ gm.sets.Daytype for lh ∈ gm.sets.DailyTimeBracket) == gm.model[:StorageLevelYearFinish][s,gm.sets.Year[k],r],
           base_name="S8_StorageLevelYearFinish_$(s)_$(gm.sets.Year[k])_$(r)")
         end
   
         for j ∈ 1:length(gm.sets.Season)
           for i ∈ 1:length(gm.sets.Daytype)
             for lh ∈ gm.sets.DailyTimeBracket
   
               @constraint(gm.model,
               0 <= (gm.model[:StorageLevelDayTypeStart][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r]+sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lhlh,r] for lhlh ∈ gm.sets.DailyTimeBracket if (lh-lhlh > 0)))-gm.model[:StorageLowerLimit][s,gm.sets.Year[k],r],
               base_name="SC1_LowerLimit_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               (gm.model[:StorageLevelDayTypeStart][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r]+sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lhlh,r] for lhlh ∈ gm.sets.DailyTimeBracket if (lh-lhlh > 0)))-gm.model[:StorageUpperLimit][s,gm.sets.Year[k],r] <= 0,
               base_name="SC1_UpperLimit_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               0 <= (i>1 ? gm.model[:StorageLevelDayTypeStart][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r]-sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i-1],lhlh,r]  for lhlh ∈ gm.sets.DailyTimeBracket if (lh-lhlh < 0)) : 0) - gm.model[:StorageLowerLimit][s,gm.sets.Year[k],r],
               base_name="SC2_LowerLimit_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               (i>1 ? gm.model[:StorageLevelDayTypeStart][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r]-sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i-1],lhlh,r] for lhlh ∈ gm.sets.DailyTimeBracket if (lh-lhlh < 0)) : 0) - gm.model[:StorageUpperLimit][s,gm.sets.Year[k],r] <= 0,
               base_name="SC2_UpperLimit_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               0 <= (gm.model[:StorageLevelDayTypeFinish][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r] - sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lhlh,r] for lhlh ∈ gm.sets.DailyTimeBracket if (lh-lhlh < 0)))-gm.model[:StorageLowerLimit][s,gm.sets.Year[k],r],
               base_name="SC3_LowerLimit_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               (gm.model[:StorageLevelDayTypeFinish][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r] - sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lhlh,r] for lhlh ∈ gm.sets.DailyTimeBracket if (lh-lhlh < 0)))-gm.model[:StorageUpperLimit][s,gm.sets.Year[k],r] <= 0,
               base_name="SC3_UpperLimit_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               0 <= (i>1 ? gm.model[:StorageLevelDayTypeFinish][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i-1],r]+sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lhlh,r] for lhlh ∈ gm.sets.DailyTimeBracket if (lh-lhlh > 0)) : 0) - gm.model[:StorageLowerLimit][s,gm.sets.Year[k],r],
               base_name="SC4_LowerLimit_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               (i>1 ? gm.model[:StorageLevelDayTypeFinish][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i-1],r]+sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lhlh,r] for lhlh ∈ gm.sets.DailyTimeBracket if (lh-lhlh > 0)) : 0) - gm.model[:StorageUpperLimit][s,gm.sets.Year[k],r] <= 0,
               base_name="SC4_UpperLimit_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               gm.model[:RateOfStorageCharge][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r] <= gm.params.StorageMaxChargeRate[r,s]*gm.model[:StorageUpperLimit][s,gm.sets.Year[k],r],
               base_name="SC5_MaxChargeConstraint_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               gm.model[:RateOfStorageDischarge][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r] <= gm.params.StorageMaxDischargeRate[r,s]*gm.model[:StorageUpperLimit][s,gm.sets.Year[k],r],
               base_name="SC6_MaxDischargeConstraint_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
   
               @constraint(gm.model,
               sum(gm.model[:RateOfActivity][gm.sets.Year[k],l,t,m,r] * gm.params.TechnologyToStorage[gm.sets.Year[k],m,t,s] * gm.params.Conversionls[l,gm.sets.Season[j]] * gm.params.Conversionld[l,gm.sets.Daytype[i]] * gm.params.Conversionlh[l,lh] for t ∈ gm.subsets.StorageDummies for m ∈ gm.sets.Mode_of_operation for l ∈ gm.sets.Timeslice if gm.params.TechnologyToStorage[gm.sets.Year[k],m,t,s]>0) == gm.model[:RateOfStorageCharge][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r],
               base_name="S1_RateOfStorageCharge_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               sum(gm.model[:RateOfActivity][gm.sets.Year[k],l,t,m,r] * gm.params.TechnologyFromStorage[gm.sets.Year[k],m,t,s] * gm.params.Conversionls[l,gm.sets.Season[j]] * gm.params.Conversionld[l,gm.sets.Daytype[i]] * gm.params.Conversionlh[l,lh] for t ∈ gm.subsets.StorageDummies for m ∈ gm.sets.Mode_of_operation for l ∈ gm.sets.Timeslice if gm.params.TechnologyFromStorage[gm.sets.Year[k],m,t,s]>0) == gm.model[:RateOfStorageDischarge][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r],
               base_name="S2_RateOfStorageDischarge_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               sum((gm.model[:RateOfStorageCharge][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r] - gm.model[:RateOfStorageDischarge][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r]) * gm.params.YearSplit[l,gm.sets.Year[k]] * gm.params.Conversionls[l,gm.sets.Season[j]] * gm.params.Conversionld[l,gm.sets.Daytype[i]] * gm.params.Conversionlh[l,lh] for l ∈ gm.sets.Timeslice if (gm.params.Conversionls[l,gm.sets.Season[j]]>0 && gm.params.Conversionld[l,gm.sets.Daytype[i]]>0 && gm.params.Conversionlh[l,lh]>0) ) == gm.model[:NetChargeWithinYear][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r],
               base_name="S3_NetChargeWithinYear_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
               @constraint(gm.model,
               (gm.model[:RateOfStorageCharge][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r] - gm.model[:RateOfStorageDischarge][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r]) * sum(gm.params.DaySplit[gm.sets.Year[k],l] * gm.params.Conversionls[l,gm.sets.Season[j]] * gm.params.Conversionld[l,gm.sets.Daytype[i]] * gm.params.Conversionlh[l,lh] for l ∈ gm.sets.Timeslice) == gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],lh,r],
               base_name="S4_NetChargeWithinDay_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(lh)_$(r)")
             end
             if i==1
               @constraint(gm.model,
               gm.model[:StorageLevelSeasonStart][s,gm.sets.Year[k],gm.sets.Season[j],r] ==  gm.model[:StorageLevelDayTypeStart][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r],
               base_name="S11_StorageLevelDayTypeStart_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(r)")
             elseif i>1
               @constraint(gm.model,
               gm.model[:StorageLevelDayTypeStart][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i-1],r] + sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i-1],lh,r] * gm.params.DaysInDayType[gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i-1]] for lh ∈ gm.sets.DailyTimeBracket)  ==  gm.model[:StorageLevelDayTypeStart][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r],
               base_name="S12_StorageLevelDayTypeStart_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(r)")
             end
             if j==length(gm.sets.Season) && i == length(gm.sets.Daytype)
               @constraint(gm.model,
               gm.model[:StorageLevelYearFinish][s,gm.sets.Year[k],r] == gm.model[:StorageLevelDayTypeFinish][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r],
               base_name="S13_StorageLevelDayTypeFinish_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(r)")
             end
             if j <= length(gm.sets.Season)-1 && i == length(gm.sets.Daytype)
               @constraint(gm.model,
               gm.model[:StorageLevelSeasonStart][s,gm.sets.Year[k],gm.sets.Season[j+1],r] == gm.model[:StorageLevelDayTypeFinish][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r],
               base_name="S14_StorageLevelDayTypeFinish_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(r)")
             end
             if j <= length(gm.sets.Season)-1 && i <= length(gm.sets.Daytype)-1
               @constraint(gm.model,
               gm.model[:StorageLevelDayTypeFinish][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i+1],r] - sum(gm.model[:NetChargeWithinDay][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i+1],lh,r]  * gm.params.DaysInDayType[gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i+1]] for lh ∈ gm.sets.DailyTimeBracket) == gm.model[:StorageLevelDayTypeFinish][s,gm.sets.Year[k],gm.sets.Season[j],gm.sets.Daytype[i],r],
               base_name="S15_StorageLevelDayTypeFinish_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(gm.sets.Daytype[i])_$(r)")
             end
           end
           if j == 1
             @constraint(gm.model,
             gm.model[:StorageLevelSeasonStart][s,gm.sets.Year[k],gm.sets.Season[j],r] == gm.model[:StorageLevelYearStart][s,gm.sets.Year[k],r],
             base_name="S9_StorageLevelSeasonStart_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(r)")
           else
             @constraint(gm.model,
             gm.model[:StorageLevelSeasonStart][s,gm.sets.Year[k],gm.sets.Season[j],r] == gm.model[:StorageLevelSeasonStart][s,gm.sets.Year[k],gm.sets.Season[j-1],r] + sum(gm.model[:NetChargeWithinYear][s,gm.sets.Year[k],gm.sets.Season[j-1],ld,lh,r] for ld ∈ gm.sets.Daytype for lh ∈ gm.sets.DailyTimeBracket) ,
             base_name="S10_StorageLevelSeasonStart_$(s)_$(gm.sets.Year[k])_$(gm.sets.Season[j])_$(r)")
           end
         end
       end end end
       
       print("Cstr: Storage 4 : ",Dates.now()-start,"\n")
     end
   
     
      ######### Transportation Equations #############
      start=Dates.now()
     for r ∈ gm.sets.Region_full for y ∈ gm.sets.Year
       for f ∈ gm.subsets.TransportFuels
         if gm.params.SpecifiedAnnualDemand[r,f,y] != 0
           for l ∈ gm.sets.Timeslice for mt ∈ gm.sets.ModalType  
             @constraint(gm.model,
             gm.params.SpecifiedAnnualDemand[r,f,y]*gm.params.ModalSplitByFuelAndModalType[r,f,y,mt]*gm.params.SpecifiedDemandProfile[r,f,l,y] == gm.model[:DemandSplitByModalType][mt,l,r,f,y],
             base_name="T1a_SpecifiedAnnualDemandByModalSplit_$(mt)_$(l)_$(r)_$(f)_$(y)")
           end end
         end
       
         for mt ∈ gm.sets.ModalType
           if sum(gm.params.TagTechnologyToModalType[:,:,mt]) != 0
             for l ∈ gm.sets.Timeslice
               @constraint(gm.model,
               sum(gm.params.TagTechnologyToModalType[t,m,mt]*gm.model[:RateOfActivity][y,l,t,m,r]*gm.params.OutputActivityRatio[r,t,f,m,y]*gm.params.YearSplit[l,y] for (t,m) ∈ gm.other_params[:LoopSetOutput][(r,f,y)]) == gm.model[:ProductionSplitByModalType][mt,l,r,f,y],
               base_name="T2_ProductionOfTechnologyByModalSplit_$(mt)_$(l)_$(r)_$(f)_$(y)")
               @constraint(gm.model,
               gm.model[:ProductionSplitByModalType][mt,l,r,f,y] >= gm.model[:DemandSplitByModalType][mt,l,r,f,y],
               base_name="T3_ModalSplitBalance_$(mt)_$(l)_$(r)_$(f)_$(y)")
             end
           end
         end
       end
   
       for l ∈ gm.sets.Timeslice 
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_FRT_SHIP_RE",l,r,"Mobility_Passenger",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_FRT_ROAD_RE",l,r,"Mobility_Passenger",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_FRT_RAIL_RE",l,r,"Mobility_Passenger",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_FRT_SHIP_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_FRT_ROAD_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_FRT_RAIL_CONV",l,r,"Mobility_Passenger",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_PSNG_AIR_RE",l,r,"Mobility_Freight",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_PSNG_ROAD_RE",l,r,"Mobility_Freight",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_PSNG_RAIL_RE",l,r,"Mobility_Freight",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_PSNG_AIR_CONV",l,r,"Mobility_Freight",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_PSNG_ROAD_CONV",l,r,"Mobility_Freight",y], 0; force=true)
         JuMP.fix(gm.model[:ProductionSplitByModalType]["MT_PSNG_RAIL_CONV",l,r,"Mobility_Freight",y], 0; force=true)
       end
     end end
   
     print("Cstr: transport: ",Dates.now()-start,"\n")
     if gm.switch.switch_ramping == 1
     
       ############### Ramping #############
       start=Dates.now()
       for y ∈ gm.sets.Year for t ∈ gm.sets.Technology for r ∈ gm.sets.Region_full
         for f ∈ gm.sets.Fuel
           for i ∈ 1:length(gm.sets.Timeslice)
             if i>1
               if gm.params.TagDispatchableTechnology[t]==1 && (gm.params.RampingUpFactor[r,t,y] != 0 || gm.params.RampingDownFactor[r,t,y] != 0 && gm.params.AvailabilityFactor[r,t,y] > 0 && gm.params.TotalAnnualMaxCapacity[r,t,y] > 0 && gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0)
                 @constraint(gm.model,
                 ((sum(gm.model[:RateOfActivity][y,gm.sets.Timeslice[i],t,m,r]*gm.params.OutputActivityRatio[r,t,f,m,y] for m ∈ gm.sets.Mode_of_operation if gm.params.OutputActivityRatio[r,t,f,m,y] != 0)*gm.params.YearSplit[gm.sets.Timeslice[i],y]) - (sum(gm.model[:RateOfActivity][y,gm.sets.Timeslice[i-1],t,m,r]*gm.params.OutputActivityRatio[r,t,f,m,y] for m ∈ gm.sets.Mode_of_operation if gm.params.OutputActivityRatio[r,t,f,m,y] != 0)*gm.params.YearSplit[gm.sets.Timeslice[i-1],y]))
                 == gm.model[:ProductionUpChangeInTimeslice][y,gm.sets.Timeslice[i],f,t,r] - gm.model[:ProductionDownChangeInTimeslice][y,gm.sets.Timeslice[i],f,t,r],
                 base_name="R1_ProductionChange_$(y)_$(gm.sets.Timeslice[i])_$(f)_$(t)_$(r)")
               end
               if gm.params.TagDispatchableTechnology[t]==1 && gm.params.RampingUpFactor[r,t,y] != 0 && gm.params.AvailabilityFactor[r,t,y] > 0 && gm.params.TotalAnnualMaxCapacity[r,t,y] > 0 && gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
                 @constraint(gm.model,
                 gm.model[:ProductionUpChangeInTimeslice][y,gm.sets.Timeslice[i],f,t,r] <= gm.model[:TotalCapacityAnnual][y,t,r]*gm.params.AvailabilityFactor[r,t,y]*gm.params.CapacityToActivityUnit[r,t]*gm.params.RampingUpFactor[r,t,y]*gm.params.YearSplit[gm.sets.Timeslice[i],y],
                 base_name="R2_RampingUpLimit_$(y)_$(gm.sets.Timeslice[i])_$(f)_$(t)_$(r)")
               end
               if gm.params.TagDispatchableTechnology[t]==1 && gm.params.RampingDownFactor[r,t,y] != 0 && gm.params.AvailabilityFactor[r,t,y] > 0 && gm.params.TotalAnnualMaxCapacity[r,t,y] > 0 && gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
                 @constraint(gm.model,
                 gm.model[:ProductionDownChangeInTimeslice][y,gm.sets.Timeslice[i],f,t,r] <= gm.model[:TotalCapacityAnnual][y,t,r]*gm.params.AvailabilityFactor[r,t,y]*gm.params.CapacityToActivityUnit[r,t]*gm.params.RampingDownFactor[r,t,y]*gm.params.YearSplit[gm.sets.Timeslice[i],y],
                 base_name="R3_RampingDownLimit_$(y)_$(gm.sets.Timeslice[i])_$(f)_$(t)_$(r)")
               end
             end
             ############### Min Runing Constraint #############
             if gm.params.MinActiveProductionPerTimeslice[y,gm.sets.Timeslice[i],f,t,r] > 0
               @constraint(gm.model,
               sum(gm.model[:RateOfActivity][y,gm.sets.Timeslice[i],t,m,r]*gm.params.OutputActivityRatio[r,t,f,m,y] for m ∈ gm.sets.Mode_of_operation if gm.params.OutputActivityRatio[r,t,f,m,y] != 0) >= 
               gm.model[:TotalCapacityAnnual][y,t,r]*gm.params.AvailabilityFactor[r,t,y]*gm.params.CapacityToActivityUnit[r,t]*gm.params.MinActiveProductionPerTimeslice[y,gm.sets.Timeslice[i],f,t,r],
               base_name="MRC1_MinRunningConstraint_$(y)_$(gm.sets.Timeslice[i])_$(f)_$(t)_$(r)")
             end
           end
   
           ############### Ramping Costs #############
           if gm.params.TagDispatchableTechnology[t]==1 && gm.params.ProductionChangeCost[r,t,y] != 0 && gm.params.AvailabilityFactor[r,t,y] > 0 && gm.params.TotalAnnualMaxCapacity[r,t,y] > 0 && gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
             @constraint(gm.model,
             sum((gm.model[:ProductionUpChangeInTimeslice][y,l,f,t,r] + gm.model[:ProductionDownChangeInTimeslice][y,l,f,t,r])*gm.params.ProductionChangeCost[r,t,y] for l ∈ gm.sets.Timeslice) == gm.model[:AnnualProductionChangeCost][y,t,r],
             base_name="RC1_AnnualProductionChangeCosts_$(y)_$(f)_$(t)_$(r)")
           end
           if gm.params.TagDispatchableTechnology[t]==1 && gm.params.ProductionChangeCost[r,t,y] != 0 && gm.params.AvailabilityFactor[r,t,y] > 0 && gm.params.TotalAnnualMaxCapacity[r,t,y] > 0 && gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
             @constraint(gm.model,
             gm.model[:AnnualProductionChangeCost][y,t,r]/((1+gm.settings.TechnologyDiscountRate[r,t])^(y-gm.switch.StartYear+0.5)) == Discountedmodel[:AnnualProductionChangeCost][y,t,r],
             base_name="RC2_DiscountedAnnualProductionChangeCost_$(y)_$(f)_$(t)_$(r)")
           end
         end
         if (gm.params.TagDispatchableTechnology[t] == 0 || sum((m,f), gm.params.OutputActivityRatio[r,t,f,m,y]) == 0 || gm.params.ProductionChangeCost[r,t,y] == 0 || gm.params.AvailabilityFactor[r,t,y] == 0 || gm.params.TotalAnnualMaxCapacity[r,t,y] == 0 || gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] == 0)
           JuMP.fix(gm.model[:DiscountedAnnualProductionChangeCost][y,t,r], 0; force=true)
           JuMP.fix(gm.model[:AnnualProductionChangeCost][y,t,r], 0; force=true)
         end
       end end end
       
     print("Cstr: Ramping : ",Dates.now()-start,"\n")
     end
   
      ############### Curtailment Costs #############
     start=Dates.now()
     for y ∈ gm.sets.Year for f ∈ gm.sets.Fuel for r ∈ gm.sets.Region_full
       @constraint(gm.model,
       sum(gm.model[:Curtailment][y,l,f,r]*gm.params.CurtailmentCostFactor[r,f,y] for l ∈ gm.sets.Timeslice ) == gm.model[:AnnualCurtailmentCost][y,f,r],
       base_name="CC1_AnnualCurtailmentCosts_$(y)_$(f)_$(r)")
       @constraint(gm.model,
       gm.model[:AnnualCurtailmentCost][y,f,r]/((1+gm.settings.GeneralDiscountRate[r])^(y-gm.switch.StartYear+0.5)) == gm.model[:DiscountedAnnualCurtailmentCost][y,f,r],
       base_name="CC2_DiscountedAnnualCurtailmentCosts_$(y)_$(f)_$(r)")
     end end end
   
     print("Cstr: Curtailment : ",Dates.now()-start,"\n")
   
     if gm.switch.switch_base_year_bounds == 1
     
      ############### General BaseYear Limits && trajectories #############
      start=Dates.now()
       for y ∈ gm.sets.Year for t ∈ gm.sets.Technology for r ∈ gm.sets.Region_full
         for f ∈ gm.sets.Fuel
           if gm.params.RegionalBaseYearProduction[r,t,f,y] != 0
             @constraint(gm.model,
             gm.model[:ProductionByTechnologyAnnual][y,t,f,r] >= gm.params.RegionalBaseYearProduction[r,t,f,y]*(1-gm.model[:BaseYearSlack][f]) - gm.model[:RegionalBaseYearProduction_neg][y,r,t,f],
             base_name="B4a_RegionalBaseYearProductionLowerBound_$(y)_$(r)_$(t)_$(f)")
           end
         end
         if gm.params.RegionalBaseYearProduction[r,t,"Power",y] != 0
           @constraint(gm.model,
           gm.model[:ProductionByTechnologyAnnual][y,t,"Power",r] <= gm.params.RegionalBaseYearProduction[r,t,"Power",y]+gm.model[:BaseYearOvershoot][r,t,"Power",y],
           base_name="B4b_RegionalBaseYearProductionUpperBound_$(y)_$(r)_$(t)_Power")
         end
       end end end
       print("Cstr: Baseyear : ",Dates.now()-start,"\n")
     end
     
      ######### Peaking Equations #############
      start=Dates.now()
     if gm.switch.switch_peaking_capacity == 1
       @variable(gm.model, PeakingDemand[gm.sets.Year,gm.sets.Region_full])
       @variable(gm.model, PeakingCapacity[gm.sets.Year,gm.sets.Region_full])
       GWh_to_PJ = 0.0036
       PeakingSlack = gm.switch.set_peaking_slack
       MinRunShare = gm.switch.set_peaking_minrun_share
       RenewableCapacityFactorReduction = gm.switch.set_peaking_res_cf
       for y ∈ gm.sets.Year for r ∈ gm.sets.Region_full
         @constraint(gm.model,
         gm.model[:PeakingDemand][y,r] ==
           sum(gm.model[:UseByTechnologyAnnual][y,t,"Power",r]/GWh_to_PJ*gm.params.x_peakingDemand[r,se]/8760
             #Demand per Year in PJ             to Gwh     Highest peak hour value   /number hours per year
           for se ∈ gm.sets.Sector for t ∈ setdiff(gm.sets.Technology,gm.subsets.StorageDummies) if gm.params.x_peakingDemand[r,se] != 0 && gm.params.TagTechnologyToSector[t,se] != 0)
         + gm.params.SpecifiedAnnualDemand[r,"Power",y]/GWh_to_PJ*gm.params.x_peakingDemand[r,"Power"]/8760,
         base_name="PC1_PowerPeakingDemand_$(y)_$(r)")
   
         @constraint(gm.model,
         gm.model[:PeakingCapacity][y,r] ==
           sum((sum(gm.params.CapacityFactor[r,t,l,y] for l ∈ gm.sets.Timeslice ) < length(gm.sets.Timeslice) ? gm.model[:TotalCapacityAnnual][y,t,r]*gm.params.AvailabilityFactor[r,t,y]*RenewableCapacityFactorReduction*(sum(gm.params.CapacityFactor[r,t,l,y] for l ∈ gm.sets.Timeslice)/length(gm.sets.Timeslice)) : 0)
           + (sum(gm.params.CapacityFactor[r,t,l,y] for l ∈ gm.sets.Timeslice ) >= length(gm.sets.Timeslice) ? gm.model[:TotalCapacityAnnual][y,t,r]*gm.params.AvailabilityFactor[r,t,y] : 0)
           for t ∈ setdiff(gm.sets.Technology,gm.subsets.StorageDummies) if (sum(gm.params.OutputActivityRatio[r,t,"Power",m,y] for m ∈ gm.sets.Mode_of_operation) != 0)),
           base_name="PC2_PowerPeakingCapacity_$(y)_$(r)")
   
         if y >gm.switch.set_peaking_startyear
           @constraint(gm.model,
           gm.model[:PeakingCapacity][y,r] + (gm.switch.switch_peaking_with_trade == 1 ? sum(gm.model[:TotalTradeCapacity][y,"Power",rr,r] for rr ∈ gm.sets.Region_full) : 0)
           + (gm.switch.switch_peaking_with_storages == 1 ? sum(gm.model[:TotalCapacityAnnual][y,t,r] for t ∈ setdiff(gm.sets.Technology,gm.subsets.StorageDummies) if (sum(gm.params.OutputActivityRatio[r,t,"Power",m,y] for m ∈ gm.sets.Mode_of_operation) != 0)) : 0)
           >= gm.model[:PeakingDemand][y,r]*PeakingSlack,
           base_name="PC3_PeakingConstraint_$(y)_$(r)")
         end
         
         if gm.switch.switch_peaking_minrun == 1
           for t ∈ gm.sets.Technology
             if (gm.params.TagTechnologyToSector[t,"Power"]==1 && gm.params.AvailabilityFactor[r,t,y]<=1 && 
               gm.params.TagDispatchableTechnology[t]==1 && gm.params.AvailabilityFactor[r,t,y] > 0 && 
               gm.params.TotalAnnualMaxCapacity[r,t,y] > 0 && gm.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 && 
               ((((JuMP.has_upper_bound(gm.model[:TotalCapacityAnnual][y,t,r])) && (JuMP.upper_bound(gm.model[:TotalCapacityAnnual][y,t,r]) > 0)) ||
               ((!JuMP.has_upper_bound(gm.model[:TotalCapacityAnnual][y,t,r])) && (!JuMP.is_fixed(gm.model[:TotalCapacityAnnual][y,t,r]))) ||
               ((JuMP.is_fixed(gm.model[:TotalCapacityAnnual][y,t,r])) && (JuMP.fix_value(gm.model[:TotalCapacityAnnual][y,t,r]) > 0)))) && 
               y > gm.switch.set_peaking_startyear)
               @constraint(gm.model,
               sum(sum(gm.model[:RateOfActivity][y,l,t,m,r] for m ∈ gm.sets.Mode_of_operation)*gm.params.YearSplit[l,y] for l ∈ gm.sets.Timeslice ) >= 
               sum(gm.model[:TotalCapacityAnnual][y,t,r]*gm.params.CapacityFactor[r,t,l,y]*gm.params.YearSplit[l,y]*gm.params.AvailabilityFactor[r,t,y]*gm.params.CapacityToActivityUnit[r,t] for l ∈ gm.sets.Timeslice )*MinRunShare,
               base_name="PC4_MinRunConstraint_$(y)_$(t)_$(r)")
             end
           end
         end
       end end
     end
     print("Cstr: Peaking : ",Dates.now()-start,"\n")
   
   
     if gm.switch.switch_endogenous_employment == 1
   
      ############### Employment effects #############
     
       @variable(gm.model, TotalJobs[gm.sets.Region_full, gm.sets.Year])
   
       genesysmod_employment(gm.model,gm.params,Emp_Sets)
       for r ∈ gm.sets.Region_full, y ∈ gm.sets.Year
         @constraint(gm.model,
         sum(((gm.model[:NewCapacity][y,t,r]*Emp_Params.EFactorManufacturing[t,y]*Emp_Params.RegionalAdjustmentFactor[gm.switch.model_region,y]*Emp_Params.LocalManufacturingFactor[gm.switch.model_region,y])
         +(gm.model[:NewCapacity][y,t,r]*Emp_Params.EFactorConstruction[t,y]*Emp_Params.RegionalAdjustmentFactor[gm.switch.model_region,y])
         +(gm.model[:TotalCapacityAnnual][y,t,r]*Emp_Params.EFactorOM[t,y]*Emp_Params.RegionalAdjustmentFactor[gm.switch.model_region,y])
         +(gm.model[:UseByTechnologyAnnual][y,t,f,r]*Emp_Params.EFactorFuelSupply[t,y]))*(1-Emp_Params.DeclineRate[t,y])^YearlyDifferenceMultiplier(y,gm.sets)
         +((gm.model[:UseByTechnologyAnnual][y,"HLI_Hardcoal","Hardcoal",r]+gm.model[:UseByTechnologyAnnual][y,"HMI_HardCoal","Hardcoal",r]
         +(gm.model[:UseByTechnologyAnnual][y,"HHI_BF_BOF","Hardcoal",r])*Emp_Params.EFactorCoalJobs["Coal_Heat",y]*Emp_Params.CoalSupply[r,y]))
         +(Emp_Params.CoalSupply[r,y]*Emp_Params.CoalDigging[gm.switch.model_region,"Coal_Export","$(gm.switch.emissionPathway)_$(gm.switch.emissionScenario)",y]*Emp_Params.EFactorCoalJobs["Coal_Export",y]) for t ∈ gm.sets.Technology for f ∈ gm.sets.Fuel)
         == gm.model[:TotalJobs][r,y],
         base_name="Jobs1_TotalJobs_$(r)_$(y)")
       end
     end
end