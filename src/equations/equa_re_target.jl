
function is_output_production_possible(x, i, f, r, t)
    sum(x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation) > 0 &&
        x.params.AvailabilityFactor[r,t,x.sets.Year[i]] > 0 &&
        x.params.TotalAnnualMaxCapacity[r,t,x.sets.Year[i]] > 0 &&
        x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 &&
        (((JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)) ||
        ((!JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (!JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]))) ||
        ((JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.fix_value(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)))
end

function is_input_production_possible(x, i, f, r, t)
    sum(x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation) > 0 &&
        x.params.AvailabilityFactor[r,t,x.sets.Year[i]] > 0 &&
        x.params.TotalAnnualMaxCapacity[r,t,x.sets.Year[i]] > 0 &&
        x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 &&
        (((JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)) ||
        ((!JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (!JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]))) ||
        ((JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.fix_value(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)))
end

function addConstraint_REtarget1(x)
    for i ∈ eachindex(x.sets.Year), f ∈ x.sets.Fuel, r ∈ x.sets.Region_full, t ∈ x.sets.Technology
        if is_output_production_possible(x, i, f, r, t)
            @constraint(x.model, sum(sum(x.model[:RateOfActivity][x.sets.Year[i],l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation if x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]] != 0)* x.params.YearSplit[l,x.sets.Year[i]] for l ∈ x.sets.Timeslice) == x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r], base_name= "RE1_FuelProductionByTechnologyAnnual_$(x.sets.Year[i])_$(t)_$(f)_$(r)")
        else
            JuMP.fix(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r],0;force=true)
        end
    
        if is_input_production_possible(x, i, f, r, t)
            @constraint(x.model, sum(sum(x.model[:RateOfActivity][x.sets.Year[i],l,t,m,r]*x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation if x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] != 0)* x.params.YearSplit[l,x.sets.Year[i]] for l ∈ x.sets.Timeslice) == x.model[:UseByTechnologyAnnual][x.sets.Year[i],t,f,r], base_name= "RE5_FuelUseByTechnologyAnnual_$(x.sets.Year[i])_$(t)_$(f)_$(r)")
        else
            JuMP.fix(x.model[:UseByTechnologyAnnual][x.sets.Year[i],t,f,r],0;force=true)
        end
    end
end

function addConstraint_REtarget2(x)
    for i ∈ eachindex(x.sets.Year), f ∈ x.sets.Fuel, r ∈ x.sets.Region_full
        for t ∈ x.sets.Technology 
          if sum(x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation) > 0 &&
            x.params.AvailabilityFactor[r,t,x.sets.Year[i]] > 0 &&
            x.params.TotalAnnualMaxCapacity[r,t,x.sets.Year[i]] > 0 &&
            x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 &&
            (((JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)) ||
            ((!JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (!JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]))) ||
            ((JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.fix_value(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)))
            @constraint(x.model, sum(sum(x.model[:RateOfActivity][x.sets.Year[i],l,t,m,r]*x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation if x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] != 0)* x.params.YearSplit[l,x.sets.Year[i]] for l ∈ x.sets.Timeslice) == x.model[:UseByTechnologyAnnual][x.sets.Year[i],t,f,r], base_name= "RE5_FuelUseByTechnologyAnnual_$(x.sets.Year[i])_$(t)_$(f)_$(r)")
          else
            JuMP.fix(x.model[:UseByTechnologyAnnual][x.sets.Year[i],t,f,r],0;force=true)
          end
        end
    
      end
end

function addConstraint_REtarget3(x)
    for i ∈ eachindex(x.sets.Year), f ∈ x.sets.Fuel, r ∈ x.sets.Region_full
        @constraint(x.model,
            sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r] for t ∈ x.subsets.Renewables ) == x.model[:TotalREProductionAnnual][x.sets.Year[i],r,f],base_name="RE2_TechIncluded_$(x.sets.Year[i])_$(r)_$(f)")
    end
end

function addConstraint_REtarget4(x)
    for i ∈ eachindex(x.sets.Year), f ∈ x.sets.Fuel, r ∈ x.sets.Region_full
        @constraint(x.model,
            x.params.REMinProductionTarget[r,f,x.sets.Year[i]]*sum(x.model[:RateOfActivity][x.sets.Year[i],l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]]*x.params.YearSplit[l,x.sets.Year[i]] for l ∈ x.sets.Timeslice for t ∈ x.sets.Technology for m ∈ x.sets.Mode_of_operation if x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]] != 0 )*x.params.RETagFuel[r,f,x.sets.Year[i]] <= x.model[:TotalREProductionAnnual][x.sets.Year[i],r,f],
            base_name="RE4_EnergyConstraint_$(x.sets.Year[i])_$(r)_$(f)")
    end
