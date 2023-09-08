function addConstraint_AnnualActivity(x)
    for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full
      if (x.other_params[:CanBuildTechnology][y,t,r] > 0) && 
        (any(x->x>0, [JuMP.has_upper_bound(x.model[:ProductionByTechnologyAnnual][y,t,f,r]) ? JuMP.upper_bound(x.model[:ProductionByTechnologyAnnual][y,t,f,r]) : ((JuMP.is_fixed(x.model[:ProductionByTechnologyAnnual][y,t,f,r])) && (JuMP.fix_value(x.model[:ProductionByTechnologyAnnual][y,t,f,r]) == 0)) ? 0 : 999999 for f ∈ x.sets.Fuel]))
        @constraint(x.model, sum(x.model[:ProductionByTechnologyAnnual][y,t,f,r] for f ∈ x.sets.Fuel) == x.model[:TotalTechnologyAnnualActivity][y,t,r], base_name= "AAC1_TotalAnnualTechnologyActivity_$(y)_$(t)_$(r)")
      else
        JuMP.fix(x.model[:TotalTechnologyAnnualActivity][y,t,r],0; force=true)
      end
  
      if x.params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] < 999999
        @constraint(x.model, x.model[:TotalTechnologyAnnualActivity][y,t,r] <= x.params.TotalTechnologyAnnualActivityUpperLimit[r,t,y], base_name= "AAC2_TotalAnnualTechnologyActivityUpperLimit_$(y)_$(t)_$(r)")
      end
  
      if x.params.TotalTechnologyAnnualActivityLowerLimit[r,t,y] > 0 # AAC3_TotalAnnualTechnologyActivityLowerLimit
        @constraint(x.model, x.model[:TotalTechnologyAnnualActivity][y,t,r] >= x.params.TotalTechnologyAnnualActivityLowerLimit[r,t,y], base_name= "AAC3_TotalAnnualTechnologyActivityLowerLimit_$(y)_$(t)_$(r)")
      end
    end
end
    
     ################ Total Activity Constraints ##############
function addConstraint_TotalActivity(x)
    for t ∈ x.sets.Technology, r ∈ x.sets.Region_full
            @constraint(x.model, sum(x.model[:TotalTechnologyAnnualActivity][y,t,r]*YearlyDifferenceMultiplier(y,x.sets) for y ∈ x.sets.Year) == x.model[:TotalTechnologyModelPeriodActivity][t,r], base_name="TAC1_TotalModelHorizenTechnologyActivity_$(t)_$(r)")
        if x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] < 999999
            @constraint(x.model, x.model[:TotalTechnologyModelPeriodActivity][t,r] <= x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t], base_name= "TAC2_TotalModelHorizenTechnologyActivityUpperLimit_$(t)_$(r)")
        end
        if x.params.TotalTechnologyModelPeriodActivityLowerLimit[r,t] > 0
            @constraint(x.model, x.model[:TotalTechnologyModelPeriodActivity][t,r] >= x.params.TotalTechnologyModelPeriodActivityLowerLimit[r,t], base_name= "TAC3_TotalModelHorizenTechnologyActivityLowerLimit_$(t)_$(r)")
        end
    end
end
    
############### Reserve Margin Constraint ############## NTS: Should change demand for production
function addConstraint_ReserveMargin(x) 
    for r ∈ x.sets.Region_full, y ∈ x.sets.Year, l ∈ x.sets.Timeslice
    @constraint(x.model,
    sum((x.model[:RateOfActivity][y,l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,y] * x.params.YearSplit[l,y] *x.params.ReserveMarginTagTechnology[r,t,y] * x.params.ReserveMarginTagFuel[r,f,y]) for f ∈ x.sets.Fuel for (t,m) ∈ x.other_params[:LoopSetOutput][(r,f,y)]) == x.model[:TotalActivityInReserveMargin][r,y,l],
    base_name="RM1_ReserveMargin_TechologiesIncluded_In_Activity_Units_$(y)_$(l)_$(r)")
    
    @constraint(x.model,
    sum((sum(x.model[:RateOfActivity][y,l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,y] for (t,m) ∈ x.other_params[:LoopSetOutput][(r,f,y)]) * x.params.YearSplit[l,y] *x.params.ReserveMarginTagFuel[r,f,y]) for f ∈ x.sets.Fuel) == x.model[:DemandNeedingReserveMargin][y,l,r],
    base_name="RM2_ReserveMargin_FuelsIncluded_$(y)_$(l)_$(r)")

    if x.params.ReserveMargin[r,y] > 0
        @constraint(x.model,
        x.model[:DemandNeedingReserveMargin][y,l,r] * x.params.ReserveMargin[r,y] <= x.model[:TotalActivityInReserveMargin][r,y,l],
        base_name="RM3_ReserveMargin_Constraint_$(y)_$(l)_$(r)")
    end
    end
end
    