
function addConstraint_CapAdequacyA1(x)
for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full
    cond = (
      any(
        x->x>0,
        [
          x.params.TotalAnnualMaxCapacity[r,t,yy] for yy ∈ x.sets.Year if (y - yy < x.params.OperationalLife[r,t]) && (y-yy>= 0)
        ]
      )
      ) && (x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0)

    if cond
      @constraint(x.model, x.model[:AccumulatedNewCapacity][y,t,r] == sum(x.model[:NewCapacity][yy,t,r] for yy ∈ x.sets.Year if (y - yy < x.params.OperationalLife[r,t]) && (y-yy>= 0)), base_name="CAa1_TotalNewCapacity_$(y)_$(t)_$(r)")
    else
      JuMP.fix(x.model[:AccumulatedNewCapacity][y,t,r], 0; force=true)
    end
    if cond || (x.params.ResidualCapacity[r,t,y]) > 0
      @constraint(x.model, x.model[:AccumulatedNewCapacity][y,t,r] + x.params.ResidualCapacity[r,t,y] == x.model[:TotalCapacityAnnual][y,t,r], base_name="CAa2_TotalAnnualCapacity_$(y)_$(t)_$(r)")
    elseif !cond && (x.params.ResidualCapacity[r,t,y]) == 0
      JuMP.fix(x.model[:TotalCapacityAnnual][y,t,r],0; force=true)
    end
  end
end

function addConstraint_CapAdequacyA2(x)
  for y ∈ x.sets.Year, t ∈ x.sets.Technology,  r ∈ x.sets.Region_full, l ∈ x.sets.Timeslice, m ∈ x.sets.Mode_of_operation
    if ((x.params.CapacityFactor[r,t,l,y] == 0)) ||
      (x.params.AvailabilityFactor[r,t,y] == 0) ||
      (x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] == 0) ||
      (x.params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] == 0) ||
      (x.params.TotalAnnualMaxCapacity[r,t,y] == 0) ||
      ((JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][y,t,r])) && (JuMP.upper_bound(x.model[:TotalCapacityAnnual][y,t,r]) == 0)) ||
      ((JuMP.is_fixed(x.model[:TotalCapacityAnnual][y,t,r])) && (JuMP.fix_value(x.model[:TotalCapacityAnnual][y,t,r]) == 0))
        JuMP.fix(x.model[:RateOfActivity][y,l,t,m,r], 0; force=true)
    end
  end
end

function addConstraint_CapAdequacyA3(x)
  if x.switch.switch_intertemporal == 1
    for r ∈ x.sets.Region_full, l ∈ x.sets.Timeslice, t ∈ x.sets.Technology, y ∈ x.sets.Year
      if x.params.CapacityFactor[r,t,l,y] > 0 && x.params.AvailabilityFactor[r,t,y] > 0 && x.params.TotalAnnualMaxCapacity[r,t,y] > 0 && x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0
        @constraint(x.model,
        x.model[:RateOfTotalActivity][y,l,t,r] == x.model[:TotalActivityPerYear][r,l,t,y]*x.params.AvailabilityFactor[r,t,y] - x.model[:DispatchDummy][r,l,t,y]*x.params.TagDispatchableTechnology[t],
        base_name="CAa4_Constraint_Capacity_$(r)_$(l)_$(t)_$(y)")
      end
      if (sum(x.params.CapacityFactor[r,t,l,yy] for yy ∈ x.sets.Year if y-yy < x.params.OperationalLife[r,t] && y-yy >= 0) > 0 || x.params.CapacityFactor[r,t,l,x.switch.StartYear] > 0) && x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 && x.params.AvailabilityFactor[r,t,y] > 0 && x.params.TotalAnnualMaxCapacity[r,t,y] > 0
        @constraint(x.model,
        x.model[:TotalActivityPerYear][r,l,t,y] == sum(x.model[:NewCapacity][yy,t,r] * x.params.CapacityFactor[r,t,l,yy] * x.params.CapacityToActivityUnit[r,t] for yy ∈ x.sets.Year if y-yy < x.params.OperationalLife[r,t] && y-yy >= 0)+(x.params.ResidualCapacity[r,t,y]*x.params.CapacityFactor[r,t,l,x.switch.StartYear] * x.params.CapacityToActivityUnit[r,t]),
        base_name="CAaT_TotalActivityPerYear_Intertemporal_$(r)_$(l)_$(t)_$(y)")
      end
    end

  else
    for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full, l ∈ x.sets.Timeslice
      if (x.params.CapacityFactor[r,t,l,y] > 0) &&
        (x.params.AvailabilityFactor[r,t,y] > 0) &&
        (x.params.TotalAnnualMaxCapacity[r,t,y] > 0) &&
        (x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0)
          @constraint(x.model, sum(x.model[:RateOfActivity][y,l,t,m,r] for m ∈ x.sets.Mode_of_operation) == x.model[:TotalCapacityAnnual][y,t,r] * x.params.CapacityFactor[r,t,l,y] * x.params.CapacityToActivityUnit[r,t] * x.params.AvailabilityFactor[r,t,y] - x.model[:DispatchDummy][r,l,t,y] * x.params.TagDispatchableTechnology[t],
          base_name="CAa4_Constraint_Capacity_$(r)_$(l)_$(t)_$(y)")
      end
    end
  end
end

function addConstraint_CapAdequacyB(x)
  for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full
    if (x.params.AvailabilityFactor[r,t,y] < 1) &&
      (x.params.TotalAnnualMaxCapacity[r,t,y] > 0) &&
      (x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0) &&
      (((JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][y,t,r])) && (JuMP.upper_bound(x.model[:TotalCapacityAnnual][y,t,r]) > 0)) ||
      ((!JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][y,t,r])) && (!JuMP.is_fixed(x.model[:TotalCapacityAnnual][y,t,r]))) ||
      ((JuMP.is_fixed(x.model[:TotalCapacityAnnual][y,t,r])) && (JuMP.fix_value(x.model[:TotalCapacityAnnual][y,t,r]) > 0)))
      @constraint(x.model, sum(sum(x.model[:RateOfActivity][y,l,t,m,r]  for m ∈ x.sets.Mode_of_operation) * x.params.YearSplit[l,y] for l ∈ x.sets.Timeslice) <= sum(x.model[:TotalCapacityAnnual][y,t,r]*x.params.CapacityFactor[r,t,l,y]*x.params.YearSplit[l,y]*x.params.AvailabilityFactor[r,t,y]*x.params.CapacityToActivityUnit[r,t] for l ∈ x.sets.Timeslice), base_name="CAb1_PlannedMaintenance_$(y)_$(t)_$(r)")
    end
  end
end