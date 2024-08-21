using CSV
using XLSX
using DataFrames
using PlotlyJS
using Plots
using StatsPlots
using Colors
using ColorSchemes

aggregation = Dict(
    "P_Nuclear"=>"Nuclear",
    "P_Coal_Hardcoal"=>"Hardcoal",
    "P_Coal_Lignite"=>"Lignite",
    "P_Oil"=>"Oil",
    "P_Gas_OCGT"=>"Gas",
    "P_Gas_CCGT"=>"Gas",
    "P_Gas_CCS"=>"Gas",
    "P_Gas_Engines"=>"Gas",
    "RES_Hydro_Large"=>"Hydro Reservoir",
    "RES_Hydro_Small"=>"Hydro Run-of-River",
    "RES_Wind_Offshore_Deep"=>"Wind_Offshore",
    "RES_Wind_Offshore_Transitional"=>"Wind_Offshore",
    "RES_Wind_Offshore_Shallow"=>"Wind_Offshore",
    "RES_Wind_Onshore_Opt"=>"Wind_Onshore",
    "RES_Wind_Onshore_Avg"=>"Wind_Onshore",
    "RES_Wind_Onshore_Inf"=>"Wind_Onshore",
    "RES_PV_Utility_Opt"=>"PV",
    "RES_PV_Utility_Avg"=>"PV",
    "RES_PV_Rooftop_Residential"=>"PV",
    "RES_PV_Utility_Tracking"=>"PV",
    "RES_PV_Utility_Inf"=>"PV",
    "RES_PV_Rooftop_Commercial"=>"PV",
    "P_Biomass"=>"Biomass",
    "P_Biomass_CCS"=>"Biomass",
    "D_PHS"=>"Pumped Hydro",
    "D_PHS_Residual"=>"Pumped Hydro",
)

