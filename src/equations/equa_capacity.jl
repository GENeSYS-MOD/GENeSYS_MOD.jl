
function addConstraint_capacity(x)
    for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full
        if (x.params.TotalAnnualMaxCapacity[r,t,y] < 999999) && (x.params.TotalAnnualMaxCapacity[r,t,y] > 0)
          @constraint(x.model, x.model[:TotalCapacityAnnual][y,t,r] <= x.params.TotalAnnualMaxCapacity[r,t,y], base_name="TCC1_TotalAnnualMaxCapacityConstraint_$(y)_$(t)_$(r)")
        elseif x.params.TotalAnnualMaxCapacity[r,t,y] == 0
          JuMP.fix(x.model[:TotalCapacityAnnual][y,t,r],0; force=true)
        end
    
        if x.params.TotalAnnualMinCapacity[r,t,y]>0
          @constraint(x.model, x.model[:TotalCapacityAnnual][y,t,r] >= x.params.TotalAnnualMinCapacity[r,t,y], base_name="TCC2_TotalAnnualMinCapacityConstraint_$(y)_$(t)_$(r)")
        end
    end
end


function addConstraint_newcapacity(x)
    for y ∈ x.sets.Year, t ∈ x.sets.Technology, r ∈ x.sets.Region_full
        if x.params.TotalAnnualMaxCapacityInvestment[r,t,y] < 999999
            @constraint(x.model,
            x.model[:NewCapacity][y,t,r] <= x.params.TotalAnnualMaxCapacityInvestment[r,t,y], base_name="NCC1_TotalAnnualMaxNewCapacityConstraint_$(y)_$(t)_$(r)")
        end
        if x.params.TotalAnnualMinCapacityInvestment[r,t,y] > 0
            @constraint(x.model,
            x.model[:NewCapacity][y,t,r] >= x.params.TotalAnnualMinCapacityInvestment[r,t,y], base_name="NCC2_TotalAnnualMinNewCapacityConstraint_$(y)_$(t)_$(r)")
        end
    end
end