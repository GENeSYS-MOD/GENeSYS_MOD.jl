using CSV
using XLSX
using DataFrames
using PlotlyJS
using Plots
using StatsPlots
using Colors
using ColorSchemes

# function when sectors are considered
function extraction_and_cleaning(extr_str,tag_techno_sector, result_file, col_names, region, sector, inf_tech; defined_sector_techno=nothing, group_techno=false,reduce_subset=true)
    in_data = CSV.read("test\\TestData\\Results\\$(result_file)_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)

    ## removing the 0 from the dataframe, so the data is smaller
    subset_df = in_data[in_data.Region .== region,:]
    subset_df_reduced = subset_df
    if reduce_subset
        subset_df_reduced = subset_df[subset_df.Value .!=0,:]
    end

    sector_techno = defined_sector_techno
    ## array with all the considered technologies, including infeasibility tech
    if isnothing(defined_sector_techno)
        sector_techno = tag_techno_sector[tag_techno_sector.Sector .== sector, :].Technology
        sector_techno = vcat(sector_techno, inf_tech)
    end
    ## keeping only the sector technologies
    subset_df_sector = subset_df_reduced[in.(subset_df_reduced.Technology, Ref(sector_techno)),:]
    
    ## summing over all the technologies for each timeslice
    if group_techno
        grouped_df = groupby(subset_df_sector, :Timeslice)
        subset_df_sum = combine(grouped_df, :Value => sum=>:Value)
        subset_df_sector = subset_df_sum
    end

    return subset_df_sector, sector_techno
end

function separation_mo_storage(subset_df_sector)
    subset_df_production = subset_df_sector[(subset_df_sector.ModeOfOperation .== 1) .& .!occursin.("D_", subset_df_sector.Technology),:] 
    grouped_df_production = groupby(subset_df_production, :Timeslice)
    subset_df_sum_production = combine(grouped_df_production, :Value => sum=>:Value)

    subset_df_charge = subset_df_sector[(subset_df_sector.ModeOfOperation .== 1) .& occursin.("D_", subset_df_sector.Technology), :]
    grouped_df_charge = groupby(subset_df_charge, :Timeslice)
    subset_df_sum_charge = combine(grouped_df_charge, :Value => sum=>:Value)

    subset_df_discharge = subset_df_sector[occursin.("D_", subset_df_sector.Technology) .& (subset_df_sector.ModeOfOperation .==2), : ]
    grouped_df_discharge = groupby(subset_df_discharge, :Timeslice)
    subset_df_sum_discharge = combine(grouped_df_discharge, :Value => sum=>:Value)

    return subset_df_sum_production, subset_df_sum_charge, subset_df_sum_discharge
end

# function when fuels are considered
function extraction_and_cleaning(extr_str, result_file, col_names, region, fuels; group_fuels=false, reduce_subset=true)
    in_data = CSV.read("test\\TestData\\Results\\$(result_file)_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)

    ## removing the 0 from the dataframe, so the data is smaller
    subset_df = in_data[in_data.Region .== region,:]
    subset_df_reduced = subset_df
    if reduce_subset
        subset_df_reduced = subset_df[subset_df.Value .!=0,:]
    end

    ## keeping only the considered fuels
    subset_df_fuel = subset_df_reduced[in.(subset_df_reduced.Fuel, Ref(fuels)),:]
    
    ## summing over all the technologies for each timeslice
    if group_fuels
        grouped_df = groupby(subset_df_fuel, :Timeslice)
        subset_df_sum = combine(grouped_df, :Value => sum=>:Value)
        subset_df_fuel = subset_df_sum
    end

    return subset_df_fuel
end


function plot_roa(extr_str, tag_techno_sector,region, year, sector, inf_tech, colors; year_split=1/8760, display_plot=true, reduce_subset=true)
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    subset_df_sector, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, sector, inf_tech, reduce_subset = reduce_subset)
    fig = AbstractTrace[]
    df_dict = Dict()
    i = 1
    for t in sector_techno
        if startswith(t,"D_")
            subset_df_techno = subset_df_sector[(subset_df_sector.Technology.==t) .& (subset_df_sector.Year.==year),:]
            if !isempty(subset_df_techno)
                gdf_storage = groupby(subset_df_techno, "ModeOfOperation")
                for (mo, subdf) in pairs(gdf_storage)
                    if display_plot
                        push!(fig, PlotlyJS.bar(x = subdf.Timeslice,
                                y = (mo.ModeOfOperation == 2 ? 1 : -1) * subdf.Value * year_split,
                                name=t,
                                marker_color=colors[i]))
                    end
                    df_dict["$(t)_$(mo.ModeOfOperation)"] = subdf
                end
                i = i+1
            end
        else
            subset_df_techno = subset_df_sector[(subset_df_sector.Technology.==t) .& (subset_df_sector.Year.==year),:]
            if !isempty(subset_df_techno)
                if display_plot
                    push!(fig, PlotlyJS.bar(x = subset_df_techno.Timeslice,
                    y = subset_df_techno.Value*year_split,
                    name=t,
                    marker_color=colors[i]))
                    i += 1
                end
                df_dict[t] = subset_df_techno
            end 
        end
    end
    if display_plot
        display(PlotlyJS.plot(fig, Layout(title="Energy production in $(region) for sector $(sector) ($(extr_str))",
                                xaxis_title="Time (hours)",
                                yaxis_title="Production (PJ)",
                                barmode="relative"),
                                config=PlotConfig(scrollZoom=true)))
    end
    return df_dict
end

function plot_net_trade(extr_str, region, fuels)
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Value"]
    subset_df_fuels = extraction_and_cleaning(extr_str, "NetTrade", col_names, region, fuels)
    
    fig = AbstractTrace[]
    for f in fuels
        subset_df_fuel = subset_df_fuels[subset_df_fuels.Fuel.==f,:]
        push!(fig, PlotlyJS.bar(x = subset_df_fuel.Timeslice,
                    y = subset_df_fuel.Value,
                    name=f))
    end
    PlotlyJS.plot(fig, Layout(title="Net Trade in $(region) ($(extr_str))",
                        xaxis_title="Time (hours)",
                        yaxis_title="Net Trade (PJ)",
                        barmode="stack"),
                        config=PlotConfig(scrollZoom=true))
end

function plot_demand(extr_str, tag_techno_sector, region, year, sector, inf_tech, fuels;display_fig=true, plot_prices = false, considered_dual=nothing, year_split=1/8760)
    fig = AbstractTrace[]
    dict_demand = Dict()
    ## 1. Curtailment
    col_names = ["Region", "Timeslice", "Technology", "Year", "Value"]
    subset_df_curtailment, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"CurtailedCapacity", col_names, region, sector, inf_tech, group_techno=true)
    push!(fig, PlotlyJS.bar(x = subset_df_curtailment.Timeslice,
                    y = -subset_df_curtailment.Value*31.56*year_split,
                    name="Curtailment"))
    dict_demand["Curtailment"] = -subset_df_curtailment.Value*31.56*year_split

    ## 2. Export
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_export = extraction_and_cleaning(extr_str, "Export", col_names, region, fuels, group_fuels = true)
    push!(fig, PlotlyJS.bar(x = subset_df_export.Timeslice,
    y = -subset_df_export.Value,
    name = "Exports"))
    dict_demand["Exports"] = -subset_df_export.Value

    ## 3. Total production including charge / discharge of the storage
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    added_tech = []
    for t in inf_tech
        if startswith(t, "D_")
            push!(added_tech, t)
        end
    end
    subset_df, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, sector, added_tech)
    subset_df_production, subset_df_charge, subset_df_discharge = separation_mo_storage(subset_df)
    push!(fig, PlotlyJS.bar(x = subset_df_production.Timeslice,
    y = subset_df_discharge.Value * year_split,
    name = "Storage discharge"))
    dict_demand["StorageDischarge"] = subset_df_discharge.Value * year_split

    push!(fig, PlotlyJS.bar(x = subset_df_production.Timeslice,
    y = subset_df_production.Value * year_split,
    name = "Production"))
    dict_demand["Production"] = subset_df_production.Value * year_split
    
    push!(fig, PlotlyJS.bar(x = subset_df_charge.Timeslice,
    y = -subset_df_charge.Value * year_split,
    name = "Storage charge"))
    dict_demand["StorageCharge"] = -subset_df_charge.Value * year_split

    ## 4. Infeasibility
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    real_inf_tech = []
    for t in inf_tech
        if startswith(t, "Infeasibility")
            push!(real_inf_tech,t)
        end
    end
    subset_df_inf, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, sector, inf_tech, group_techno=true, defined_sector_techno = real_inf_tech)
    push!(fig, PlotlyJS.bar(x = subset_df_inf.Timeslice,
    y = subset_df_inf.Value*year_split,
    name="Infeasible"))
    dict_demand["Infeasible"] = subset_df_inf.Value*year_split

    ## 5. Import
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_import = extraction_and_cleaning(extr_str, "Import", col_names, region, fuels, group_fuels = true)
    push!(fig, PlotlyJS.bar(x = subset_df_import.Timeslice,
    y = subset_df_import.Value,
    name = "Imports"))
    dict_demand["Imports"] = subset_df_import.Value

    ## 6. Dual
    if plot_prices
        df_dual = plot_duals(extr_str, region, considered_dual = considered_dual, display_plot=false)
        df_dual_region = df_dual[(df_dual.Region .== region) .& (df_dual.Year .== year), :]
        gdf_fuel = groupby(df_dual_region, :Fuel)
        for (fuel, subdf) in pairs(gdf_fuel)
            push!(fig, PlotlyJS.scatter(x=subdf.Timeslice, y = subdf.Value*(31.536/8760)*1000, name="Dual $(fuel.Fuel)", yaxis="y2"))
        end
        if display_fig
            display(PlotlyJS.plot(fig, Layout(title="Energy demand in $(region) for sector $(sector) and fuels $(fuels) ($(extr_str))",
                        xaxis_title="Time (hours)",
                        yaxis_title="Energy (PJ)",
                        yaxis2=attr(title="Cost (€/MWh)", overlaying="y", side="right"),
                        barmode="relative"), 
                        config=PlotConfig(scrollZoom=true)))
        end
    else
        if display_fig
            display(PlotlyJS.plot(fig, Layout(title="Energy demand in $(region) for sector $(sector) and fuels $(fuels) ($(extr_str))",
                        xaxis_title="Time (hours)",
                        yaxis_title="Energy (PJ)",
                        barmode="relative"), 
                        config=PlotConfig(scrollZoom=true)))
        end
    end
    return dict_demand