# function when sectors are considered
function extraction_and_cleaning(extr_str,tag_techno_sector, result_file, col_names, region, year, sector, inf_tech; defined_sector_techno=nothing, group_techno=false,reduce_subset=true, aggregate_techno=true)
    in_data = CSV.read("test\\TestData\\Results\\$(result_file)_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)

    ## removing the 0 from the dataframe, so the data is smaller
    if !isnothing(region)
        subset_df = in_data[(in_data.Region .== region) .&& (in_data.Year .== year),:]
    else
        subset_df = in_data[(in_data.Year .== year),:]
    end
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
    
    ## aggregation of technologies so the results are easier to read
    if aggregate_techno
        replace!(subset_df_sector.Technology, aggregation...)
        pop!(col_names)
        grouped_df = groupby(subset_df_sector, col_names)
        subset_df_sector = combine(grouped_df, :Value => sum=>:Value)
    end
    print(first(aggregate_techno,5))
    ## summing over all the technologies for each timeslice
    if group_techno
        grouped_df = groupby(subset_df_sector, :Timeslice)
        subset_df_sum = combine(grouped_df, :Value => sum=>:Value)
        subset_df_sector = subset_df_sum
    end

    return subset_df_sector, sector_techno
end

# makes 3 dataframes: 1 with the storage charge, 1 with the storage discharge, and 1 with the production, excluding the storages
function separation_mo_storage(subset_df_sector)
    subset_df_production = subset_df_sector[.!occursin.("D_", subset_df_sector.Technology),:] 
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
function extraction_and_cleaning(extr_str, result_file, col_names, region, year, fuels; group_fuels=false, reduce_subset=true)
    in_data = CSV.read("test\\TestData\\Results\\$(result_file)_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)

    ## removing the 0 from the dataframe, so the data is smaller
    subset_df = in_data[(in_data.Region .== region) .&& (in_data.Year .== year),:]
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
    subset_df_sector, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, year, sector, inf_tech, reduce_subset = reduce_subset)
    fig = AbstractTrace[]
    df_dict = Dict()
    i = 1
    for t in unique(subset_df_sector.Technology)
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
                gdf_techno = groupby(subset_df_techno, "ModeOfOperation")
                for (mo, subdf) in pairs(gdf_techno)
                    println(t)
                    println(mo)

                    gdf = groupby(subdf, :Timeslice)
                    df_all_region = combine(gdf, :Value => sum=>:Value)

                    if display_plot
                        push!(fig, PlotlyJS.bar(x = subdf.Timeslice,
                        y = df_all_region.Value*year_split,
                        name=t,
                        marker_color=colors[i]))
                        i += 1
                    end
                    df_dict["$(t)_$(mo.ModeOfOperation)"] = df_all_region
                end
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

function plot_net_trade(extr_str, region, year, fuels)
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Value"]
    subset_df_fuels = extraction_and_cleaning(extr_str, "NetTrade", col_names, region, year, fuels)
    
    fig = AbstractTrace[]
    for f in fuels
        subset_df_fuel = subset_df_fuels[subset_df_fuels.Fuel.==f,:]
        push!(fig, PlotlyJS.bar(x = subset_df_fuel.Timeslice,
                    y = subset_df_fuel.Value,
                    name=f))
    end
    display(PlotlyJS.plot(fig, Layout(title="Net Trade in $(region) ($(extr_str))",
                        xaxis_title="Time (hours)",
                        yaxis_title="Net Trade (PJ)",
                        barmode="stack"),
                        config=PlotConfig(scrollZoom=true)))
end

function plot_demand(extr_str, tag_techno_sector, region, year, sector, inf_tech, fuels;display_fig=true, plot_prices = false, considered_dual=nothing, year_split=1/8760)
    fig = AbstractTrace[]
    dict_demand = Dict()
    ## 1. Curtailment
    col_names = ["Region", "Timeslice", "Technology", "Year", "Value"]
    subset_df_curtailment, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"CurtailedCapacity", col_names, region, year, sector, inf_tech, group_techno=true)
    gdf = groupby(subset_df_curtailment, :Timeslice)
    df_all_region = combine(gdf, :Value => sum=>:Value)
    
    push!(fig, PlotlyJS.bar(x = subset_df_curtailment.Timeslice,
                    y = -df_all_region.Value*31.56*year_split,
                    name="Curtailment"))
    dict_demand["Curtailment"] = -df_all_region.Value*31.56*year_split

    ## 2. Export
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_export = extraction_and_cleaning(extr_str, "Export", col_names, region, year, fuels, group_fuels = true)
    gdf = groupby(subset_df_export, :Timeslice)
    df_all_region = combine(gdf, :Value => sum=>:Value)
    push!(fig, PlotlyJS.bar(x = subset_df_export.Timeslice,
    y = -df_all_region.Value,
    name = "Exports"))
    dict_demand["Exports"] = -df_all_region.Value

    ## 3. Total production including charge / discharge of the storage
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    added_tech = []
    for t in inf_tech
        if startswith(t, "D_")
            push!(added_tech, t)
        end
    end
    subset_df, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, year, sector, added_tech)
    print(subset_df)
    subset_df_production, subset_df_charge, subset_df_discharge = separation_mo_storage(subset_df)
    timeslices = subset_df_production.Timeslice
    
    gdf = groupby(subset_df_discharge, :Timeslice)
    df_all_region = combine(gdf, :Value => sum=>:Value)

    push!(fig, PlotlyJS.bar(x = subset_df_production.Timeslice,
    y = df_all_region.Value * year_split,
    name = "Storage discharge"))
    dict_demand["StorageDischarge"] = df_all_region.Value * year_split

    gdf = groupby(subset_df_production, :Timeslice)
    df_all_region = combine(gdf, :Value => sum=>:Value)

    push!(fig, PlotlyJS.bar(x = subset_df_production.Timeslice,
    y = df_all_region.Value * year_split,
    name = "Production"))
    dict_demand["Production"] = df_all_region.Value * year_split

    gdf = groupby(subset_df_charge, :Timeslice)
    df_all_region = combine(gdf, :Value => sum=>:Value)
    
    push!(fig, PlotlyJS.bar(x = subset_df_charge.Timeslice,
    y = -df_all_region.Value * year_split,
    name = "Storage charge"))
    dict_demand["StorageCharge"] = -df_all_region.Value * year_split

    ## 4. Infeasibility
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    real_inf_tech = []
    for t in inf_tech
        if startswith(t, "Infeasibility")
            push!(real_inf_tech,t)
        end
    end
    subset_df_inf, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, year, sector, inf_tech, group_techno=true, defined_sector_techno = real_inf_tech)

    gdf = groupby(subset_df_inf, :Timeslice)
    df_all_region = combine(gdf, :Value => sum=>:Value)

    push!(fig, PlotlyJS.bar(x = subset_df_inf.Timeslice,
    y = df_all_region.Value*year_split,
    name="Infeasible"))
    dict_demand["Infeasible"] = df_all_region.Value*year_split

    ## 5. Import
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_import = extraction_and_cleaning(extr_str, "Import", col_names, region, year, fuels, group_fuels = true)

    gdf = groupby(subset_df_import, :Timeslice)
    df_all_region = combine(gdf, :Value => sum=>:Value)

    push!(fig, PlotlyJS.bar(x = subset_df_import.Timeslice,
    y = df_all_region.Value,
    name = "Imports"))
    dict_demand["Imports"] = df_all_region.Value

    ## 6. Dual
    if plot_prices
        prices = plot_duals([extr_str], region, year, considered_dual = considered_dual, display_plot=false)
        for (fuel, price) in prices
            price_year = price[price.Year .== year,:]
            push!(fig, PlotlyJS.scatter(x=timeslices, y = price_year.Value*(31.536/8760)*1000, name="Dual $(fuel)", yaxis="y2"))
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
    return subset_df_storages


