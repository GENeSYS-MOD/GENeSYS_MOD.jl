# GENeSYS-MOD v3.1 [Global Energy System Model]  ~ March 2022
#
# #############################################################
#
# Copyright 2020 Technische Universität Berlin and DIW Berlin
#
# Licensed under the Apache License, Version 2.0 (the "License")
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
Internal function used in the run process after reading the input data to reduce the hourly
timeseries for the whole year to a given number of timeslices. The algorithm maintain the max
and min value and also fit the new timeserie to minimise deviation from the mean of the original timeseire.
"""
function create_daa_hourly(in_data, tab_name, els...)
    df = DataFrame(XLSX.gettable(in_data[tab_name]))
    long_df = stack(df,3:ncol(df)) # 3 because data starts at column 3, 1 is the hours and 2 is the timeslice

    select!(long_df, Not(:TIMESLICE)) #remove the timeslice column

    A = JuMP.Containers.DenseAxisArray(
        zeros(length.(els)...), els...)
    # Fill in values from Excel
    for r in eachrow(long_df)
        try
            A[r[1:end-1]...] = r.value 
        catch err
            @debug err
        end
    end
    return A
end

"""

"""
function create_df_hourly(in_data, tab_name)
    df = DataFrame(XLSX.gettable(in_data[tab_name]))
    long_df = stack(df,3:ncol(df)) # 3 because data starts at column 3, 1 is the hours and 2 is the timeslice

    select!(long_df, Not(:TIMESLICE)) #remove the timeslice column

    return long_df
end

"""

