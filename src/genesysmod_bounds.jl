# GENeSYS-MOD v3.1 [Global Energy System Model]  ~ March 2022
#
# #############################################################
#
# Copyright 2020 Technische Universität Berlin and DIW Berlin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# #############################################################
"""
Internal function used in the run process to modify batches of input data.
"""
function genesysmod_bounds(model,Sets,Params, Vars,Settings,Switch,Maps)

    #
    # ####### Default Values #############
    #

    end_uses = union(["Power"], Params.Tags.TagFuelToSubsets["HeatFuels"], Params.Tags.TagFuelToSubsets["TransportFuels"])
    sub = union(["Power"], Params.Tags.TagFuelToSubsets["HeatFuels"], Params.Tags.TagFuelToSubsets["TransportFuels"])

    for r ∈ Sets.Region_full for y ∈ Sets.Year
        for t ∈ intersect(Sets.Technology,Params.Tags.TagTechnologyToSubsets["Renewables"])
            Params.Tags.RETagTechnology[r,t,y] = 1
        end
        for f ∈ intersect(Sets.Fuel,sub)
            Params.Tags.RETagFuel[r,f,y] = 1
        end
    end end

    #
    # ####### Default Values #############
    #

    for r ∈ Sets.Region_full
        for t ∈ Sets.Technology
            for y ∈ Sets.Year
                if Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] == 0
                        Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] = 999999
                end
            end
        end
    end