end

function plot_duals(extr_str_list, region, year; considered_dual=nothing, display_plot=true)
    fig = AbstractTrace[]
    results_data = Dict()
    for extr_str in extr_str_list
        in_data = read_dual_results(extr_str)
        considered_data = in_data
        if !isnothing(considered_dual)
            considered_data = in_data[in.(in_data.Fuel, Ref(considered_dual)),:]
        end 

        dual_gdf = groupby(considered_data,"Fuel")
        for (f,subdf) in pairs(dual_gdf)
            subdf_region = subdf[(subdf.Region .== region) .&& (subdf. Year .== year), :]
            push!(fig, PlotlyJS.scatter(x = subdf_region.Timeslice,
                        y = subdf_region.Value*(31.536/8760)*1000,
                        name= "$(f.Fuel)_$(extr_str)"))
            results_data["$(f.Fuel)_$(extr_str)"] = subdf_region
        end
    end
    if display_plot
        display(PlotlyJS.plot(fig, Layout(title="Energy Balance dual values for Region $(region) ($(extr_str))",
                        xaxis_title="Time (hours)",
                        yaxis_title="Cost(euros/MWh)"),
                        config=PlotConfig(scrollZoom=true)))
    end
    return results_data

end

function plot_period_comparison_roa(extr_str_list, period, region, year, tag_techno_sector, sector, inf_tech, colors; year_split=1/8760, name_list=nothing)
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
            push!(fig, PlotlyJS.bar(x = isnothing(name_list) ? extr_str_list : name_list,
            y = y,
            name=tech,
            marker_color=colors[i]))
            i+=1
        end
    end
    title = "Production in sector $(sector) of $(region) in period $(period)"
    if isnothing(region)
        title = "Production in sector $(sector) in Europe in period $(period)"
    end
    display(PlotlyJS.plot(fig, Layout(title=title,
    yaxis_title="Energy (PJ)",
    barmode="relative"),
    config=PlotConfig(scrollZoom=true)))
end

function plot_year_comparison_demand(extr_str_list, region, year, tag_techno_sector, sector, inf_tech, fuels; year_split=1/8760, name_list=nothing)
    values_list_dict = []
    fig = AbstractTrace[]
    for extr_str in extr_str_list
        values_dict = plot_demand(extr_str, tag_techno_sector, region, year, sector, inf_tech, fuels, year_split=year_split, display_fig=false)
        push!(values_list_dict, values_dict)
    end
    keys_dict = [keys(dict) for dict in values_list_dict]
    union_index = union(keys_dict...)
    for index in union_index
        y = []
        for value_dict in values_list_dict
            if haskey(value_dict, index)
                push!(y, sum(value_dict[index]))
            else
                push!(y, 0)
            end
        end
        if !iszero(y)
            push!(fig, PlotlyJS.bar(x = isnothing(name_list) ? extr_str_list : name_list,
            y = y,
            name=index
            ))
        end
    end
    title = "Energy demand in sector $(sector) for $(region) in the year $(year)"
    if isnothing(region)
        title = title = "Energy demand in sector $(sector) in Europe during the year $(year)"
    end
    display(PlotlyJS.plot(fig, Layout(title=title,
    yaxis_title="Energy (PJ)",
    barmode="relative"),
    config=PlotConfig(scrollZoom=true)))      