"""
function timeseries_reduction!(Params, Sets, Switch)

    switch_dunkelflaute = Switch.elmod_dunkelflaute

    Country_Data_Entries=[
    "LOAD",
    "PV_AVG", "PV_INF", "PV_OPT",
    "WIND_ONSHORE_AVG", "WIND_ONSHORE_INF", "WIND_ONSHORE_OPT",
    "WIND_OFFSHORE","WIND_OFFSHORE_SHALLOW","WIND_OFFSHORE_DEEP",
    "MOBILITY_PSNG",
    "HEAT_LOW", "HEAT_HIGH",
    "HEAT_PUMP_AIR", "HEAT_PUMP_GROUND","HYDRO_ROR","PV_TRACKING"]

    sector_to_tech = Dict(
        "Industry"=>"HEAT_HIGH",
        "Buildings"=>"HEAT_LOW",
        "Transportation"=>"MOBILITY_PSNG",
        "Power"=>"LOAD")

    Timeslice_Full = 1:8760

    CountryData = Dict()

    hourly_data = XLSX.readxlsx(joinpath(Switch.inputdir, Switch.hourly_data_file * ".xlsx"))

    CountryData_Load = DataFrame(XLSX.gettable(hourly_data["TS_LOAD"]))
    CountryData_PV_Avg = DataFrame(XLSX.gettable(hourly_data["TS_PV_AVG"]))
    CountryData_PV_Inf = DataFrame(XLSX.gettable(hourly_data["TS_PV_INF"]))
    CountryData_PV_Opt = DataFrame(XLSX.gettable(hourly_data["TS_PV_OPT"]))
    CountryData_PV_tracking = DataFrame(XLSX.gettable(hourly_data["TS_PV_TRA"]))
    CountryData_Wind_Onshore_Avg = DataFrame(XLSX.gettable(hourly_data["TS_WIND_ONSHORE_AVG"]))
    CountryData_Wind_Onshore_Inf = DataFrame(XLSX.gettable(hourly_data["TS_WIND_ONSHORE_INF"]))
    CountryData_Wind_Onshore_Opt = DataFrame(XLSX.gettable(hourly_data["TS_WIND_ONSHORE_OPT"]))
    CountryData_Wind_Offshore = DataFrame(XLSX.gettable(hourly_data["TS_WIND_OFFSHORE"]))
    CountryData_Wind_Offshore_Shallow = DataFrame(XLSX.gettable(hourly_data["TS_WIND_OFFSHORE_SHALLOW"]))
    CountryData_Wind_Offshore_Deep = DataFrame(XLSX.gettable(hourly_data["TS_WIND_OFFSHORE_DEEP"]))
    CountryData_Mobility_Psng = DataFrame(XLSX.gettable(hourly_data["TS_MOBILITY_PSNG"]))
    CountryData_Heat_Low = DataFrame(XLSX.gettable(hourly_data["TS_HEAT_LOW"]))
    CountryData_Heat_High = DataFrame(XLSX.gettable(hourly_data["TS_HEAT_HIGH"]))
    CountryData_HeatPump_AirSource = DataFrame(XLSX.gettable(hourly_data["TS_HP_AIRSOURCE"]))
    CountryData_HeatPump_GroundSource = DataFrame(XLSX.gettable(hourly_data["TS_HP_GROUNDSOURCE"]))
    CountryData_Hydro_RoR = DataFrame(XLSX.gettable(hourly_data["TS_HYDRO_ROR"]))

    CountryData["LOAD"] = CountryData_Load
    CountryData["PV_AVG"] = CountryData_PV_Avg
    CountryData["PV_INF"] = CountryData_PV_Inf
    CountryData["PV_OPT"] = CountryData_PV_Opt
    CountryData["PV_TRACKING"] = CountryData_PV_tracking
    CountryData["WIND_ONSHORE_AVG"] = CountryData_Wind_Onshore_Avg
    CountryData["WIND_ONSHORE_INF"] = CountryData_Wind_Onshore_Inf
    CountryData["WIND_ONSHORE_OPT"] = CountryData_Wind_Onshore_Opt
    CountryData["WIND_OFFSHORE"] = CountryData_Wind_Offshore
    CountryData["WIND_OFFSHORE_DEEP"] = CountryData_Wind_Offshore_Deep
    CountryData["WIND_OFFSHORE_SHALLOW"] = CountryData_Wind_Offshore_Shallow
    CountryData["HEAT_LOW"] = CountryData_Heat_Low
    CountryData["HEAT_HIGH"] = CountryData_Heat_High
    CountryData["HEAT_PUMP_AIR"] = CountryData_HeatPump_AirSource
    CountryData["HEAT_PUMP_GROUND"] = CountryData_HeatPump_GroundSource
    CountryData["MOBILITY_PSNG"] = CountryData_Mobility_Psng
    CountryData["HYDRO_ROR"] = CountryData_Hydro_RoR

    for cde ∈ Country_Data_Entries
        select!(CountryData[cde], Not([:HOUR]))
    end

    Dunkelflaute = Dict(x => mapcols(col -> col*0.0, CountryData[x]) for x ∈ Country_Data_Entries)
    SmoothedCountryData = Dict(x => mapcols(col -> col*0.0, CountryData[x]) for x ∈ Country_Data_Entries)
    ScaledCountryData = Dict(x => mapcols(col -> col*0.0, CountryData[x]) for x ∈ Country_Data_Entries)
    AverageCapacityFactor = Dict(x => mapcols(col -> 0.0, CountryData[x]) for x ∈ Country_Data_Entries)

    x_averageTimeSeriesValue = Dict()
    for cde ∈ Country_Data_Entries
        x_averageTimeSeriesValue[cde] = combine(CountryData[cde], names(CountryData[cde]) .=> DataFrames.mean, renamecols=false)
    end

    df_peakingDemand = Dict()
    for s ∈ intersect(Sets.Sector,keys(sector_to_tech)), r ∈ Sets.Region_full
        df_peakingDemand[s] = combine(CountryData[sector_to_tech[s]], names(CountryData[sector_to_tech[s]]) .=> maximum, renamecols=false) ./ x_averageTimeSeriesValue[sector_to_tech[s]]
        Params.x_peakingDemand[r,s] = df_peakingDemand[s][1,r]
    end

    negativeCDE = Dict(x => mapcols(col -> min.(col,0), CountryData[x]) for x ∈ Country_Data_Entries)

    LAST_TIMESLICE = Sets.Timeslice[end]
    FIRST_TIMESLICE = Sets.Timeslice[1]

    i = 1
    j = 0
    lll=0
    #insert the Dunkelflaute
    while i < 24 && lll < 500 #what is the second condition supposed to be?
        lll = (1+j) * (24*Switch.elmod_daystep+Switch.elmod_hourstep) + Switch.elmod_starthour
        
        Dunkelflaute["PV_INF"][lll,:] .= 0.5
        Dunkelflaute["WIND_ONSHORE_INF"][lll,:] .= 0.1
        Dunkelflaute["WIND_OFFSHORE"][lll,:] .= 0.1

        Dunkelflaute["PV_AVG"][lll,:] .= 0.5
        Dunkelflaute["WIND_ONSHORE_AVG"][lll,:] .= 0.1
        Dunkelflaute["WIND_OFFSHORE_SHALLOW"][lll,:] .= 0.1

        Dunkelflaute["PV_OPT"][lll,:] .= 0.5
        Dunkelflaute["WIND_ONSHORE_OPT"][lll,:] .= 0.1
        Dunkelflaute["WIND_OFFSHORE_DEEP"][lll,:] .= 0.1

        j+=1
        #Depending on the length of the total time set the length of the dunkelflaute are included
        if Switch.elmod_daystep == 0
            i+= 1
        else
            i += Switch.elmod_daystep * 2
        end
    end

    for r ∈ Sets.Region_full
        if sum(CountryData["LOAD"][l,r] for l ∈ Sets.Timeslice) != 0 
            AverageCapacityFactor["LOAD"][1,r] = sum(CountryData["LOAD"][:,r])/8760
        end
        CountryData["LOAD"][!,r] = CountryData["LOAD"][!,r] / AverageCapacityFactor["LOAD"][1,r]

        if sum(CountryData["HEAT_LOW"][l,r] for l ∈ Sets.Timeslice) != 0 
            AverageCapacityFactor["HEAT_LOW"][1,r] = sum(CountryData["HEAT_LOW"][:,r])/8760
        end
        CountryData["HEAT_LOW"][!,r] = CountryData["HEAT_LOW"][!,r] / AverageCapacityFactor["HEAT_LOW"][1,r]

        for cde ∈ Country_Data_Entries
            if sum(CountryData[cde][l,r] for l ∈ Sets.Timeslice) != 0 
                AverageCapacityFactor[cde][1,r] = sum(CountryData[cde][:,r])/8760
            end
        end
    end

    smoothing_range = Dict()
    smoothing_range["LOAD"] = 3
    smoothing_range["PV_INF"] = 1
    smoothing_range["WIND_ONSHORE_INF"] = 2
    smoothing_range["PV_AVG"] = 1
    smoothing_range["WIND_ONSHORE_AVG"] = 2
    smoothing_range["PV_OPT"] = 1
    smoothing_range["PV_TRACKING"] = 1
    smoothing_range["WIND_ONSHORE_OPT"] = 2
    smoothing_range["WIND_OFFSHORE"] = 2
    smoothing_range["WIND_OFFSHORE_SHALLOW"] = 2
    smoothing_range["WIND_OFFSHORE_DEEP"] = 2
    smoothing_range["MOBILITY_PSNG"] = 3
    smoothing_range["HEAT_LOW"] = 3
    smoothing_range["HEAT_HIGH"] = 3
    smoothing_range["HEAT_PUMP_AIR"] = 3
    smoothing_range["HEAT_PUMP_GROUND"] = 3
    smoothing_range["HYDRO_ROR"] = 3

    for cde ∈ Country_Data_Entries
        smoothing_range[cde]=1
    end

    # Full calculation
    if length(Sets.Timeslice) == 8760
        for cde ∈ Country_Data_Entries
            smoothing_range[cde]=0
        end
    end 

    # Every 25th hour
    if length(Sets.Timeslice) == 374
        smoothing_range["LOAD"] = 3
        smoothing_range["PV_INF"] = 1
        smoothing_range["WIND_ONSHORE_INF"] = 4
        smoothing_range["PV_AVG"] = 1
        smoothing_range["WIND_ONSHORE_AVG"] = 4
        smoothing_range["PV_OPT"] = 1
        smoothing_range["PV_TRACKING"] = 1
        smoothing_range["WIND_ONSHORE_OPT"] = 4
        smoothing_range["WIND_OFFSHORE"] = 4
        smoothing_range["WIND_OFFSHORE_SHALLOW"] = 4
        smoothing_range["WIND_OFFSHORE_DEEP"] = 4
        smoothing_range["MOBILITY_PSNG"] = 3
        smoothing_range["HEAT_LOW"] = 3
        smoothing_range["HEAT_HIGH"] = 3
        smoothing_range["HEAT_PUMP_AIR"] = 3
        smoothing_range["HEAT_PUMP_GROUND"] = 3
        smoothing_range["HYDRO_ROR"] = 3
    end

    # Every 49th hour
    if length(Sets.Timeslice) == 191
        smoothing_range["LOAD"] = 3
        smoothing_range["PV_INF"] = 1
        smoothing_range["WIND_ONSHORE_INF"] = 3
        smoothing_range["PV_AVG"] = 1
        smoothing_range["WIND_ONSHORE_AVG"] = 3
        smoothing_range["PV_OPT"] = 1
        smoothing_range["PV_TRACKING"] = 1
        smoothing_range["WIND_ONSHORE_OPT"] = 3
        smoothing_range["WIND_OFFSHORE"] = 3
        smoothing_range["WIND_OFFSHORE_SHALLOW"] = 3
        smoothing_range["WIND_OFFSHORE_DEEP"] = 3
        smoothing_range["MOBILITY_PSNG"] = 3
        smoothing_range["HEAT_LOW"] = 3
        smoothing_range["HEAT_HIGH"] = 3
        smoothing_range["HEAT_PUMP_AIR"] = 3
        smoothing_range["HEAT_PUMP_GROUND"] = 3
        smoothing_range["HYDRO_ROR"] = 3
    end

    # If very short time-spans are used (e.g. for testing) decrease smoothing range
    for cde ∈ Country_Data_Entries
        if smoothing_range[cde]*2+1 > length(Sets.Timeslice)
            smoothing_range[cde] = max(0, round(length(Sets.Timeslice)/2-2))
        end
    end

    for cde ∈ Country_Data_Entries for r ∈ Sets.Region_full
        if sum(CountryData[cde][:,r]) != 0
            if smoothing_range[cde] == 0 
                SmoothedCountryData[cde] = CountryData[cde]
            elseif smoothing_range[cde] > 0
                for j ∈ eachindex(Sets.Timeslice)
                    SmoothedCountryData[cde][Sets.Timeslice[j],r] = sum(CountryData[cde][Sets.Timeslice[k],r]*
                    (1+((switch_dunkelflaute ==1 && Dunkelflaute[cde][Sets.Timeslice[j],r] > 0) ? -1+Dunkelflaute[cde][Sets.Timeslice[j],r] : 0)) 
                    for k ∈ eachindex(Sets.Timeslice) if ((k >= j - smoothing_range[cde]) && (k <= j + smoothing_range[cde]))) / sum(1 for k ∈ eachindex(Sets.Timeslice) if ((k >= j - smoothing_range[cde]) && (k <= j + smoothing_range[cde])))
                end
            end
        end
    end end

    # Determine minimum and maximum values in timeup and timeup_smoothed
    CountryDataMin         = Dict(cde => combine(CountryData[cde], names(CountryData[cde]) .=> minimum, renamecols=false) for cde ∈ Country_Data_Entries)
    CountryDataMax         = Dict(cde => combine(CountryData[cde], names(CountryData[cde]) .=> maximum, renamecols=false) for cde ∈ Country_Data_Entries)
    SmoothedCountryDataMin = Dict(cde => combine(SmoothedCountryData[cde][Sets.Timeslice,:], names(SmoothedCountryData[cde]) .=> minimum, renamecols=false) for cde ∈ Country_Data_Entries)
    SmoothedCountryDataMax = Dict(cde => combine(SmoothedCountryData[cde][Sets.Timeslice,:], names(SmoothedCountryData[cde]) .=> maximum, renamecols=false) for cde ∈ Country_Data_Entries)

    #Find the t with the highest /lovest value
    set_SmoothedCountryDataMin_tmp = Dict(cde => combine(SmoothedCountryData[cde][Sets.Timeslice,:], names(SmoothedCountryData[cde]) .=> argmin, renamecols=false) for cde ∈ Country_Data_Entries)
    set_SmoothedCountryDataMax_tmp = Dict(cde => combine(SmoothedCountryData[cde][Sets.Timeslice,:], names(SmoothedCountryData[cde]) .=> argmax, renamecols=false) for cde ∈ Country_Data_Entries)

    set_SmoothedCountryDataMin = Dict( cde => DataFrame(Dict(r => Sets.Timeslice[set_SmoothedCountryDataMin_tmp[cde][1,r]] for r in Sets.Region_full)) for cde ∈ Country_Data_Entries)
    set_SmoothedCountryDataMax = Dict( cde => DataFrame(Dict(r => Sets.Timeslice[set_SmoothedCountryDataMax_tmp[cde][1,r]] for r in Sets.Region_full)) for cde ∈ Country_Data_Entries)
    
    if Switch.elmod_nthhour == 1
        scaling_exponent = JuMP.Containers.DenseAxisArray(ones(length(Sets.Region_full), length(Country_Data_Entries)), Sets.Region_full, Country_Data_Entries)
        scaling_multiplicator = JuMP.Containers.DenseAxisArray(ones(length(Sets.Region_full), length(Country_Data_Entries)), Sets.Region_full, Country_Data_Entries)
        scaling_addition = JuMP.Containers.DenseAxisArray(zeros(length(Sets.Region_full), length(Country_Data_Entries)), Sets.Region_full, Country_Data_Entries)

        ScaledCountryData = CountryData
    else
        # SCALING
        model_scaling1 = JuMP.Model()

        @variable(model_scaling1, scaling_objective)
        @variable(model_scaling1, scaling_exponent[Sets.Region_full,Country_Data_Entries], start=1)
        @variable(model_scaling1, scaling_multiplicator[Sets.Region_full,Country_Data_Entries])
        @variable(model_scaling1, scaling_addition[Sets.Region_full,Country_Data_Entries])

        @NLconstraint(model_scaling1, def_scaling_max[r = Sets.Region_full, cde = Country_Data_Entries ; AverageCapacityFactor[cde][1,r] != 0 && (SmoothedCountryDataMax[cde][1,r] - SmoothedCountryDataMin[cde][1,r]) != 0],
        CountryDataMax[cde][1,r] - CountryDataMin[cde][1,r] == model_scaling1[:scaling_multiplicator][r,cde])
        @NLconstraint(model_scaling1, def_scaling_min[r = Sets.Region_full, cde = Country_Data_Entries ; AverageCapacityFactor[cde][1,r] != 0 && (SmoothedCountryDataMax[cde][1,r] - SmoothedCountryDataMin[cde][1,r]) != 0],
        CountryDataMin[cde][1,r] == model_scaling1[:scaling_addition][r,cde])

        N=length(Sets.Timeslice)
        @NLconstraint(model_scaling1, def_scaling_objective, model_scaling1[:scaling_objective] == 
        sum((AverageCapacityFactor[cde][1,r] * N - 
        sum(max(0,((((SmoothedCountryData[cde][l,r]-SmoothedCountryDataMin[cde][1,r])/(SmoothedCountryDataMax[cde][1,r]-SmoothedCountryDataMin[cde][1,r])
        )^model_scaling1[:scaling_exponent][r,cde]
        )*(CountryDataMax[cde][1,r] - CountryDataMin[cde][1,r])
        ) + CountryDataMin[cde][1,r]) for l ∈ Sets.Timeslice if (SmoothedCountryData[cde][l,r]-SmoothedCountryDataMin[cde][1,r]) != 0) - sum(max(0,CountryDataMin[cde][1,r]) for l ∈ Sets.Timeslice if (SmoothedCountryData[cde][l,r]-SmoothedCountryDataMin[cde][1,r]) == 0)
        )^2 for r ∈ Sets.Region_full for cde ∈ Country_Data_Entries if (AverageCapacityFactor[cde][1,r] != 0 && (SmoothedCountryDataMax[cde][1,r] - SmoothedCountryDataMin[cde][1,r]) != 0)))


        for r ∈ Sets.Region_full for cde ∈ Country_Data_Entries
            JuMP.set_lower_bound(model_scaling1[:scaling_exponent][r,cde], 0)
            JuMP.set_upper_bound(model_scaling1[:scaling_exponent][r,cde], 10)
        end end

        @objective(model_scaling1, MOI.MIN_SENSE, model_scaling1[:scaling_objective])
        set_optimizer(model_scaling1, Switch.DNLPsolver)
        optimize!(model_scaling1)

        for cde ∈ Country_Data_Entries for r ∈ Sets.Region_full
            if SmoothedCountryDataMax[cde][1,r] - SmoothedCountryDataMin[cde][1,r] != 0
                for l ∈ Sets.Timeslice
                ScaledCountryData[cde][l,r] = max(0, (
                    ((((SmoothedCountryData[cde][l,r] - SmoothedCountryDataMin[cde][1,r]) / (SmoothedCountryDataMax[cde][1,r] - SmoothedCountryDataMin[cde][1,r])
                    )^max(0,JuMP.value(model_scaling1[:scaling_exponent][r,cde]))
                    )
                    ) * JuMP.value(model_scaling1[:scaling_multiplicator][r,cde])
                    ) + JuMP.value(model_scaling1[:scaling_addition][r,cde]))
                end
            end
        end end
    end

    for cde ∈ Country_Data_Entries
        ScaledCountryData[cde] .= round.(ScaledCountryData[cde], digits=6)
    end

    sdp_list=["Power","Mobility_Passenger","Mobility_Freight","Heat_Low_Residential","Heat_Low_Industrial","Heat_Medium_Industrial","Heat_High_Industrial"]
    capf_list=["HLR_Heatpump_Aerial","HLR_Heatpump_Ground","RES_PV_Utility_Opt","RES_Wind_Onshore_Opt","RES_Wind_Offshore_Transitional","RES_Wind_Onshore_Avg","RES_Wind_Offshore_Shallow","RES_PV_Utility_Inf",
    "RES_Wind_Onshore_Inf","RES_Wind_Offshore_Deep","RES_PV_Utility_Tracking","RES_Hydro_Small"]

    tmp = ScaledCountryData["LOAD"] ./ length(Sets.Timeslice)
    for r ∈ Sets.Region_full
        for f ∈ Sets.Fuel
            if sum(Params.SpecifiedAnnualDemand[r,f,:]) != 0
                Params.SpecifiedDemandProfile[r,f,:,Sets.Year[1]] = tmp[Sets.Timeslice,r]
            end
        end
    end

    tmp=Dict()
    tmp["MOBILITY_PSNG"] = ScaledCountryData["MOBILITY_PSNG"] ./ combine(ScaledCountryData["MOBILITY_PSNG"], names(ScaledCountryData["MOBILITY_PSNG"]) .=> sum, renamecols=false)
    tmp["HEAT_LOW"] = ScaledCountryData["HEAT_LOW"] ./ combine(ScaledCountryData["HEAT_LOW"], names(ScaledCountryData["HEAT_LOW"]) .=> sum, renamecols=false)
    tmp["HEAT_HIGH"] = ScaledCountryData["HEAT_HIGH"] ./ combine(ScaledCountryData["HEAT_HIGH"], names(ScaledCountryData["HEAT_HIGH"]) .=> sum, renamecols=false)

    for r ∈ Sets.Region_full 
        Params.SpecifiedDemandProfile[r,"Mobility_Passenger",:,Sets.Year[1]] = tmp["MOBILITY_PSNG"][Sets.Timeslice,r]
        Params.SpecifiedDemandProfile[r,"Mobility_Freight",:,Sets.Year[1]] = tmp["MOBILITY_PSNG"][Sets.Timeslice,r]
        Params.SpecifiedDemandProfile[r,"Heat_Low_Residential",:,Sets.Year[1]] = tmp["HEAT_LOW"][Sets.Timeslice,r]
        Params.SpecifiedDemandProfile[r,"Heat_Low_Industrial",:,Sets.Year[1]] = tmp["HEAT_HIGH"][Sets.Timeslice,r]
        Params.SpecifiedDemandProfile[r,"Heat_Medium_Industrial",:,Sets.Year[1]] = tmp["HEAT_HIGH"][Sets.Timeslice,r]
        Params.SpecifiedDemandProfile[r,"Heat_High_Industrial",:,Sets.Year[1]] = tmp["HEAT_HIGH"][Sets.Timeslice,r]
    end

    for r ∈ Sets.Region_full for f ∈ Sets.Fuel for y ∈ Sets.Year[2:end]
        Params.SpecifiedDemandProfile[r,f,:,y] = Params.SpecifiedDemandProfile[r,f,:,Sets.Year[1]]
    end end end
    
    for y ∈ Sets.Year
        for t ∈ Params.Tags.TagTechnologyToSubsets["Solar"]
            Params.CapacityFactor[:,t,:,y] .= 0
        end
        for t ∈ Params.Tags.TagTechnologyToSubsets["Wind"]
            Params.CapacityFactor[:,t,:,y] .= 0
        end
        for r ∈ Sets.Region_full 
            if length(Sets.Timeslice) < 8760
                Params.CapacityFactor[r,"HLR_Heatpump_Aerial",:,y] .= 1
                Params.CapacityFactor[r,"HLR_Heatpump_Ground",:,y] .= 1
                Params.TimeDepEfficiency[r,"HLR_Heatpump_Aerial",:,y] = ScaledCountryData["HEAT_PUMP_AIR"][Sets.Timeslice,r]
                Params.TimeDepEfficiency[r,"HLR_Heatpump_Ground",:,y] = ScaledCountryData["HEAT_PUMP_GROUND"][Sets.Timeslice,r]

                Params.CapacityFactor[r,"RES_PV_Utility_Opt",:,y] = ScaledCountryData["PV_OPT"][Sets.Timeslice,r]
                Params.CapacityFactor[r,"RES_Wind_Onshore_Opt",:,y] = ScaledCountryData["WIND_ONSHORE_OPT"][Sets.Timeslice,r]
                Params.CapacityFactor[r,"RES_Wind_Offshore_Transitional",:,y] = ScaledCountryData["WIND_OFFSHORE"][Sets.Timeslice,r]

                Params.CapacityFactor[r,"RES_PV_Utility_Avg",:,y] = ScaledCountryData["PV_AVG"][Sets.Timeslice,r]
                Params.CapacityFactor[r,"RES_Wind_Onshore_Avg",:,y] = ScaledCountryData["WIND_ONSHORE_AVG"][Sets.Timeslice,r]
                Params.CapacityFactor[r,"RES_Wind_Offshore_Shallow",:,y] = ScaledCountryData["WIND_OFFSHORE_SHALLOW"][Sets.Timeslice,r]

                Params.CapacityFactor[r,"RES_PV_Utility_Inf",:,y] = ScaledCountryData["PV_INF"][Sets.Timeslice,r]
                Params.CapacityFactor[r,"RES_Wind_Onshore_Inf",:,y] = ScaledCountryData["WIND_ONSHORE_INF"][Sets.Timeslice,r]
                Params.CapacityFactor[r,"RES_Wind_Offshore_Deep",:,y] = ScaledCountryData["WIND_OFFSHORE_DEEP"][Sets.Timeslice,r]

                Params.CapacityFactor[r,"RES_PV_Utility_Tracking",:,y] = ScaledCountryData["PV_TRACKING"][Sets.Timeslice,r]

                Params.CapacityFactor[r,"RES_Hydro_Small",:,y] = ScaledCountryData["HYDRO_ROR"][Sets.Timeslice,r]
            else
                Params.CapacityFactor[r,"HLR_Heatpump_Aerial",:,y] = CountryData["HEAT_PUMP_AIR"][:,r]
                Params.CapacityFactor[r,"HLR_Heatpump_Ground",:,y] = CountryData["HEAT_PUMP_GROUND"][:,r]

                Params.CapacityFactor[r,"RES_PV_Utility_Opt",:,y] = CountryData["PV_OPT"][:,r]
                Params.CapacityFactor[r,"RES_Wind_Onshore_Opt",:,y] = CountryData["WIND_ONSHORE_OPT"][:,r]
                Params.CapacityFactor[r,"RES_Wind_Offshore_Transitional",:,y] = CountryData["WIND_OFFSHORE"][:,r]

                Params.CapacityFactor[r,"RES_PV_Utility_Avg",:,y] = CountryData["PV_AVG"][:,r]
                Params.CapacityFactor[r,"RES_Wind_Onshore_Avg",:,y] = CountryData["WIND_ONSHORE_AVG"][:,r]
                Params.CapacityFactor[r,"RES_Wind_Offshore_Shallow",:,y] = CountryData["WIND_OFFSHORE_SHALLOW"][:,r]

                Params.CapacityFactor[r,"RES_PV_Utility_Inf",:,y] = CountryData["PV_INF"][:,r]
                Params.CapacityFactor[r,"RES_Wind_Onshore_Inf",:,y] = CountryData["WIND_ONSHORE_INF"][:,r]
                Params.CapacityFactor[r,"RES_Wind_Offshore_Deep",:,y] = CountryData["WIND_OFFSHORE_DEEP"][:,r]

                Params.CapacityFactor[r,"RES_PV_Utility_Tracking",:,y] = CountryData["PV_TRACKING"][:,r]

                Params.CapacityFactor[r,"RES_Hydro_Small",:,y] = CountryData["HYDRO_ROR"][:,r]
            end
        end
    end


    if Switch.write_reduced_timeserie == 1
        df_SpecifiedDemandProfile = convert_jump_container_to_df(Params.SpecifiedDemandProfile[:,sdp_list,:,:];dim_names=[:Region,:Fuel,:Timeslice,:Year])
        df_CapacityFactor = convert_jump_container_to_df(Params.CapacityFactor[:,capf_list,:,:];dim_names=[:Region,:Technology,:Timeslice,:Year])
        df_x_peakingDemand = convert_jump_container_to_df(Params.x_peakingDemand;dim_names=[:Region,:Sector])
        df_YearSplit = convert_jump_container_to_df(Params.YearSplit;dim_names=[:Timeslice,:Year])
        
        filename = "$(Switch.inputdir)/input_reduced_timeserie_$(Switch.model_region)_$(Switch.emissionPathway)_$(Switch.emissionScenario)_$(Switch.elmod_nthhour).xlsx"
        if isfile(filename)
            rm(filename)
        end
        XLSX.writetable(filename,
        "SpecifiedDemandProfile" => df_SpecifiedDemandProfile, "CapacityFactor" => df_CapacityFactor, "x_peakingDemand" => df_x_peakingDemand,
        "YearSplit" => df_YearSplit)
    end

end