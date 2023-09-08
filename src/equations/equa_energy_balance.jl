
function addConstraint_EnergyBalanceA1(x)
    for y ∈ x.sets.Year, f ∈ x.sets.Fuel, r ∈ x.sets.Region_full
        for rr ∈ x.sets.Region_full
        if x.params.TradeRoute[y,f,r,rr] > 0
            for l ∈ x.sets.Timeslice
            @constraint(x.model, x.model[:Import][y,l,f,r,rr] == x.model[:Export][y,l,f,rr,r], base_name="EBa10_EnergyBalanceEachTS4_$(y)_$(l)_$(f)_$(r)_$(rr)")
            end
        else
            for l ∈ x.sets.Timeslice
            JuMP.fix(x.model[:Import][y,l,f,r,rr], 0; force=true)
            JuMP.fix(x.model[:Export][y,l,f,rr,r], 0; force=true)
            end
        end
        end

        if sum(x.params.TradeRoute[y,f,r,rr] for rr ∈ x.sets.Region_full) == 0
        JuMP.fix.(x.model[:NetTrade][y,:,f,r], 0; force=true)
        else
        for l ∈ x.sets.Timeslice
            @constraint(x.model, sum(x.model[:Export][y,l,f,r,rr]*(1+x.params.TradeLossBetweenRegions[y,f,r,rr]) - x.model[:Import][y,l,f,r,rr] for rr ∈ x.sets.Region_full if x.params.TradeRoute[y,f,r,rr] > 0) == x.model[:NetTrade][y,l,f,r], 
            base_name="EBa12_NetTradeBalance_$(y)_$(l)_$(f)_$(r)")
        end
        end

        if x.other_params[:IgnoreFuel][y,f,r] == 0
            for l ∈ x.sets.Timeslice
                @constraint(x.model,sum(x.model[:RateOfActivity][y,l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,y] for (t,m) ∈ x.other_params[:LoopSetOutput][(r,f,y)])* x.params.YearSplit[l,y] ==
            (x.params.Demand[y,l,f,r] + sum(x.model[:RateOfActivity][y,l,t,m,r]*x.params.InputActivityRatio[r,t,f,m,y] for (t,m) ∈ x.other_params[:LoopSetInput][(r,f,y)])*x.params.YearSplit[l,y] + x.model[:NetTrade][y,l,f,r] + x.model[:Curtailment][y,l,f,r]),
                base_name="EBa11_EnergyBalanceEachTS5_$(y)_$(l)_$(f)_$(r)")
            end
        end
    end
end

function addConstraint_EnergyBalanceA2(x)
    for y ∈ x.sets.Year, f ∈ x.sets.Fuel, r ∈ x.sets.Region_full
        if any(x->x>0, [JuMP.has_upper_bound(x.model[:Curtailment][y,l,f,r]) ? JuMP.upper_bound(x.model[:Curtailment][y,l,f,r]) : ((JuMP.is_fixed(x.model[:Curtailment][y,l,f,r])) && (JuMP.fix_value(x.model[:Curtailment][y,l,f,r]) == 0)) ? 0 : 999999 for l ∈ x.sets.Timeslice])
            @constraint(x.model, x.model[:CurtailmentAnnual][y,f,r] == sum(x.model[:Curtailment][y,l,f,r] for l ∈ x.sets.Timeslice), base_name="EBa13_CurtailmentAnnual_$(y)_$(f)_$(r)")
        else
            JuMP.fix(x.model[:CurtailmentAnnual][y,f,r],0; force=true)
        end

        if x.params.SelfSufficiency[y,f,r] != 0
            @constraint(x.model, sum(x.x.model[:RateOfActivity][y,l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,y]*x.params.YearSplit[l,y] for l ∈ x.sets.Timeslice for (t,m) ∈ x.other_params[:LoopSetOutput][(r,f,y)]) == (x.params.SpecifiedAnnualDemand[r,f,y] + sum(x.model[:RateOfActivity][y,l,t,m,r]*x.params.InputActivityRatio[r,t,f,m,y]*x.params.YearSplit[l,y] for l ∈ x.sets.Timeslice for (t,m) ∈ x.other_params[:LoopSetInput][(r,f,y)]))*x.params.SelfSufficiency[y,f,r], base_name="EBa14_SelfSufficiency_$(y)_$(f)_$(r)")
        end
    end
end

function addConstraint_EnergyBalanceB(x)
    for y ∈ x.sets.Year, f ∈ x.sets.Fuel, r ∈ x.sets.Region_full
        if sum(x.params.TradeRoute[y,f,r,rr] for rr ∈ x.sets.Region_full) > 0
        @constraint(x.model, sum(x.model[:NetTrade][y,l,f,r] for l ∈ x.sets.Timeslice) == x.model[:NetTradeAnnual][y,f,r], base_name="EBb3_EnergyBalanceEachYear3_$(y)_$(f)_$(r)")
        else
        JuMP.fix(x.model[:NetTradeAnnual][y,f,r],0; force=true)
        end
    
        @constraint(x.model, sum(x.model[:RateOfActivity][y,l,t,m,r]*x.params.OutputActivityRatio[r,t,f,m,y]*x.params.YearSplit[l,y] for l ∈ x.sets.Timeslice for (t,m) ∈ x.other_params[:LoopSetOutput][(r,f,y)]) >= 
        sum( x.model[:RateOfActivity][y,l,t,m,r]*x.params.InputActivityRatio[r,t,f,m,y]*x.params.YearSplit[l,y] for l ∈ x.sets.Timeslice for (t,m) ∈ x.other_params[:LoopSetInput][(r,f,y)]) + x.model[:NetTradeAnnual][y,f,r], 
        base_name="EBb4_EnergyBalanceEachYear4_$(y)_$(f)_$(r)")
    end
end