end

function plot_capacities(extr_str_list, region, year, tag_techno_sector, sector, colors;aggregate_techno=true)
    sector_techno = tag_techno_sector[tag_techno_sector.Sector .== sector, :].Technology
    dict_list = Dict[]
    for extr_str in extr_str_list
        col_names = ["Year", "Technology", "Region", "Value"]
        in_data = CSV.read("test\\TestData\\Results\\TotalCapacityAnnual_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)
        in_data_reduced = in_data[(in_data.Value .!= 0) .& (in_data.Region .== region) .& (in_data.Year .== year) .& in.(in_data.Technology, Ref(sector_techno)),: ]
        df_aggregated = in_data_reduced
        if aggregate_techno
            replace!(in_data_reduced.Technology, aggregation...)
            pop!(col_names)
            grouped_df = groupby(in_data_reduced, col_names)
            df_aggregated = combine(grouped_df, :Value => sum=>:Value)
        end
        capacities_dict = Dict(Pair.(df_aggregated.Technology, df_aggregated.Value))
        push!(dict_list, capacities_dict)
    end

    fig = AbstractTrace[]
    i = 1
    keys_dict = [keys(dict) for dict in dict_list]
    union_index = union(keys_dict...)
    for index in union_index
        y = []
        for dict in dict_list
            if haskey(dict, index)
                push!(y, sum(dict[index]))
            else
                push!(y, 0)
            end
        end
        if !iszero(y)
            push!(fig, PlotlyJS.bar(x = extr_str_list,
            y = y,
            name=index,
            marker_color=colors[i]
            ))
            i = i+1
        end
    end

    display(PlotlyJS.plot(fig, Layout(title="Computed capacities in region $(region) for sector $(sector)",
    yaxis_title="Capacity (GW)",
    barmode="stack"),
    config=PlotConfig(scrollZoom=true)))
end

function write_demand(extr_str, tag_techno_sector, region, year, sector, inf_tech, fuels; considered_dual=nothing, year_split=1/8760)
    ## 1. Curtailment
    col_names = ["Region", "Timeslice", "Technology", "Year", "Value"]
    subset_df_curtailment, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"CurtailedCapacity", col_names, region, year, sector, inf_tech, group_techno=true, reduce_subset=false)
    df = DataFrame("Timeslices_hours"=>subset_df_curtailment.Timeslice)
    df[:,:Curtailment_PJ] .= subset_df_curtailment.Value*31.56*year_split

    ## 2. Export
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_export = extraction_and_cleaning(extr_str, "Export", col_names, region, year, fuels, group_fuels = true, reduce_subset=false)
    df[:,:Exports_PJ] .= subset_df_export.Value

    ## 3. Total production including charge / discharge of the storage
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    subset_df, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, year, sector, [], reduce_subset=false)
    subset_df_production, subset_df_charge, subset_df_discharge = separation_mo_storage(subset_df)
    df[:,:Production_PJ] .= subset_df_production.Value * year_split
    df[:,:Storage_charge_PJ] .= subset_df_charge.Value * year_split

    ## 4. Infeasibility
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    subset_df_inf, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, year, sector, inf_tech, group_techno=true, defined_sector_techno = inf_tech, reduce_subset=false)
    df[:,:Infeasible_PJ] .= subset_df_inf.Value * year_split

    ## 5. Import
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_import = extraction_and_cleaning(extr_str, "Import", col_names, region, year, fuels, group_fuels = true, reduce_subset=false)
    df[:,:Imports_PJ] .= subset_df_import.Value

    ## 6. Dual
    df_dual = plot_duals(extr_str, region, year, considered_dual = considered_dual, display_plot=false)
    df_dual_region = df_dual[df_dual.Region .== region, :]
    gdf_fuel = groupby(df_dual_region, :Fuel)
    for (fuel, subdf) in pairs(gdf_fuel)
        df[:,"Dual_$(fuel.Fuel)_euro_per_MWh"] .= subdf.Value*(31.536/8760)*1000
    end

    ## write in a csv file
    CSV.write("demand_$(sector)_$(region)_$(extr_str).csv", df)
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

