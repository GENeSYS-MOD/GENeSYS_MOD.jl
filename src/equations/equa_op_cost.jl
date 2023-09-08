
function addConstraint_OpCost(x)
    for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full
        if (sum(x.params.VariableCost[r,t,m,y] for m ∈ x.sets.Mode_of_operation) > 0) & (x.other_params[:CanBuildTechnology][y,t,r] > 0)
          @constraint(x.model, sum((x.model[:TotalAnnualTechnologyActivityByMode][y,t,m,r]*x.params.VariableCost[r,t,m,y]) for m ∈ x.sets.Mode_of_operation) == x.model[:AnnualVariableOperatingCost][y,t,r], base_name="OC1_OperatingCostsVariable_$(y)_$(t)_$(r)")
        else
          JuMP.fix(x.model[:AnnualVariableOperatingCost][y,t,r],0; force=true)
        end
    
        if (x.params.FixedCost[r,t,y] > 0) & (x.other_params[:CanBuildTechnology][y,t,r] > 0)
          @constraint(x.model, sum(x.model[:NewCapacity][yy,t,r]*x.params.FixedCost[r,t,yy] for yy ∈ x.sets.Year if (y-yy < x.params.OperationalLife[r,t]) && (y-yy >= 0)) == x.model[:AnnualFixedOperatingCost][y,t,r], base_name="OC2_OperatingCostsFixedAnnual_$(y)_$(t)_$(r)")
        else
          JuMP.fix(x.model[:AnnualFixedOperatingCost][y,t,r],0; force=true)
        end
    
        if ((JuMP.has_upper_bound(x.model[:AnnualVariableOperatingCost][y,t,r]) && JuMP.upper_bound(x.model[:AnnualVariableOperatingCost][y,t,r]) >0) || 
          (!JuMP.is_fixed(x.model[:AnnualVariableOperatingCost][y,t,r]) >0) && !JuMP.has_upper_bound(x.model[:AnnualVariableOperatingCost][y,t,r]) ||
          (JuMP.is_fixed(x.model[:AnnualVariableOperatingCost][y,t,r]) && JuMP.fix_value(x.model[:AnnualVariableOperatingCost][y,t,r]) >0)) ||
          ((JuMP.has_upper_bound(x.model[:AnnualFixedOperatingCost][y,t,r]) && JuMP.upper_bound(x.model[:AnnualFixedOperatingCost][y,t,r]) >0) || 
          (!JuMP.is_fixed(x.model[:AnnualFixedOperatingCost][y,t,r]) >0) && !JuMP.has_upper_bound(x.model[:AnnualFixedOperatingCost][y,t,r]) ||
          (JuMP.is_fixed(x.model[:AnnualFixedOperatingCost][y,t,r]) && JuMP.fix_value(x.model[:AnnualFixedOperatingCost][y,t,r]) >0)) #OC3_OperatingCostsTotalAnnual
          @constraint(x.model, (x.model[:AnnualFixedOperatingCost][y,t,r] + x.model[:AnnualVariableOperatingCost][y,t,r])*YearlyDifferenceMultiplier(y,x.sets) == x.model[:OperatingCost][y,t,r], base_name="OC3_OperatingCostsTotalAnnual_$(y)_$(t)_$(r)")
        else
          JuMP.fix(x.model[:OperatingCost][y,t,r],0; force=true)
        end
    
        if ((JuMP.has_upper_bound(x.model[:OperatingCost][y,t,r]) && JuMP.upper_bound(x.model[:OperatingCost][y,t,r]) >0) || 
          (!JuMP.is_fixed(x.model[:OperatingCost][y,t,r]) >0) && !JuMP.has_upper_bound(x.model[:OperatingCost][y,t,r]) ||
          (JuMP.is_fixed(x.model[:OperatingCost][y,t,r]) && JuMP.fix_value(x.model[:OperatingCost][y,t,r]) >0)) # OC4_DiscountedOperatingCostsTotalAnnual
          @constraint(x.model, x.model[:OperatingCost][y,t,r]/((1+x.settings.TechnologyDiscountRate[r,t])^(y-x.switch.StartYear+0.5)) == x.model[:DiscountedOperatingCost][y,t,r], base_name="OC4_DiscountedOperatingCostsTotalAnnual_$(y)_$(t)_$(r)")
        else
          JuMP.fix(x.model[:DiscountedOperatingCost][y,t,r],0; force=true)
        end
      end
end