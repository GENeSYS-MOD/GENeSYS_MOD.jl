

function addConstraint_AccTech1(x)
    for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full, m ∈ x.sets.Mode_of_operation
      if x.other_params[:CanBuildTechnology][y,t,r] > 0
        @constraint(x.model, sum(x.model[:RateOfActivity][y,l,t,m,r]*x.params.YearSplit[l,y] for l ∈ x.sets.Timeslice) == x.model[:TotalAnnualTechnologyActivityByMode][y,t,m,r], base_name="Acc3_AverageAnnualRateOfActivity_$(y)_$(t)_$(m)_$(r)")
      else
        JuMP.fix(x.model[:TotalAnnualTechnologyActivityByMode][y,t,m,r],0; force=true)
      end
    end
end

function addConstraint_AccTech2(x)
    for r ∈ x.sets.Region_full
      @constraint(x.model, sum(x.model[:TotalDiscountedCost][y,r] for y ∈ x.sets.Year) == x.model[:ModelPeriodCostByRegion][r], base_name="Acc4_ModelPeriodCostByRegion_$(r)")
    end
end