function compare_roa_in_time(extr_str1, extr_str2, tag_techno_sector,region, year, sector, inf_tech, colors; year_split=1/8760)
    df_dict1 = plot_roa(extr_str1, tag_techno_sector, region, year, sector, inf_tech, colors, year_split = year_split, display_plot = false, reduce_subset=false)
    df_dict2 = plot_roa(extr_str2, tag_techno_sector, region, year, sector, inf_tech, colors, year_split = year_split, display_plot = false, reduce_subset=false)

    keys1 = collect(keys(df_dict1))
    n_timeslice = size(df_dict1[keys1[1]].Value, 1)
    union_tech = union(keys(df_dict1), keys(df_dict2))
    i=1
    fig = AbstractTrace[]

    for tech in union_tech
        difference = zeros(n_timeslice)
        if haskey(df_dict1, tech)
            gdf = groupby(df_dict1[tech], :Timeslice)
            df_all_mo = combine(gdf, :Value => sum=>:Value)
            difference = difference .+ (df_all_mo.Value * year_split)
        end
        if haskey(df_dict2, tech)
            gdf = groupby(df_dict2[tech], :Timeslice)
            df_all_mo = combine(gdf, :Value => sum=>:Value)
            difference = difference .- (df_all_mo.Value * year_split)
        end
        if !iszero(difference)
            push!(fig, PlotlyJS.bar(x = 1:n_timeslice,
                                y = difference,
                                name=tech,
                                marker_color=colors[i]))
            i = i+1
        end
    end
    display(PlotlyJS.plot(fig, Layout(title="Energy production comparison between $(extr_str1) and $(extr_str2)",
    xaxis_title="Time (hours)",
    yaxis_title="Production (PJ)",
    barmode="relative"),
    config=PlotConfig(scrollZoom=true)))
end

function plot_price_and_dummy(extr_str, tag_techno_sector,region, year, sector, inf_tech, colors; year_split=1/8760, display_plot=true, considered_dual = [sector])
    col_names = ["Region", "Timeslice", "Technology", "Year", "Value"]
    subset_df_sector, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"DispatchDummy", col_names, region, year, sector, inf_tech, reduce_subset = false)
    fig = AbstractTrace[]
    df_dict = Dict()
    i = 1
    timeslices = []
    for t in sector_techno
        subset_df_techno = subset_df_sector[(subset_df_sector.Technology.==t),:]
        timeslices = subset_df_techno.Timeslice
        if !isempty(subset_df_techno)
            if display_plot
                push!(fig, PlotlyJS.bar(x = subset_df_techno.Timeslice,
                y = (subset_df_techno.Value/31.536)*1000,
                name=t,
                marker_color=colors[i]))
                i += 1
            end
            df_dict[t] = subset_df_techno
        end 
    end

    prices = plot_duals([extr_str], region, year, considered_dual = considered_dual, display_plot=false)
    for (fuel, price) in prices
        push!(fig, PlotlyJS.scatter(x=timeslices, y = price.Value*(31.536/8760)*1000, name="Dual $(fuel)", yaxis="y2"))
    end

    storages = plot_storage_status(extr_str, region, year, considered_storages=["S_Gas_H2"])
    push!(fig, PlotlyJS.scatter(x=timeslices, y=storages.Value*1000, name="H2 Storage No unit"))
    if display_plot
        display(PlotlyJS.plot(fig, Layout(title="Available capacity in $(region) for sector $(sector) ($(extr_str))",
                                xaxis_title="Time (hours)",
                                yaxis_title="Available capacity (MW)",
                                yaxis2=attr(title="Cost (€/MWh)", overlaying="y", side="right"),
                                barmode="relative"),
                                config=PlotConfig(scrollZoom=true)))
    end
    return df_dict
end


