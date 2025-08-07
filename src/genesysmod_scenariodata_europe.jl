if "X_DAC_HT" ∈ Sets.Technology
    Params.AvailabilityFactor[:,"X_DAC_HT",:] .= 0
end
if "X_DAC_LT" ∈ Sets.Technology
    Params.AvailabilityFactor[:,"X_DAC_LT",:] .= 0
end

for r ∈ Sets.Region, t ∈ Sets.Technology, y ∈ Sets.Year
    if Params.TotalAnnualMaxCapacity[r,t,y] < Params.TotalAnnualMinCapacity[r,t,2025]
        println("TotalAnnualMaxCapacity[$r,$t,$y] is lower than TotalAnnualMinCapacity[$r,$t,2025], check the data! Setting the value to TotalAnnualMinCapacity[$r,$t,2025].")
        Params.TotalAnnualMaxCapacity[r,t,y] = Params.TotalAnnualMinCapacity[r,t,2025]
    end
end

# Limit capacity expansion in 2025 to only actually (historically) installed capacities
for r ∈ Sets.Region, t ∈ setdiff(Params.Tags.TagTechnologyToSubsets["PowerSupply"],"P_Nuclear")
    if  Params.TotalAnnualMinCapacity[r,t,2025] == 0
        @constraint(model, Vars.NewCapacity[2025,t,r] <= Params.TotalAnnualMaxCapacity[r,t,2025], base_name="ScenarioData_Europe_NewCapacity_2025_$(t)_$(r)") #Shouldn't that be fixed to 0?
    end
end
#NewCapacity.up("2025",t,r)$(TagTechnologyToSubsets(t,"PowerSupply") and not TotalAnnualMinCapacity(r,t,"2025") and not sameas(t,"P_Nuclear")) = TotalAnnualMinCapacity(r,t,"2025");

for r ∈ Sets.Region, y ∈ Sets.Year
    @constraint(model, Vars.ProductionByTechnologyAnnual[y,"CHP_WasteToEnergy","Heat_District",r] <= Params.RegionalBaseYearProduction[r,"CHP_WasteToEnergy","Heat_District","2018"], base_name="ScenarioData_Europe_CHP_WasdteToEnergy_Heat_District_$(r)_$(y)")
    for f ∈ Sets.Fuel
        Params.OutputActivityRatio[r,"CHP_WasteToEnergy",f,1,y] = 0
    end
    if y > 2018
        @constraint(model, Vars.ProductionByTechnologyAnnual[y,"HD_Heatpump_ExcessHeat","Heat_District",r] <= Params.SpecifiedAnnualDemand[r,"Heat_District",y]*0.08, base_name="ScenarioData_Europe_HD_Heatpump_ExcessHeat_Heat_District_$(r)_$(y)")
    end
end

for r ∈ Sets.Region, y ∈ Sets.Year
    tmp = copy(Params.SpecifiedAnnualDemand[r,"Heat_District",y])
    Params.SpecifiedAnnualDemand[r,"Heat_Buildings",y] = Params.SpecifiedAnnualDemand[r,"Heat_District",y]*0.85 + Params.SpecifiedAnnualDemand[r,"Heat_Buildings",y]
    Params.SpecifiedAnnualDemand[r,"Heat_District",y] = 0

    @constraint(model, sum(Params.RateOfActivity[y,l,t,m,r] * Params.OutputActivityRatio[r,"Heat_District",m,y] * Params.YearSplit[l,y] for l ∈ Sets.Timeslice for t ∈ Sets.Technology for m ∈ Sets.Mode_of_operation if Params.OutputActivityRatio[r,"Heat_District",m,y] != 0) >= tmp,
     base_name="ScenarioData_Europe_DistrictHeatLimit_$(r)_$(y)")

    @constraint(model, Vars.ProductionByTechnologyAnnual[y,"HLI_Geothermal","Heat_Low_Industrial",r] <= Params.SpecifiedAnnualDemand[r,"Heat_Low_Industrial",y]*0.25, base_name="ScenarioData_Europe_HLI_Geothermal_Heat_Low_Industrial_$(r)_$(y)")