#=     for r ∈ Sets.Region_full
        for t ∈ Sets.Technology
            Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] = 999999
    end end  =#

    for r ∈ Sets.Region_full
        for t ∈ setdiff(Params.Tags.TagTechnologyToSubsets["FossilFuelGeneration"],["R_Nuclear"])
            if Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] == 999999
                Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] = 0
            end
    end end

    f="ETS"
    for r ∈ Sets.Region_full
        for rr ∈ Sets.Region_full
            if Params.TradeCosts[f,r,rr] == 0
                Params.TradeCosts[f,r,rr] = 0.01
    end end end

    for r ∈ Sets.Region_full
        for t ∈ Sets.Technology
            for m ∈ Sets.Mode_of_operation
                for y ∈ Sets.Year
                    if Params.VariableCost[r,t,m,y]==0
                        Params.VariableCost[r,t,m,y] = 0.01
    end end end end end

    #
    # ####### Dummy-Technologies [enable for test purposes, if model runs infeasible] #############
    #

    if Switch.switch_infeasibility_tech == 1
        Params.Tags.TagTechnologyToSector[Params.Tags.TagTechnologyToSubsets["DummyTechnology"],"Infeasibility"] .= 1
        Params.AvailabilityFactor[:,Params.Tags.TagTechnologyToSubsets["DummyTechnology"],:] .= 0

        for end_use ∈ end_uses
            Params.OutputActivityRatio[:,"Infeasibility_$(end_use)",end_use,1,:] .= 1
        end

        Params.CapacityToActivityUnit[Params.Tags.TagTechnologyToSubsets["DummyTechnology"]] .= 31.56
        Params.TotalAnnualMaxCapacity[:,Params.Tags.TagTechnologyToSubsets["DummyTechnology"],:] .= 999999
        Params.FixedCost[:,Params.Tags.TagTechnologyToSubsets["DummyTechnology"],:] .= 999
        Params.CapitalCost[:,Params.Tags.TagTechnologyToSubsets["DummyTechnology"],:] .= 999
        Params.VariableCost[:,Params.Tags.TagTechnologyToSubsets["DummyTechnology"],:,:] .= 999
        Params.AvailabilityFactor[:,Params.Tags.TagTechnologyToSubsets["DummyTechnology"],:] .= 1
        Params.CapacityFactor[:,Params.Tags.TagTechnologyToSubsets["DummyTechnology"],:,:] .= 1
        Params.OperationalLife[Params.Tags.TagTechnologyToSubsets["DummyTechnology"]] .= 1
        Params.EmissionActivityRatio[:,Params.Tags.TagTechnologyToSubsets["DummyTechnology"],:,:,:] .= 0

    end

    #
    # ####### Bounds for non-supply technologies #############
    #

    for r ∈ Sets.Region_full
        for t ∈ Sets.Technology
            if t ∈ vcat(Params.Tags.TagTechnologyToSubsets["Transformation"],Params.Tags.TagTechnologyToSubsets["FossilPower"],Params.Tags.TagTechnologyToSubsets["FossilFuelGeneration"],
                Params.Tags.TagTechnologyToSubsets["CHP"],Params.Tags.TagTechnologyToSubsets["Transport"],Params.Tags.TagTechnologyToSubsets["ImportTechnology"],Params.Tags.TagTechnologyToSubsets["Biomass"],"P_Biomass")
                for y ∈ Sets.Year
                    Params.TotalAnnualMaxCapacity[r,t,y] = 999999
                end
            end
    end end

    for r ∈ Sets.Region_full
        for t ∈ Params.Tags.TagTechnologyToSubsets["ImportTechnology"]
            for y ∈ Sets.Year
                Params.AvailabilityFactor[r,t,y] = 1
    end end end

    for r ∈ Sets.Region_full
        for t ∈ Sets.Technology
            if t ∈ Params.Tags.TagTechnologyToSubsets["ImportTechnology"]
                for l ∈ Sets.Timeslice
                    for y ∈ Sets.Year
                        Params.CapacityFactor[r,t,l,y] = 1
                end end
    end end end

    for r ∈ Sets.Region_full
        for t ∈ Params.Tags.TagTechnologyToSubsets["ImportTechnology"]
                Params.OperationalLife[t] = 1
        end
    end

    for r ∈ Sets.Region_full
        for t ∈ Params.Tags.TagTechnologyToSubsets["ImportTechnology"]
            Params.TotalTechnologyModelPeriodActivityUpperLimit[r,t] = 999999
    end end

    #
    # ####### Bounds for storage technologies #############
    #


    #
    # ####### Capacity factor for heat technologies #############
    #
    # TO DO: ask konstantin for reason behind this and possibility to simplify
    #CapacityFactor(r,Heat,l,y)$(sum(ll,CapacityFactor(r,Heat,ll,y)) = 0) = 1;
    #Params.CapacityFactor[[x ∈ Subsets.Heat for x ∈ Params.CapacityFactor[!,:Technology]], :Value] .= 1

    for r ∈ Sets.Region_full, l ∈ Sets.Timeslice, y ∈ Sets.Year, t ∈ intersect(Sets.Technology, ["HLI_Solar_Thermal", "HLR_Solar_Thermal", "HB_Solar_Thermal", "RES_PV_Rooftop_Residential", "P_PV_Rooftop_Residential"]) # TODO remove when data redundant
        if "RES_PV_Rooftop_Commercial" in Sets.Technology # TODO remove when data redundant
            Params.CapacityFactor[r,t,l,y] = Params.CapacityFactor[r,"RES_PV_Rooftop_Commercial",l,y]
        end
        if "P_PV_Rooftop_Commercial" in Sets.Technology 
            Params.CapacityFactor[r,t,l,y] = Params.CapacityFactor[r,"P_PV_Rooftop_Commercial",l,y]
        end
    end
    #
    # ####### No new capacity construction in 2015 #############
    #
    if Switch.switch_dispatch == 0
        for r ∈ Sets.Region_full
            for t ∈ intersect(Sets.Technology, vcat(Params.Tags.TagTechnologyToSubsets["Transformation"],Params.Tags.TagTechnologyToSubsets["PowerSupply"], Params.Tags.TagTechnologyToSubsets["SectorCoupling"], Params.Tags.TagTechnologyToSubsets["StorageDummies"]))
                JuMP.fix(Vars.NewCapacity[Switch.StartYear,t,r],0; force=true)
            end
            for t ∈ intersect(Sets.Technology, vcat(Params.Tags.TagTechnologyToSubsets["Biomass"],Params.Tags.TagTechnologyToSubsets["CHP"],["HLR_Gas_Boiler","HB_Gas_Boiler","HLI_Gas_Boiler","HHI_BF_BOF",
                "HHI_Bio_BF_BOF","HHI_Scrap_EAF","HHI_DRI_EAF", "D_Gas_Methane"])) # TODO remove when data redundant
                if JuMP.is_fixed(Vars.NewCapacity[Switch.StartYear,t,r])
                    JuMP.unfix(Vars.NewCapacity[Switch.StartYear,t,r])
                end
            end
        end

        if "CHP" ∈ Sets.Sector
            for t ∈ Sets.Technology
                if Params.Tags.TagTechnologyToSector[t,"CHP"] == 1
                    for r ∈ Sets.Region_full
                        if JuMP.is_fixed(model[:NewCapacity][Switch.StartYear,t,r])
                            JuMP.unfix(model[:NewCapacity][Switch.StartYear,t,r])
                        end
                    end
                end
            end
        end
    end


    ### ReserveMargin initialization

    for r ∈ Sets.Region_full for t ∈ Sets.Technology for y ∈ Sets.Year
        if ((max(Params.TotalAnnualMaxCapacity[r,t,y], Params.ResidualCapacity[r,t,y]) >0 )
            && (max(Params.TotalAnnualMaxCapacity[r,t,y], Params.ResidualCapacity[r,t,y]) < 999999))
            Params.TotalAnnualMaxCapacity[r,t,y] = max(Params.TotalAnnualMaxCapacity[r,t,y], Params.ResidualCapacity[r,t,y])
        end
    end end end

    ### Adds (negligible) variable costs to transport technologies, since they only had fuel costs before
    ### This is to combat strange "curtailment" effects of some transportation technologies
    for r ∈ Sets.Region_full for t ∈ intersect(Sets.Technology, Params.Tags.TagTechnologyToSubsets["Transport"])
        Params.VariableCost[r,t,:,:] .= 0.09
    end end

    #
    # ####### Dispatch and Curtailment #############
    #
    subs = vcat(intersect(Sets.Technology, Params.Tags.TagTechnologyToSubsets["Solar"]), intersect(Sets.Technology, Params.Tags.TagTechnologyToSubsets["Wind"]))
    if "RES_Hydro_Small" in Sets.Technology # TODO remove when data redundant
        subs = vcat(subs, ["RES_Hydro_Small"])
    end
    if "P_Hydro_RoR" in Sets.Technology
        subs = vcat(subs, ["P_Hydro_RoR"])
    end
    Params.Tags.TagDispatchableTechnology[subs] = zeros(length(intersect(Sets.Technology,subs)))
    Params.CurtailmentCostFactor == 0.1

    for r ∈ Sets.Region_full, t ∈ intersect(Sets.Technology,Params.Tags.TagTechnologyToSubsets["Solar"])
        Params.AvailabilityFactor[r,t,:] .= 1
    end

    for e ∈ Sets.Emission for s ∈ Sets.Sector for y ∈ Sets.Year
        if Params.AnnualSectoralEmissionLimit[e,s,y] == 0
            Params.AnnualSectoralEmissionLimit[e,s,y] = 999999
        end
    end end end

    #
    # ####### CCS #############
    #

    if Switch.switch_ccs == 1
        for r ∈ Sets.Region_full for t ∈ intersect(Sets.Technology, Params.Tags.TagTechnologyToSubsets["CCS"])
            Params.AvailabilityFactor[r,t,:] .= 0
            Params.TotalAnnualMaxCapacity[r,t,:] .= 99999
            Params.TotalTechnologyAnnualActivityUpperLimit[r,t,:] .= 99999
        end end

        for y ∈ Sets.Year for r ∈ Sets.Region_full
            if (y > 2020) && (Params.RegionalCCSLimit[r] > 0)
                for t ∈ intersect(Sets.Technology, Params.Tags.TagTechnologyToSubsets["CCS"])
                    Params.AvailabilityFactor[r,t,y] = 0.95
                end
            else
                for t ∈ intersect(Sets.Technology, Params.Tags.TagTechnologyToSubsets["CCS"])
                    Params.TotalAnnualMaxCapacity[r,t,y] = 0
                    Params.TotalTechnologyAnnualActivityUpperLimit[r,t,y] = 0
                    for f ∈ Maps.Tech_Fuel[t]
                        JuMP.fix(Vars.ProductionByTechnologyAnnual[y,t,f,r],0; force=true)
                    end
                end
            end
        end end

        Params.TotalAnnualMaxCapacity[Sets.Region_full,"A_Air",:] .= 99999
        Params.TotalTechnologyAnnualActivityUpperLimit[Sets.Region_full,"A_Air",:] .= 99999

        for t ∈ intersect(Sets.Technology, ["X_DAC_HT","X_DAC_LT"])
            Params.EmissionActivityRatio[Sets.Region_full,t,:,:,:] .= -1
        end

    else
        for y ∈ Sets.Year for r ∈ Sets.Region_full for t ∈ intersect(Sets.Technology, Params.Tags.TagTechnologyToSubsets["CCS"])
            Params.AvailabilityFactor[r,t,y] = 0
            Params.TotalAnnualMaxCapacity[r,t,y] = 0
            for f ∈ Maps.Tech_Fuel[t]
                JuMP.fix(Vars.ProductionByTechnologyAnnual[y,t,f,r], 0; force = true)
            end
        end end end
    end


    #
    # ####### Ramping #############
    #
    #$ontext
    if Switch.switch_ramping == 1
        for r ∈ Sets.Region_full for y ∈ Sets.Year