function peaking_production(extr_str_list, tag_techno_sector, region, year, sector, inf_tech;year_split=1/8760, write_results=false, id=nothing)
    added_tech = []
    roa_dict = Dict()
    for t in inf_tech
        if startswith(t, "D_")
            push!(added_tech, t)
        end
    end
    for extr_str in extr_str_list
        # computing the argmax of the production (max_timeslice)
        col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
        subset_df, sector_techno = extraction_and_cleaning(extr_str, tag_techno_sector,"RateOfActivity", col_names, region, year, sector, inf_tech)
        subset_df_production, subset_df_charge, subset_df_discharge = separation_mo_storage(subset_df)
        rename!(subset_df_production, [:Timeslice, :Value_Production])
        rename!(subset_df_discharge, [:Timeslice, :Value_Discharge])
        subset_df_total = coalesce.(outerjoin(subset_df_production, subset_df_discharge, on = :Timeslice),0)
        subset_df_total[!, "Value"] = subset_df_total[!, "Value_Production"] + subset_df_total[!, "Value_Discharge"]
        argmax_production = argmax(subset_df_total.Value)
        max_timeslice = subset_df_total.Timeslice[argmax_production]

        # finding the roa at this timeslice + roa of discharging
        subset_df_max = subset_df[subset_df.Timeslice .== max_timeslice,:]
        rename!(subset_df_max, :Value => "Value_$(extr_str)_production")
        # value in GWh
        subset_df_max[!, "Value_$(extr_str)_production"] = subset_df_max[!, "Value_$(extr_str)_production"] * year_split * 8760/31.536

        # computing the ratio capacity used / total capacity
        col_names_capacity = ["Year", "Technology", "Region", "Value"]
        capacities_tmp, _ = extraction_and_cleaning(extr_str, tag_techno_sector, "TotalCapacityAnnual", col_names_capacity, region, year, sector, inf_tech)
        rename!(capacities_tmp, :Value => :Value_capacity)
        subset_df_max = coalesce.(leftjoin(subset_df_max, capacities_tmp, on = [:Year, :Technology, :Region]),0)
        subset_df_max[!, "Ratio_$(extr_str)"] = subset_df_max[:,"Value_$(extr_str)_production"]./subset_df_max.Value_capacity
        print(subset_df_max)

        roa_dict[extr_str] = select(subset_df_max, Not([:Timeslice]))

    end
    df_sum = roa_dict[pop!(extr_str_list)]
    for extr_str in extr_str_list
        df_sum = coalesce.(outerjoin(df_sum, roa_dict[extr_str], on = [:Technology, :ModeOfOperation, :Region, :Year], makeunique=true), 0)
    end
    col_name_production = [name for name in names(df_sum) if occursin("production", name)]
    df_sum[!, "Value_sum"] = sum(df_sum[!, col_name] for col_name in col_name_production)
    println(df_sum)
    if write_results
        CSV.write("..//Results//peaking_production_$(id).csv", df_sum)
    end
    return df_sum
end

function plot_peaking_production(list_extr_str_list, name_list, tag_techno_sector, region, year, sector, inf_tech;year_split=1/8760)
    fig = AbstractTrace[]
    i=1
    for extr_str_list in list_extr_str_list
        df_peaking_production = peaking_production(extr_str_list, tag_techno_sector, region, year, sector, inf_tech, year_split=year_split)
        push!(fig, PlotlyJS.bar(x = df_peaking_production.Technology,
        y = df_peaking_production.Value_sum,
        name=name_list[i]
        ))
        i+=1
        fig2 = AbstractTrace[]
        ratio_list = [ratio for ratio in names(df_peaking_production) if startswith(ratio, "Ratio")]
        for ratio in ratio_list
            push!(fig2, PlotlyJS.bar(x = df_peaking_production.Technology,
            y = df_peaking_production[!,ratio],
            name=last(split(ratio,"_"))
            ))
        end
        
        display(PlotlyJS.plot(fig2, Layout(title="Ratio between peaking production and available capacity",
                                xaxis_title="Technologies",
                                yaxis_title="Ratio"
                                ),
                                config=PlotConfig(scrollZoom=true)))
    end
    display(PlotlyJS.plot(fig, Layout(title="Peaking production in $(region) for sector $(sector)",
                                xaxis_title="Technologies",
                                yaxis_title="Production (GWh)"
                                ),
                                config=PlotConfig(scrollZoom=true)))
