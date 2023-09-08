
function addConstraint_CapCost(x)
    for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full
      @constraint(x.model, x.params.CapitalCost[r,t,y] * x.model[:NewCapacity][y,t,r] == x.model[:CapitalInvestment][y,t,r], base_name="CC1_UndiscountedCapitalInvestment_$(y)_$(t)_$(r)")
      @constraint(x.model, x.model[:CapitalInvestment][y,t,r]/((1+x.settings.TechnologyDiscountRate[r,t])^(y-x.switch.StartYear)) == x.model[:DiscountedCapitalInvestment][y,t,r], base_name="CC2_DiscountingCapitalInvestment_$(y)_$(t)_$(r)")
    end
end
    
     ############### Investment & Capacity Limits #############
function addConstraint_InvCapLimits(x)
    if x.switch.switch_dispatch == 0
      if x.switch.switch_investLimit == 1
        for i ∈ 1:length(x.sets.Year)
          if x.sets.Year[i] > x.switch.StartYear
            @constraint(x.model, 
            sum(x.model[:CapitalInvestment][x.sets.Year[i],t,r] for t ∈ x.sets.Technology for r ∈ x.sets.Region_full) <= 1/(max(x.sets.Year...)-x.switch.StartYear)*YearlyDifferenceMultiplier(x.sets.Year[i-1],x.sets)*x.settings.InvestmentLimit*sum(x.model[:CapitalInvestment][yy,t,r] for yy ∈ x.sets.Year for t ∈ x.sets.Technology for r ∈ x.sets.Region_full), 
            base_name="CC3_InvestmentLimit_$(x.sets.Year[i])")
            for r ∈ x.sets.Region_full 
              for t ∈ x.subsets.Renewables
                @constraint(x.model,
                x.model[:NewCapacity][x.sets.Year[i],t,r] <= YearlyDifferenceMultiplier(x.sets.Year[i-1],x.sets)*x.settings.NewRESCapacity*x.params.TotalAnnualMaxCapacity[r,t,x.sets.Year[i]], 
                base_name="CC4_CapacityLimit_$(x.sets.Year[i])_$(r)_$(t)")
              end
              for f ∈ x.sets.Fuel
                for t ∈ x.subsets.PhaseInSet
                  @constraint(x.model,
                  x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r] >= x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r]*x.settings.PhaseIn[x.sets.Year[i]]*(x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i]] > 0 ? x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i]]/x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i-1]] : 1), 
                  base_name="CC5c_PhaseInLowerLimit_$(x.sets.Year[i])_$(r)_$(t)_$(f)")
                end
                for t ∈ x.subsets.PhaseOutSet
                  @constraint(x.model, 
                  x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r] <= x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r]*x.settings.PhaseOut[x.sets.Year[i]]*(x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i]] > 0 ? x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i]]/x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i-1]] : 1), 
                  base_name="CC5d_PhaseOutUpperLimit_$(x.sets.Year[i])_$(r)_$(t)_$(f)")
                end
              end
            end
            for f ∈ x.sets.Fuel
              if x.settings.ProductionGrowthLimit[x.sets.Year[i],f]>0
                @constraint(x.model,
                sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r]-x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r] for t ∈ x.sets.Technology for r ∈ x.sets.Region_full if x.params.RETagTechnology[r,t,x.sets.Year[i]]==1) <= 
                YearlyDifferenceMultiplier(x.sets.Year[i-1],x.sets)*x.settings.ProductionGrowthLimit[x.sets.Year[i],f]*sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r] for t ∈ x.sets.Technology for r ∈ x.sets.Region_full)-sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r] for t ∈ x.subsets.StorageDummies for r ∈ x.sets.Region_full),
                base_name="CC5f_AnnualProductionChangeLimit_$(x.sets.Year[i])_$(f)")
              end
            end
          end
        end
      
  
        if x.switch.switch_ccs == 1
          for r ∈ x.sets.Region_full
            for i ∈ 2:length(x.sets.Year) for f ∈ setdiff(x.sets.Fuel,["DAC_Dummy"]) 
              @constraint(x.model,
              sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r]-x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r] for t ∈ x.subsets.CCS) <= YearlyDifferenceMultiplier(x.sets.Year[i-1],x.sets)*(x.settings.ProductionGrowthLimit[x.sets.Year[i],"Air"])*sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r] for t ∈ x.sets.Technology),
              base_name="CC5g_CCSAddition_$(x.sets.Year[i])_$(r)_$(f)")
            end end
  
            if sum(x.params.RegionalCCSLimit[r] for r ∈ x.sets.Region_full)>0
              @constraint(x.model,
              sum(sum( x.model[:TotalAnnualTechnologyActivityByMode][y,t,m,r]*x.params.EmissionContentPerFuel[f,e]*x.params.InputActivityRatio[r,t,f,m,y]*YearlyDifferenceMultiplier(y,x.sets)*((x.params.EmissionActivityRatio[r,t,e,m,y]>0 ? (1-x.params.EmissionActivityRatio[r,t,e,m,y]) : 0)+
              (x.params.EmissionActivityRatio[r,t,e,m,y] < 0 ? (-1)*x.params.EmissionActivityRatio[r,t,e,m,y] : 0)) for f ∈ x.sets.Fuel for m ∈ x.sets.Mode_of_operation for e ∈ x.sets.Emission) for y ∈ x.sets.Year for t ∈ x.subsets.CCS ) <= x.params.RegionalCCSLimit[r],
              base_name="CC5i_CCSLimit_$(r)")
            end
          end
        end
  
        for i ∈ 2:length(x.sets.Year) for f ∈ x.sets.Fuel
          if x.settings.ProductionGrowthLimit[x.sets.Year[i],f]>0
            for r ∈ x.sets.Region_full 
              @constraint(x.model,
              sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r]-x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r] for t ∈ x.subsets.StorageDummies) <= YearlyDifferenceMultiplier(x.sets.Year[i-1],x.sets)*(x.settings.ProductionGrowthLimit[x.sets.Year[i],f]+x.settings.StorageLimitOffset)*sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i-1],t,f,r] for t ∈ x.sets.Technology),
              base_name="CC5h_AnnualStorageChangeLimit_$(x.sets.Year[i])_$(r)_$(f)")
            end
          end
        end end
      end
    end
end
  
    