#=             Params.RampingUpFactor["RES_Hydro_Large",y] = 0.25
            Params.RampingUpFactor["P_Nuclear",y] = 0.01
            Params.RampingDownFactor["RES_Hydro_Large",y] = 0.25
            Params.RampingDownFactor["P_Nuclear",y] = 0.01
            Params.ProductionChangeCost[r,"RES_Hydro_Large",y] = 50/3.6
            Params.ProductionChangeCost[r,"P_Nuclear",y] = 200/3.6
            for t ∈ Params.Tags.TagTechnologyToSubsets["PowerBiomass"]
                Params.RampingUpFactor[t,y] = 0.04
                Params.RampingDownFactor[t,y] = 0.04
                Params.ProductionChangeCost[r,t,y] = 100/3.6
            end
            for t ∈ Params.Tags.TagTechnologyToSubsets["FossilPower"]
                Params.RampingUpFactor[t,y] = 0.04
                Params.RampingDownFactor[t,y] = 0.04
                Params.ProductionChangeCost[r,t,y] = 100/3.6
            end
            for t ∈ Params.Tags.TagTechnologyToSubsets["Coal"]
                Params.RampingUpFactor[t,y] = 0.02
                Params.RampingDownFactor[t,y] = 0.02
                Params.ProductionChangeCost[r,t,y] = 50/3.6
            end
            for t ∈ Params.Tags.TagTechnologyToSubsets["Gas"]
                Params.RampingUpFactor[t,y] = 0.2
                Params.RampingDownFactor[t,y] = 0.2
                Params.ProductionChangeCost[r,t,y] = 20/3.6
            end
            for t ∈ Params.Tags.TagTechnologyToSubsets["HeatSlowRamper"]
                Params.RampingUpFactor[t,y] = 0.1
                Params.RampingDownFactor[t,y] = 0.1
                Params.ProductionChangeCost[r,t,y] = 100/3.6
            end
            for t ∈ Params.Tags.TagTechnologyToSubsets["HeatQuickRamper"]
                Params.RampingUpFactor[t,y] = 0
                Params.RampingDownFactor[t,y] = 0
                Params.ProductionChangeCost[r,t,y] = 0
            end =#
            if "RES_Hydro_Large" in Sets.Technology && "RES_Hydro_Small" in Sets.Technology # TODO remove when data redundant
                for l ∈ Sets.Timeslice
                    Params.MinActiveProductionPerTimeslice[y,l,"Power","RES_Hydro_Large",r] = 0.1
                    Params.MinActiveProductionPerTimeslice[y,l,"Power","RES_Hydro_Small",r] = 0.05
                end
            end
            if "P_Hydro_Reservoir" in Sets.Technology && "P_Hydro_RoR" in Sets.Technology
                for l ∈ Sets.Timeslice
                    Params.MinActiveProductionPerTimeslice[y,l,"Power","P_Hydro_Reservoir",r] = 0.1
                    Params.MinActiveProductionPerTimeslice[y,l,"Power","P_Hydro_RoR",r] = 0.05
                end
            end
        end end
    end

    #marginal costs for better numerical stability
    for r ∈ Sets.Region_full for t ∈ Sets.Technology for y ∈ Sets.Year
        if Params.CapitalCost[r,t,y] == 0
            Params.CapitalCost[r,t,y] = 0.01
        end
    end end end


    for r ∈ Sets.Region_full for i ∈ 1:length(Sets.Timeslice) for y ∈ Sets.Year
        if Switch.switch_dispatch==0
            for s in intersect(Sets.Storage, ["S_Battery_Li-Ion","S_Battery_Redox","S_Heat_HLR","S_HB_Tank_Small", "S_Heat_HLI"])
                if (i-1 + Switch.elmod_starthour/Switch.elmod_hourstep) % (24/Switch.elmod_hourstep) == 0
                    JuMP.fix(Vars.StorageLevelTSStart[s,y,Sets.Timeslice[i],r], 0; force = true)
                end
            end
        end
        if "RES_CSP" ∈ Sets.Technology #TODO remove when data redundant
            try
                Params.CapacityFactor[r,"RES_CSP",Sets.Timeslice[i],y] = Params.CapacityFactor[r,"RES_PV_Utility_Opt",Sets.Timeslice[i],y]
            catch e
                if isa(e, KeyError)
                    Params.CapacityFactor[r,"RES_CSP",Sets.Timeslice[i],y] = Params.CapacityFactor[r,"RES_PV_Utility_Avg",Sets.Timeslice[i],y]
                end
            end
        end
        if "P_CSP" ∈ Sets.Technology
            try
                Params.CapacityFactor[r,"P_CSP",Sets.Timeslice[i],y] = Params.CapacityFactor[r,"P_PV_Utility_Opt",Sets.Timeslice[i],y]
            catch e
                if isa(e, KeyError)
                    Params.CapacityFactor[r,"P_CSP",Sets.Timeslice[i],y] = Params.CapacityFactor[r,"P_PV_Utility_Avg",Sets.Timeslice[i],y]
                end
            end
        end

        for t ∈ intersect(Sets.Technology, ["HLI_Solar_Thermal", "HLR_Solar_Thermal", "HB_Solar_Thermal", "RES_PV_Rooftop_Commercial", "RES_PV_Rooftop_Residential", "P_PV_Rooftop_Commercial", "P_PV_Rooftop_Residential"]) # TODO remove when data redundant
            if "RES_PV_Utility_Avg" in Sets.Technology # TODO remove when data redundant
                Params.CapacityFactor[r,t,Sets.Timeslice[i],y] = Params.CapacityFactor[r,"RES_PV_Utility_Avg",Sets.Timeslice[i],y]
            end
            if "P_PV_Utility_Avg" in Sets.Technology
                Params.CapacityFactor[r,t,Sets.Timeslice[i],y] = Params.CapacityFactor[r,"P_PV_Utility_Avg",Sets.Timeslice[i],y]
            end
        end
    end end end

    #for r ∈ Sets.Region_full for s in Sets.Storage for y ∈ Sets.Year
        #Params.CapitalCostStorage[r,s,y] = CapitalCostStorage[r,s,y]/365*8760/Switch.elmod_nthhour/(24/Switch.elmod_hourstep)

        #@constraint(model, Vars.StorageUpperLimit[s,y,r] <= sum(Params.TotalCapacityAnnual[y,t,r] * Partams.StorageE2PRatio[s] * 0.0036 * 3 for t in Sets.Technology for m in Sets.Mode_of_operation if Params.TechnologyToStorage[t,s,m,y] != 0),
        #base_name="Add_E2PRatio_up|$(s)|$(y)|$(r)")
        #@constraint(model, Vars.StorageUpperLimit[s,y,r] >= sum(Params.TotalCapacityAnnual[y,t,r] * Partams.StorageE2PRatio[s] * 0.0036 * 0.5 for t in Sets.Technology for m in Sets.Mode_of_operation if Params.TechnologyToStorage[t,s,m,y] != 0),
        #base_name="Add_E2PRatio_low|$(s)|$(y)|$(r)")
end

function YearlyDifferenceMultiplier(y,Sets);
    i = findfirst(Sets.Year.== y)
    if i < length(Sets.Year)
        return max(1,Sets.Year[i+1]-Sets.Year[i])
    else
        return 1
    end
end
