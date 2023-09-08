

function addConstraint_TradeCapacity(x)

    for i ∈ 1:length(x.sets.Year), r ∈ x.sets.Region_full, rr ∈ x.sets.Region_full
        if x.params.TradeRoute[x.sets.Year[i],"Power",rr,r] > 0
        for l ∈ x.sets.Timeslice
            @constraint(x.model, (x.model[:Import][x.sets.Year[i],l,"Power",r,rr]) <= x.model[:TotalTradeCapacity][x.sets.Year[i],"Power",rr,r]*x.params.YearSplit[l,x.sets.Year[i]]*31.536 , base_name="TrC1_TradeCapacityPowerLinesImport_$(x.sets.Year[i])_$(l)_Power_$(r)_$(rr)")
        end
        end
        if x.params.TradeRoute[x.sets.Year[i],"Power",r,rr] > 0
        for l ∈ x.sets.Timeslice
            @constraint(x.model, (x.model[:Export][x.sets.Year[i],l,"Power",r,rr]) <= x.model[:TotalTradeCapacity][x.sets.Year[i],"Power",r,rr]*x.params.YearSplit[l,x.sets.Year[i]]*31.536 , base_name="TrC1_TradeCapacityPowerLinesExport_$(x.sets.Year[i])_$(l)_Power_$(r)_$(rr)")
        end
        @constraint(x.model, x.model[:NewTradeCapacity][x.sets.Year[i],"Power",r,rr]*x.params.TradeCapacityGrowthCosts["Power",r,rr]*x.params.TradeRoute[x.sets.Year[i],"Power",r,rr] == x.model[:NewTradeCapacityCosts][x.sets.Year[i],"Power",r,rr], base_name="TrC4_NewTradeCapacityCosts_$(x.sets.Year[i])_Power_$(r)_$(rr)")
        @constraint(x.model, x.model[:NewTradeCapacityCosts][x.sets.Year[i],"Power",r,rr]/((1+x.settings.GeneralDiscountRate[r])^(x.sets.Year[i]-x.switch.StartYear+0.5)) == x.model[:DiscountedNewTradeCapacityCosts][x.sets.Year[i],"Power",r,rr], base_name="TrC5_DiscountedNewTradeCapacityCosts_$(x.sets.Year[i])_Power_$(r)_$(rr)")
        end

        if x.switch.switch_dispatch == 0
        for f ∈ x.sets.Fuel
            if x.params.TradeRoute[x.sets.Year[i],f,r,rr] > 0
            if x.sets.Year[i] == x.switch.StartYear
                @constraint(x.model, x.model[:TotalTradeCapacity][x.sets.Year[i],f,r,rr] == x.params.TradeCapacity[x.sets.Year[i],f,r,rr], base_name="TrC2a_TotalTradeCapacity_$(x.sets.Year[i])_$(f)_$(r)_$(rr)")
            elseif x.sets.Year[i] > x.switch.StartYear
                @constraint(x.model, x.model[:TotalTradeCapacity][x.sets.Year[i],f,r,rr] == x.model[:TotalTradeCapacity][x.sets.Year[i-1],f,r,rr] + x.model[:NewTradeCapacity][x.sets.Year[i],f,r,rr] + x.params.AdditionalTradeCapacity[x.sets.Year[i],f,r,rr], 
                base_name="TrC2b_TotalTradeCapacity_$(x.sets.Year[i])_$(f)_$(r)_$(rr)")
            end

            if i > 1 && x.params.GrowthRateTradeCapacity[x.sets.Year[i],f,r,rr] > 0 && x.params.TradeRoute[x.sets.Year[i],f,r,rr] > 0
                @constraint(x.model, (x.params.GrowthRateTradeCapacity[x.sets.Year[i],f,r,rr]*YearlyDifferenceMultiplier(x.sets.Year[i],x.sets))*x.model[:TotalTradeCapacity][x.sets.Year[i-1],f,r,rr] >= x.model[:NewTradeCapacity][x.sets.Year[i],f,r,rr], 
                base_name="TrC3_NewTradeCapacityLimit_$(x.sets.Year[i])_$(f)_$(r)_$(rr)")
            end
            end
        end
        end

        if x.params.TradeRoute[x.sets.Year[i],"Power",r,rr] == 0 || x.params.GrowthRateTradeCapacity[x.sets.Year[i],"Power",r,rr] == 0
        JuMP.fix(x.model[:NewTradeCapacity][x.sets.Year[i],"Power",r,rr],0; force=true)
        end

        for f ∈ x.sets.Fuel
        if f != "Power"
            JuMP.fix(x.model[:NewTradeCapacity][x.sets.Year[i],f,r,rr],0; force=true)
        end
        if x.params.TradeRoute[x.sets.Year[i],f,r,rr] == 0 || f != "Power"
            JuMP.fix(x.model[:DiscountedNewTradeCapacityCosts][x.sets.Year[i],f,r,rr],0; force=true)
        end
        end
    end
end
function addConstraint_TradeCost(x)
    for y ∈ x.sets.Year, r ∈ x.sets.Region_full
        if sum(x.params.TradeRoute[y,f,r,rr] for f ∈ x.sets.Fuel for rr ∈ x.sets.Region_full) > 0
            @constraint(x.model, sum(x.model[:Import][y,l,f,r,rr] * x.params.TradeCosts[f,r,rr] for f ∈ x.sets.Fuel for rr ∈ x.sets.Region_full for l ∈ x.sets.Timeslice if x.params.TradeRoute[y,f,r,rr] > 0) == x.model[:AnnualTotalTradeCosts][y,r], base_name="Tc1_TradeCosts_$(y)_$(r)")
        else
            JuMP.fix(x.model[:AnnualTotalTradeCosts][y,r], 0; force=true)
        end
            @constraint(x.model, x.model[:AnnualTotalTradeCosts][y,r]/((1+x.settings.GeneralDiscountRate[r])^(y-x.switch.StartYear+0.5)) == x.model[:DiscountedAnnualTotalTradeCosts][y,r], base_name="Tc3_DiscountedAnnualTradeCosts_$(y)_$(r)")
    end 
end