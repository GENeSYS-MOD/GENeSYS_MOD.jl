
function build_obj(x)
    @objective(x.model, Min,
    sum(x.model[:TotalDiscountedCost][y,r] for y ∈x.sets.Year for r ∈x.sets.Region_full)
    + sum(x.model[:DiscountedAnnualTotalTradeCosts][y,r] for y ∈x.sets.Year for r ∈x.sets.Region_full)
    + sum(x.model[:DiscountedNewTradeCapacityCosts][y,f,r,rr] for y ∈x.sets.Year for f ∈x.sets.Fuel for r ∈x.sets.Region_full for rr ∈x.sets.Region_full)
    + sum(x.model[:DiscountedAnnualCurtailmentCost][y,f,r] for y ∈x.sets.Year for f ∈x.sets.Fuel for r ∈x.sets.Region_full)
    + sum(x.model[:BaseYearOvershoot][r,t,"Power",y]*999 for y ∈x.sets.Year for r ∈x.sets.Region_full for t ∈x.sets.Technology)
    )
end