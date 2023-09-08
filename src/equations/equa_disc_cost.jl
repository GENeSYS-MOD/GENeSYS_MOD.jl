
function addConstraint_DiscCost(x)
for y ∈ x.sets.Year, r ∈ x.sets.Region_full
    for t ∈ x.sets.Technology 
      @constraint(x.model,
      x.model[:DiscountedOperatingCost][y,t,r]+x.model[:DiscountedCapitalInvestment][y,t,r]+x.model[:DiscountedTechnologyEmissionsPenalty][y,t,r]-x.model[:DiscountedSalvageValue][y,t,r]
      + (x.switch.switch_ramping ==1 ? x.model[:DiscountedAnnualProductionChangeCost][y,t,r] : 0)
      == x.model[:TotalDiscountedCostByTechnology][y,t,r],
      base_name="TDC1_TotalDiscountedCostByTechnology_$(y)_$(t)_$(r)")
    end
    @constraint(x.model, sum(x.model[:TotalDiscountedCostByTechnology][y,t,r] for t ∈ x.sets.Technology)+sum(x.model[:TotalDiscountedStorageCost][s,y,r] for s ∈ x.sets.Storage) == x.model[:TotalDiscountedCost][y,r]
    ,base_name="TDC2_TotalDiscountedCost_$(y)_$(r)")
  end
end