end

if Switch.emissionPathway == "REPowerEU"
    for r ∈ Sets.Region, y ∈ Sets.Year
        @constraint(model, Vars.ProductionByTechnologyAnnual[y,"HHI_Scrap_EAF","Heat_High_Industrial",r] <= Params.SpecifiedAnnualDemand[r,"Heat_High_Industrial",y]*0.65, base_name="ScenarioData_Europe_HHI_Scrap_EAF_Heat_High_Industrial_$(r)_$(y)")
    end
    for f ∈ Sets.Fuel
        if y > 2025 && Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD",y] != 0
            Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD",y] = Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD","2025"] - 0.002*(y-2025)
            Params.ModalSplitByFuelAndModalType[r,f,"MT_FRT_ROAD",y] = Params.ModalSplitByFuelAndModalType[r,f,"MT_FRT_ROAD","2025"] - 0.002*(y-2025)
        end
    end
elseif Switch.emissionPathway == "NECPEssentials"
    for r ∈ Sets.Region, y ∈ Sets.Year
        @constraint(model, Vars.ProductionByTechnologyAnnual[y,"HHI_Scrap_EAF","Heat_High_Industrial",r] <= Params.SpecifiedAnnualDemand[r,"Heat_High_Industrial",y]*0.6, base_name="ScenarioData_Europe_HHI_Scrap_EAF_Heat_High_Industrial_$(r)_$(y)")
    end
    for f ∈ Sets.Fuel
        if y > 2025 && Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD",y] != 0
            Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD",y] = Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD","2025"] - 0.00175*(y-2025)
            Params.ModalSplitByFuelAndModalType[r,f,"MT_FRT_ROAD",y] = Params.ModalSplitByFuelAndModalType[r,f,"MT_FRT_ROAD","2025"] - 0.00175*(y-2025)
        end
    end
elseif Switch.emissionPathway == "Green"
    for r ∈ Sets.Region, y ∈ Sets.Year
        @constraint(model, Vars.ProductionByTechnologyAnnual[y,"HHI_Scrap_EAF","Heat_High_Industrial",r] <= Params.SpecifiedAnnualDemand[r,"Heat_High_Industrial",y]*0.75, base_name="ScenarioData_Europe_HHI_Scrap_EAF_Heat_High_Industrial_$(r)_$(y)")
    end
    for f ∈ Sets.Fuel
        if y > 2025 && Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD",y] != 0
            Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD",y] = Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD","2025"] - 0.00225*(y-2025)
            Params.ModalSplitByFuelAndModalType[r,f,"MT_FRT_ROAD",y] = Params.ModalSplitByFuelAndModalType[r,f,"MT_FRT_ROAD","2025"] - 0.00225*(y-2025)
        end
    end
elseif Switch.emissionPathway == "Trinity"
    for r ∈ Sets.Region, y ∈ Sets.Year
        @constraint(model, Vars.ProductionByTechnologyAnnual[y,"HHI_Scrap_EAF","Heat_High_Industrial",r] <= Params.SpecifiedAnnualDemand[r,"Heat_High_Industrial",y]*0.5, base_name="ScenarioData_Europe_HHI_Scrap_EAF_Heat_High_Industrial_$(r)_$(y)")
    end
    for f ∈ Sets.Fuel
        if y > 2025 && Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD",y] != 0
            Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD",y] = Params.ModalSplitByFuelAndModalType[r,f,"MT_PSNG_ROAD","2025"] - 0.001*(y-2025)
            Params.ModalSplitByFuelAndModalType[r,f,"MT_FRT_ROAD",y] = Params.ModalSplitByFuelAndModalType[r,f,"MT_FRT_ROAD","2025"] - 0.001*(y-2025)
        end
    end
end
