
function addConstraint_Salvage(x)
    for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full
        if x.settings.DepreciationMethod[r]==1 && ((y + x.params.OperationalLife[r,t] - 1 > max(x.sets.Year...)) && (x.settings.TechnologyDiscountRate[r,t] > 0))
          @constraint(x.model, 
          x.model[:SalvageValue][y,t,r] == x.params.CapitalCost[r,t,y]*x.model[:NewCapacity][y,t,r]*(1-(((1+x.settings.TechnologyDiscountRate[r,t])^(max(x.sets.Year...) - y + 1 ) -1)/((1+x.settings.TechnologyDiscountRate[r,t])^x.params.OperationalLife[r,t]-1))),
          base_name="SV1_SalvageValueAtEndOfPeriod1_$(y)_$(t)_$(r)")
        end
    
        if (((y + x.params.OperationalLife[r,t]-1 > max(x.sets.Year...)) && (x.settings.TechnologyDiscountRate[r,t] == 0)) || (x.settings.DepreciationMethod[r]==2 && (y + x.params.OperationalLife[r,t]-1 > max(x.sets.Year...))))
          @constraint(x.model,
          x.model[:SalvageValue][y,t,r] == x.params.CapitalCost[r,t,y]*x.model[:NewCapacity][y,t,r]*(1-(max(x.sets.Year...)- y+1)/x.params.OperationalLife[r,t]),
          base_name="SV2_SalvageValueAtEndOfPeriod2_$(y)_$(t)_$(r)")
        end
        if y + x.params.OperationalLife[r,t]-1 <= max(x.sets.Year...)
          @constraint(x.model,
          x.model[:SalvageValue][y,t,r] == 0,
          base_name="SV3_SalvageValueAtEndOfPeriod3_$(y)_$(t)_$(r)")
        end
    
        @constraint(x.model,
        x.model[:DiscountedSalvageValue][y,t,r] == x.model[:SalvageValue][y,t,r]/((1+x.settings.TechnologyDiscountRate[r,t])^(1+max(x.sets.Year...) - x.switch.StartYear)),
        base_name="SV4_SalvageValueDiscToStartYr_$(y)_$(t)_$(r)")
      end
end