end

function plot_production_capacities(list_extr_str_list, name_list, tag_techno_sector, region, year, sector, fuels, inf_tech;year_split=1/8760)
    fig1 = AbstractTrace[]
    fig2 = AbstractTrace[]
    i=1
    for extr_str_list in list_extr_str_list
        df_production_capacities = capacities_production_sum(extr_str_list,region, year, fuels, tag_techno_sector, sector, inf_tech)
        push!(fig1, PlotlyJS.bar(x = df_production_capacities.Technology,
        y = df_production_capacities.Capacities_sum,
        name=name_list[i]
        ))
        push!(fig2, PlotlyJS.bar(x = df_production_capacities.Technology,
        y = df_production_capacities.Production_sum,
        name=name_list[i]
        ))
        i+=1
    end
    display(PlotlyJS.plot(fig1, Layout(title="Capacities in $(region) for sector $(sector)",
                                xaxis_title="Technologies",
                                yaxis_title="Capacity (GW)"
                                ),
                                config=PlotConfig(scrollZoom=true)))
    display(PlotlyJS.plot(fig2, Layout(title="Total annual production in $(region) for sector $(sector)",
    xaxis_title="Technologies",
    yaxis_title="Production (GWh)"
    ),
    config=PlotConfig(scrollZoom=true)))
    
end

function production_sum(extr_str_list,region, year, fuels)
    col_names = ["Year", "Technology", "Fuel", "Region", "Value"]
    production = 0
    for extr_str in extr_str_list
        df = extraction_and_cleaning(extr_str, "ProductionByTechnologyAnnual", col_names, region, year, fuels)
        production += sum(df.Value)
    end
    return production * 0.0036
end

function capacities_production_sum(extr_str_list,region, year, fuels, tag_techno_sector, sector, inf_tech; write_results=false, id=nothing)
    # production in GWh and capacities in GW
    col_names_production = ["Year", "Technology", "Fuel", "Region", "Value"]
    col_names_capacity = ["Year", "Technology", "Region", "Value"]
    extr_str1 = pop!(extr_str_list)
    df_total = select(extraction_and_cleaning(extr_str1, "ProductionByTechnologyAnnual", col_names_production, region, year, fuels), Not(:Fuel))
    inf_tech_wo_inf = [tech for tech in inf_tech if !startswith(tech, "Infeasibility")]
    print(inf_tech_wo_inf)
    df_capacities, _ = extraction_and_cleaning(extr_str1, tag_techno_sector, "TotalCapacityAnnual", col_names_capacity, region, year, sector, inf_tech_wo_inf)
    print(df_capacities)
    df_total.Value = df_total.Value / 0.0036
    rename!(df_total, :Value => :Value_Production)
    rename!(df_capacities, :Value => :Value_Capacities)
    df_total = coalesce.(leftjoin(df_total, df_capacities, on = [:Year, :Technology, :Region]),0)
     
    for extr_str in extr_str_list
        col_names_production = ["Year", "Technology", "Fuel", "Region", "Value"]
        col_names_capacity = ["Year", "Technology", "Region", "Value"]
        production_tmp = select(extraction_and_cleaning(extr_str, "ProductionByTechnologyAnnual", col_names_production, region, year, fuels), Not(:Fuel))
        production_tmp.Value = production_tmp.Value / 0.0036
        capacities_tmp, _ = extraction_and_cleaning(extr_str, tag_techno_sector, "TotalCapacityAnnual", col_names_capacity, region, year, sector, inf_tech_wo_inf)
        rename!(production_tmp, :Value => :Value_Production)
        rename!(capacities_tmp, :Value => :Value_Capacities)

        df_total = coalesce.(outerjoin(df_total, capacities_tmp, on = [:Year, :Technology, :Region], makeunique=true), 0)
        df_total = coalesce.(leftjoin(df_total, production_tmp, on = [:Year, :Technology, :Region], makeunique=true), 0)
    end
    print(df_total)
    
    col_name_capacities = [name for name in names(df_total) if occursin("Capacities", name)]
    col_name_production = [name for name in names(df_total) if occursin("Production", name)]
    df_total[!, "Capacities_sum"] = sum(df_total[!, col_name] for col_name in col_name_capacities)
    df_total[!, "Production_sum"] = sum(df_total[!, col_name] for col_name in col_name_production)
    if write_results
        CSV.write("..//Results//capacities_production_$(id).csv", df_total)
    end
    return df_total