end

function plot_storage_status(extr_str, region, year; considered_storages=nothing)
    col_names = ["Storage", "Year", "Timeslice", "Region", "Value"]
    in_data = CSV.read("test\\TestData\\Results\\StorageLevelTSStart_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)

    ## removing the 0 from the dataframe, so the data is smaller
    subset_df = in_data[(in_data.Region .== region) .& (in_data.Year .== year),:]
    subset_df_reduced = subset_df[subset_df.Value .!=0,:]
    subset_df_storages = subset_df_reduced

    ## keeping only the considered storages
    if !isnothing(considered_storages)
        subset_df_storages = subset_df_reduced[in.(subset_df_reduced.Storage, Ref(considered_storages)),:]
    end

    fig = AbstractTrace[]
    gdf_storages = groupby(subset_df_storages, "Storage")
    for (s,subdf) in pairs(gdf_storages)
        push!(fig, PlotlyJS.scatter(x = subdf.Timeslice,
                    y = subdf.Value,
                    name=s.Storage))
    end
    display(PlotlyJS.plot(fig, Layout(title="Storage Level at each beginning of time slice for Region $(region) ($(extr_str))",
                        xaxis_title="Time (hours)",
                        yaxis_title="Storage level (PJ)",
                        barmode="stack"),
                        config=PlotConfig(scrollZoom=true)))


end

function plot_duals(extr_str, region; considered_dual=nothing, display_plot=true)
    in_data = read_dual_results(extr_str)
    considered_data = in_data
    if !isnothing(considered_dual)
        considered_data = in_data[in.(in_data.Fuel, Ref(considered_dual)),:]
    end
    
    fig = AbstractTrace[]
    dual_gdf = groupby(in_data,"Fuel")
    for (f,subdf) in pairs(dual_gdf)
        subdf_region = subdf[subdf.Region .== region, :]
        push!(fig, PlotlyJS.scatter(x = subdf_region.Timeslice,
                    y = subdf_region.Value,
                    name=f.Fuel))
    end
    if display_plot
        PlotlyJS.plot(fig, Layout(title="Energy Balance dual values for Region $(region) ($(extr_str))",
                        xaxis_title="Time (hours)",
                        yaxis_title="Dual (price)"),
                        config=PlotConfig(scrollZoom=true))
    end
    return considered_data

end

function plot_period_comparison_roa(extr_str_list, period, region, year, tag_techno_sector, sector, inf_tech, colors; year_split=1/8760)
    list_df_dict = []
    for extr_str in extr_str_list
        df_dict = plot_roa(extr_str, tag_techno_sector, region, year, sector, inf_tech, colors, year_split=year_split, display_plot=false, reduce_subset= false)
        push!(list_df_dict, df_dict)
    end
    fig = AbstractTrace[]
    i=1
    keys_dict = [keys(df_dict) for df_dict in list_df_dict]
    union_tech = union(keys_dict...)
    for tech in union_tech
        y = []
        for df_dict in list_df_dict
            if haskey(df_dict, tech)
                df = df_dict[tech]

                # group by mode of operation
                gdf = groupby(df, :Timeslice)
                df_all_mo = combine(gdf, :Value => sum=>:Value)

                # taking only the chosen period
                period_df = df_all_mo[period,:]
                sum_value = sum(period_df.Value)
                mult = (startswith(tech, "D_") & endswith(tech, "1") ? -1 : 1)
                push!(y, mult* sum_value * year_split)
            else
                push!(y, 0)
            end
        end
        if !iszero(y)
            push!(fig, PlotlyJS.bar(x = extr_str_list,
            y = y,
            name=tech,
            marker_color=colors[i]))
            i+=1
        end
    end
    display(PlotlyJS.plot(fig, Layout(title="Production in sector $(sector) of $(region) in period $(period)",
    yaxis_title="Energy (PJ)",
    barmode="relative"),
    config=PlotConfig(scrollZoom=true)))
end

function plot_year_comparison_demand(extr_str_list, region, tag_techno_sector, sector, inf_tech, fuels; year_split=1/8760)
    values_list_dict = []
    fig = AbstractTrace[]
    for extr_str in extr_str_list
        values_dict = plot_demand(extr_str, tag_techno_sector, region, sector, inf_tech, fuels, year_split=year_split, display_fig=false)
        push!(values_list_dict, values_dict)
    end
    keys_dict = [keys(dict) for dict in values_list_dict]
    union_index = union(keys_dict...)
    for index in union_index
        y = []
        for value_dict in values_list_dict
            if haskey(value_dict, index)
                push!(y, sum(value_dict[index]))
            end
        end
        if !iszero(y)
            push!(fig, PlotlyJS.bar(x = extr_str_list,
            y = y,
            name=index
            ))
        end
    end
    display(PlotlyJS.plot(fig, Layout(title="Energy demand in sector $(sector) of $(region) in the year",
    yaxis_title="Energy (PJ)",
    barmode="relative"),
    config=PlotConfig(scrollZoom=true)))      
end

function plot_capacities(extr_str1, extr_str2, region, year, tag_techno_sector, sector, colors)
    col_names = ["Year", "Technology", "Region", "Value"]
    in_data = CSV.read("test\\TestData\\Results\\TotalCapacityAnnual_minimal_MinimalExample_globalLimit_$(extr_str1).csv", DataFrame, header=col_names, skipto=2)
    in_data_reduced = in_data[(in_data.Value .!= 0) .& (in_data.Region .== region) .& (in_data.Year .== year),: ]
    in_data2 = CSV.read("test\\TestData\\Results\\TotalCapacityAnnual_minimal_MinimalExample_globalLimit_$(extr_str2).csv", DataFrame, header=col_names, skipto=2)
    in_data_reduced2 = in_data2[(in_data2.Value .!= 0) .& (in_data2.Region .== region) .& (in_data2.Year .== year),: ]

    sector_techno = tag_techno_sector[tag_techno_sector.Sector .== sector, :].Technology
    
    capacities_dict = Dict(Pair.(in_data_reduced.Technology, in_data_reduced.Value))
    capacities_dict2 = Dict(Pair.(in_data_reduced2.Technology, in_data_reduced2.Value))

    fig = AbstractTrace[]
    i = 1
    
    for (tech, capacity) in capacities_dict
        if in(tech, sector_techno)
            if haskey(capacities_dict2, tech)
                push!(fig, PlotlyJS.bar(x = [extr_str1, extr_str2],
                y = [capacity, capacities_dict2[tech]],
                name=tech,
                marker_color=colors[i]))
            else
                push!(fig, PlotlyJS.bar(x = [extr_str1, extr_str2],
                y = [capacity, 0],
                name=tech,
                marker_color=colors[i]))
            end
            i+=1
        end
    end

    for tech in setdiff(keys(capacities_dict2), keys(capacities_dict))
        push!(fig, PlotlyJS.bar(x = [extr_str1, extr_str2],
                y = [0, capacities_dict2[tech]],
                name=tech,
                marker_color=colors[i]))
        i+=1
    end

    display(PlotlyJS.plot(fig, Layout(title="Computed capacities in region $(region) for sector $(sector)",
    yaxis_title="Capacity (GW)",
    barmode="stack"),
    config=PlotConfig(scrollZoom=true)))
end

function write_demand(extr_str, tag_techno_sector, region, sector, inf_tech, fuels; considered_dual=nothing, year_split=1/8760)
    ## 1. Curtailment
    col_names = ["Region", "Timeslice", "Technology", "Year", "Value"]
    subset_df_curtailment, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"CurtailedCapacity", col_names, region, sector, inf_tech, group_techno=true, reduce_subset=false)
    df = DataFrame("Curtailment_PJ"=>subset_df_curtailment.Value*31.56*year_split)

    ## 2. Export
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_export = extraction_and_cleaning(extr_str, "Export", col_names, region, fuels, group_fuels = true, reduce_subset=false)
    df[:,:Exports_PJ] .= subset_df_export.Value

    ## 3. Total production including charge / discharge of the storage
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    subset_df, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, sector, [], reduce_subset=false)
    subset_df_production, subset_df_charge, subset_df_discharge = separation_mo_storage(subset_df)
    df[:,:Production_PJ] .= subset_df_production.Value * year_split
    df[:,:Storage_charge_PJ] .= subset_df_charge.Value * year_split

    ## 4. Infeasibility
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    subset_df_inf, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, sector, inf_tech, group_techno=true, defined_sector_techno = inf_tech, reduce_subset=false)
    df[:,:Infeasible_PJ] .= subset_df_inf.Value * year_split

    ## 5. Import
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_import = extraction_and_cleaning(extr_str, "Import", col_names, region, fuels, group_fuels = true, reduce_subset=false)
    df[:,:Imports_PJ] .= subset_df_import.Value

    ## 6. Dual
    df_dual = plot_duals(extr_str, region, considered_dual = considered_dual, display_plot=false)
    df_dual_region = df_dual[df_dual.Region .== region, :]
    gdf_fuel = groupby(df_dual_region, :Fuel)
    for (fuel, subdf) in pairs(gdf_fuel)
        df[:,"Dual_$(fuel.Fuel)_euro_per_MWh"] .= subdf.Value*(31.536/8760)*1000
    end

    ## write in a csv file
    CSV.write("demand_$(sector)_$(region)_$(extr_str).csv", df)
