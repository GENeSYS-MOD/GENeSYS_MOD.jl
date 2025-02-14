if Params.TradeRoute[r,rr,"H2",𝓨[i]] > 0 # export region r, import region rr, power is fuel, y is year. 
    for l ∈ 𝓛 #for timeslice l in 𝓛
      @constraint(model, (Vars.Import[𝓨[i],l,"H2",r,rr]) <= Vars.TotalTradeCapacity[𝓨[i],"H2",rr,r]*Params.YearSplit[l,𝓨[i]]*31.536 , base_name="TrC1_TradeCapacityH2LinesImport|$(𝓨[i])|$(l)_H2|$(r)|$(rr)") #Constraint that the import quantity in year Y, for fuel “H2”, for the import region to the export region must be lower or equal to  the total trade capacity 
    end
end


if Params.TradeCapacityGrowthCosts[r,rr,f] > 0 && f != "H2"
    @constraint(model, sum(Vars.Import[𝓨[i],l,f,rr,r] for l ∈ 𝓛) <= Vars.TotalTradeCapacity[𝓨[i],f,r,rr],
    base_name="TrC7_TradeCapacityLimitNonH2$(𝓨[i])|$(f)|$(r)|$(rr)")
end

if Params.TradeRoute[r,rr,"H2",𝓨[i]] > 0 
    @constraint(model, Vars.NewTradeCapacity[𝓨[i],"H2",r,rr] >= Vars.NewTradeCapacity[𝓨[i],"H2",rr,r] * Switch.set_symmetric_transmission,
    base_name="TrC6_SymmetricalTransmissionExpansion|$(𝓨[i])|$(r)|$(rr)")
end


if Params.TradeRoute[r,rr,"H2",𝓨[i]] == 0 || Params.GrowthRateTradeCapacity[r,rr,"H2",𝓨[i]] == 0 || i==1 
    JuMP.fix(Vars.NewTradeCapacity[𝓨[i],"H2",r,rr],0; force=true)
end