end

function max_use_capacities(extr_str, tag_techno_sector,region, year, sector, inf_tech; year_split=1/8760)
    colors = []
    df_roa = plot_roa(extr_str, tag_techno_sector, region, year, sector, inf_tech, colors, year_split= year_split, display_plot=false)
    max_used_capacity = Dict()
    for tech in keys(df_roa)
        max_used_capacity[tech] = maximum(df_roa[tech].Value)*year_split * 8760 / 31.536
    end
    return max_used_capacity
end

function plot_emissions(extr_str_list, sectors, years; name_list=nothing)
    col_names = ["Year", "Emissions", "Sector", "Region", "Value"]
    fig = AbstractTrace[]
    in_data_dict = Dict()
    for extr_str in extr_str_list
        in_data = CSV.read("test\\TestData\\Results\\AnnualSectoralEmissions_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)
        in_data_dict[extr_str] = in_data
    end
    if isnothing(name_list)
        name_list = extr_str_list
    end
    for sector in sectors
        y = []
        for extr_str in extr_str_list
            for year in years
                in_data = in_data_dict[extr_str]
                in_data_sector = in_data[(in_data.Sector .== sector) .& (in_data.Year .== year),:]
                push!(y, sum(in_data_sector.Value))
            end
        end
        push!(fig, PlotlyJS.bar(x = name_list,
        y = y,
        name=sector
        ))
    end
    y = []
    for extr_str in extr_str_list
        for year in years
            in_data = in_data_dict[extr_str]
            in_data_other_sectors = in_data[.!in.(in_data.Sector,Ref(sectors)) .& (in_data.Year .== year),:]
            push!(y, sum(in_data_other_sectors.Value))
        end
    end
    push!(fig, PlotlyJS.bar(x = name_list,
        y = y,
        name="Other"
        ))

    display(PlotlyJS.plot(fig, Layout(title="Annual CO2 emissions in Europe in $(years)",
    xaxis_title="Taxation scenario",
    yaxis_title="Annual CO2 emissions (MtCO2 eq)",
    barmode="relative"
    ),
    config=PlotConfig(scrollZoom=true)))


end

function plot_accumulated_emissions(extr_str_list, sectors; name_list=nothing)
    col_names = ["Year", "Emissions", "Sector", "Region", "Value"]
    fig = AbstractTrace[]
    in_data_dict = Dict()
    for extr_str in extr_str_list
        in_data = CSV.read("test\\TestData\\Results\\AnnualSectoralEmissions_minimal_MinimalExample_globalLimit_$(extr_str).csv", DataFrame, header=col_names, skipto=2)
        in_data_dict[extr_str] = in_data
    end
    if isnothing(name_list)
        name_list = extr_str_list
    end
    for sector in sectors
        y = []
        for extr_str in extr_str_list
            in_data = in_data_dict[extr_str]
            in_data_sector = in_data[(in_data.Sector .== sector),:]
            push!(y, sum(in_data_sector.Value))
        end
        push!(fig, PlotlyJS.bar(x = name_list,
        y = y,
        name=sector
        ))
    end
    y = []
    for extr_str in extr_str_list
        in_data = in_data_dict[extr_str]
        in_data_other_sectors = in_data[.!in.(in_data.Sector,Ref(sectors)),:]
        push!(y, sum(in_data_other_sectors.Value))
    end
    push!(fig, PlotlyJS.bar(x = name_list,
        y = y,
        name="Other"
        ))

    display(PlotlyJS.plot(fig, Layout(title="Annual CO2 emissions in Europe from 2018 to 2050",
    xaxis_title="Taxation scenario",
    yaxis_title="Annual CO2 emissions (MtCO2 eq)",
    barmode="relative"
    ),
    config=PlotConfig(scrollZoom=true)))


end