end

function plot_RE_heat(extr_str, tag_techno_sector, region, inf_tech, colors)
    df_roa_power_dict = plot_roa(extr_str, tag_techno_sector, region, "Power", inf_tech, colors, display_plot=false)
    df_roa_heat_dict = plot_roa(extr_str, tag_techno_sector, region, "Buildings", [], colors, display_plot=false)
    
    # we want to keep only the heat produced with heat pump and the heat storage
    df_HP = copy(df_roa_heat_dict["HLR_Heatpump_Aerial"])
    rename!(df_HP, :Value => :Value_HP)
    df_HLRStorage_charge = copy(df_roa_heat_dict["D_Heat_HLR_1"])
    rename!(df_HLRStorage_charge, :Value => :Value_Storage)
    df_HLRStorage_discharge = df_roa_heat_dict["D_Heat_HLR_2"]

    # keeping only the heat charged in the battery with electricity (assuming heat pump is the first in the merit order, compared to gas and district heating)
    df_join_heat = outerjoin(df_HP[:,[:Timeslice, :Value_HP]], df_HLRStorage_charge[:,[:Timeslice, :Value_Storage]], on = :Timeslice)
    df_join_heat_clean = coalesce.(df_join_heat, 0)
    df_join_heat_clean.Value = min.(df_join_heat_clean.Value_HP, df_join_heat_clean.Value_Storage)
    
    # plotting the power roa and the charge/discharge of battery to compare (charge only with electricity)
    fig = AbstractTrace[]
    i = 1
    for (tech,df) in df_roa_power_dict
        if startswith(tech, "D_") & endswith(tech, "1")
            push!(fig, PlotlyJS.bar(x = df.Timeslice,
                                y =  - df.Value * year_split,
                                name=tech,
                                marker_color=colors[i]))
            i = i+1
        else
            push!(fig, PlotlyJS.bar(x = df.Timeslice,
                                y =  df.Value * year_split,
                                name=tech,
                                marker_color=colors[i]))
            i = i+1
        end
    end
    push!(fig, PlotlyJS.bar(x = df_join_heat_clean.Timeslice, y = - df_join_heat_clean.Value * year_split, name = "D_Heat_HLR_charge", marker_color = colors[i]))
    push!(fig, PlotlyJS.bar(x = df_HLRStorage_discharge.Timeslice, y = df_HLRStorage_discharge.Value *year_split, name = "D_Heat_HLR", marker_color = colors[i]))
    display(PlotlyJS.plot(fig, Layout(title="Energy production in $(region) for sector Power and Heat ($(extr_str))",
    xaxis_title="Time (hours)",
    yaxis_title="Production (PJ)",
    barmode="relative"),
    config=PlotConfig(scrollZoom=true)))
end

function read_dual_results(extr_str)
    col_names = ["Name", "Value"]
    df = CSV.read("test\\TestData\\Results\\Duals_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)
    regions = []
    years = []
    timeslices = []
    fuels = []
    for name in df.Name
        splitting = split(name, "_")
        push!(years, parse(Int64, splitting[3]))
        push!(timeslices, parse(Int64, splitting[4]))
        x = lastindex(splitting)
        fuel = splitting[5:x-1]
        push!(fuels, string(fuel...))
        push!(regions, last(splitting))
    end
    
    df.Fuel = fuels
    df.Timeslice = timeslices
    df.Region = regions
    df.Year = years
    return df[!, ["Name", "Fuel", "Timeslice", "Region", "Year", "Value"]]
end