end

function addConstraint_REtarget_switch_dispatch(x)
    for i ∈ eachindex(x.sets.Year), f ∈ x.sets.Fuel, r ∈ x.sets.Region_full
        if x.sets.Year[i]> x.switch.StartYear && x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i]]>0
            @constraint(x.model,
                x.model[:TotalREProductionAnnual][x.sets.Year[i],r,f] >= x.model[:TotalREProductionAnnual][x.sets.Year[i-1],r,f]*((x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i]]/x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i-1]])),
                base_name="RE6_RETargetPath_$(x.sets.Year[i])_$(r)_$(f)")
        end
    end
end

function addConstraint_REtarget5(x)
    for i ∈ 1:length(x.sets.Year), f ∈ x.sets.Fuel, r ∈ x.sets.Region_full, t ∈ x.sets.Technology 
      if sum(x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation) > 0 &&
        x.params.AvailabilityFactor[r,t,x.sets.Year[i]] > 0 &&
        x.params.TotalAnnualMaxCapacity[r,t,x.sets.Year[i]] > 0 &&
        x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 &&
        (((JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)) ||
        ((!JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (!JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]))) ||
        ((JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.fix_value(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)))
        @constraint(x.model, sum(sum(x.model[:RateOfActivity][x.sets.Year[i],l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation if x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]] != 0)* x.params.YearSplit[l,x.sets.Year[i]] for l ∈ x.sets.Timeslice) == x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r], base_name= "RE1_FuelProductionByTechnologyAnnual_$(x.sets.Year[i])_$(t)_$(f)_$(r)")
      else
        JuMP.fix(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r],0;force=true)
      end

      if sum(x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation) > 0 &&
        x.params.AvailabilityFactor[r,t,x.sets.Year[i]] > 0 &&
        x.params.TotalAnnualMaxCapacity[r,t,x.sets.Year[i]] > 0 &&
        x.params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] > 0 &&
        (((JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)) ||
        ((!JuMP.has_upper_bound(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (!JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]))) ||
        ((JuMP.is_fixed(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r])) && (JuMP.fix_value(x.model[:TotalCapacityAnnual][x.sets.Year[i],t,r]) > 0)))
        @constraint(x.model, sum(sum(x.model[:RateOfActivity][x.sets.Year[i],l,t,m,r]*x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] for m ∈ x.sets.Mode_of_operation if x.params.InputActivityRatio[r,t,f,m,x.sets.Year[i]] != 0)* x.params.YearSplit[l,x.sets.Year[i]] for l ∈ x.sets.Timeslice) == x.model[:UseByTechnologyAnnual][x.sets.Year[i],t,f,r], base_name= "RE5_FuelUseByTechnologyAnnual_$(x.sets.Year[i])_$(t)_$(f)_$(r)")
      else
        JuMP.fix(x.model[:UseByTechnologyAnnual][x.sets.Year[i],t,f,r],0;force=true)
      end
    end
end

function addConstraint_REtarget6(x)  
    for i ∈ 1:length(x.sets.Year), f ∈ x.sets.Fuel, r ∈ x.sets.Region_full
    
        @constraint(x.model,
        sum(x.model[:ProductionByTechnologyAnnual][x.sets.Year[i],t,f,r] for t ∈ x.subsets.Renewables ) == x.model[:TotalREProductionAnnual][x.sets.Year[i],r,f],base_name="RE2_TechIncluded_$(x.sets.Year[i])_$(r)_$(f)")

        @constraint(x.model,
        x.params.REMinProductionTarget[r,f,x.sets.Year[i]]*sum(x.model[:RateOfActivity][x.sets.Year[i],l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]]*x.params.YearSplit[l,x.sets.Year[i]] for l ∈ x.sets.Timeslice for t ∈ x.sets.Technology for m ∈ x.sets.Mode_of_operation if x.params.OutputActivityRatio[r,t,f,m,x.sets.Year[i]] != 0 )*x.params.RETagFuel[r,f,x.sets.Year[i]] <= x.model[:TotalREProductionAnnual][x.sets.Year[i],r,f],
        base_name="RE4_EnergyConstraint_$(x.sets.Year[i])_$(r)_$(f)")

        if x.switch.switch_dispatch == 0
            if x.sets.Year[i]> x.switch.StartYear && x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i]]>0
                @constraint(x.model,
                x.model[:TotalREProductionAnnual][x.sets.Year[i],r,f] >= x.model[:TotalREProductionAnnual][x.sets.Year[i-1],r,f]*((x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i]]/x.params.SpecifiedAnnualDemand[r,f,x.sets.Year[i-1]])),
                base_name="RE6_RETargetPath_$(x.sets.Year[i])_$(r)_$(f)")
            end
        end

    end
end