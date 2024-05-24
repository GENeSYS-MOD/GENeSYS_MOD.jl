using CSV
using XLSX
using DataFrames
using PlotlyJS
using Plots
using StatsPlots

## Loading the dispatch data (rate of activity) and the tag to sector data, to keep the data of only one sector
input_data_model = XLSX.readxlsx("test\\TestData\\Inputs\\RegularParameters_Europe_openENTRANCE_technoFriendly.xlsx")
tag_techno_sector = DataFrame(XLSX.gettable(input_data_model["Par_TagTechnologyToSector"]))

# function when sectors are considered
function extraction_and_cleaning(tag_techno_sector, result_file, col_names, region, sector, inf_tech; defined_sector_techno=nothing, group_techno=false)
    in_data = CSV.read("test\\TestData\\Results\\$(result_file)_minimal_MinimalExample_globalLimit_dispatch2.csv", DataFrame, header=col_names, skipto=2)

    ## removing the 0 from the dataframe, so the data is smaller
    subset_df = in_data[in_data.Region .== region,:]
    subset_df_reduced = subset_df[subset_df.Value .!=0,:]

    sector_techno = defined_sector_techno
    ## array with all the considered technologies, including infeasibility tech
    if isnothing(defined_sector_techno)
        sector_techno = tag_techno_sector[tag_techno_sector.Sector .== sector, :].Technology
        sector_techno = vcat(sector_techno, inf_tech)
    end

    ## keeping only the sector technologies
    subset_df_sector = subset_df_reduced[in.(subset_df_reduced.Technology, Ref(sector_techno)),:]
    print(first(subset_df_sector, 5))
    
    ## summing over all the technologies for each timeslice
    if group_techno
        grouped_df = groupby(subset_df_sector, :Timeslice)
        subset_df_sum = combine(grouped_df, :Value => sum=>:Value)
        subset_df_sector = subset_df_sum
    end

    return subset_df_sector, sector_techno
end

# function when fuels are considered
function extraction_and_cleaning(result_file, col_names, region, fuels; group_fuels=false)
    in_data = CSV.read("test\\TestData\\Results\\$(result_file)_minimal_MinimalExample_globalLimit_dispatch2.csv", DataFrame, header=col_names, skipto=2)

    ## removing the 0 from the dataframe, so the data is smaller
    subset_df = in_data[in_data.Region .== region,:]
    subset_df_reduced = subset_df[subset_df.Value .!=0,:]

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


function plot_roa(tag_techno_sector,region, sector, inf_tech)
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    subset_df_sector, sector_techno = extraction_and_cleaning(tag_techno_sector,"RateOfActivity", col_names, region, sector, inf_tech)

    fig = AbstractTrace[]
    for t in sector_techno
        subset_df_techno = subset_df_sector[subset_df_sector.Technology.==t,:]
        push!(fig, PlotlyJS.bar(x = subset_df_techno.Timeslice,
                    y = subset_df_techno.Value/8760,
                    name=t))
    end
    PlotlyJS.plot(fig, Layout(title="Rate of activity in $(region) for sector $(sector)",
                                xaxis_title="Time (hours)",
                                yaxis_title="Rate of Activity (PJ)",
                                barmode="stack"),
                                config=PlotConfig(scrollZoom=true))
end

function plot_net_trade(region, fuels)
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Value"]
    subset_df_fuels = extraction_and_cleaning("NetTrade", col_names, region, fuels)
    
    fig = AbstractTrace[]
    for f in fuels
        subset_df_fuel = subset_df_fuels[subset_df_fuels.Fuel.==f,:]
        push!(fig, PlotlyJS.bar(x = subset_df_fuel.Timeslice,
                    y = subset_df_fuel.Value,
                    name=f))
    end
    PlotlyJS.plot(fig, Layout(title="Net Trade in $(region)",
                        xaxis_title="Time (hours)",
                        yaxis_title="Net Trade (PJ)",
                        barmode="stack"),
                        config=PlotConfig(scrollZoom=true))
end

function plot_demand(tag_techno_sector, region, sector, inf_tech, fuels;plot_prices = false, considered_dual=nothing)
    fig = AbstractTrace[]

    ## 1. Curtailment
    col_names = ["Region", "Timeslice", "Technology", "Year", "Value"]
    subset_df_curtailment, sector_techno = extraction_and_cleaning(tag_techno_sector,"CurtailedCapacity", col_names, region, sector, inf_tech, group_techno=true)
    push!(fig, PlotlyJS.bar(x = subset_df_curtailment.Timeslice,
                    y = -subset_df_curtailment.Value*31.56/8760,
                    name="Curtailment"))

    ## 2. Export
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_export = extraction_and_cleaning("Export", col_names, region, fuels, group_fuels = true)
    push!(fig, PlotlyJS.bar(x = subset_df_export.Timeslice,
    y = -subset_df_export.Value,
    name = "Exports"))

    ## 3. Total production
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    subset_df_production, sector_techno = extraction_and_cleaning(tag_techno_sector,"RateOfActivity", col_names, region, sector, [], group_techno=true)
    
    push!(fig, PlotlyJS.bar(x = subset_df_production.Timeslice,
    y = subset_df_production.Value/8760,
    name="Production"))

    ## 4. Infeasibility
    col_names = ["Year", "Timeslice", "Technology", "ModeOfOperation", "Region", "Value"]
    subset_df_inf, sector_techno = extraction_and_cleaning(tag_techno_sector,"RateOfActivity", col_names, region, sector, inf_tech, group_techno=true, defined_sector_techno = inf_tech)
    push!(fig, PlotlyJS.bar(x = subset_df_inf.Timeslice,
    y = subset_df_inf.Value/8760,
    name="Infeasible"))

    ## 5. Import
    col_names = ["Year", "Timeslice", "Fuel", "Region", "Region2","Value"]
    subset_df_import = extraction_and_cleaning("Import", col_names, region, fuels, group_fuels = true)
    push!(fig, PlotlyJS.bar(x = subset_df_import.Timeslice,
    y = subset_df_import.Value,
    name = "Imports"))

    ## 6. Dual
    if plot_prices
        df_dual = plot_duals(region, considered_dual = considered_dual, display_plot=false)
        df_dual_region = df_dual[df_dual.Region .== region, :]
        push!(fig, PlotlyJS.scatter(x=df_dual_region.Timeslice, y=df_dual_region.Value, name="Dual", yaxis="y2"))


        PlotlyJS.plot(fig, Layout(title="Energy demand in $(region) for sector $(sector) and fuels $(fuels)",
                        xaxis_title="Time (hours)",
                        yaxis_title="Energy (PJ)",
                        yaxis2=attr(title="Dual", overlaying="y", side="right"),
                        barmode="relative"), 
                        config=PlotConfig(scrollZoom=true))
    else
        PlotlyJS.plot(fig, Layout(title="Energy demand in $(region) for sector $(sector) and fuels $(fuels)",
                        xaxis_title="Time (hours)",
                        yaxis_title="Energy (PJ)",
                        barmode="relative"), 
                        config=PlotConfig(scrollZoom=true))
    end

end

function plot_storage_status(region; considered_storages=nothing)
    col_names = ["Storage", "Year", "Timeslice", "Region", "Value"]
    in_data = CSV.read("test\\TestData\\Results\\StorageLevelTSStart_minimal_MinimalExample_globalLimit_dispatch2.csv", DataFrame, header=col_names, skipto=2)

    ## removing the 0 from the dataframe, so the data is smaller
    subset_df = in_data[in_data.Region .== region,:]
    subset_df_reduced = subset_df[subset_df.Value .!=0,:]
    subset_df_storages = subset_df_reduced

    ## keeping only the considered storages
    if !isnothing(considered_storages)
        subset_df_storages = subset_df_reduced[in.(subset_df_reduced.Storage, Ref(considered_storages)),:]
    end

    fig = AbstractTrace[]
    gdf_storages = groupby(subset_df_storages, "Storage")
    for (s,subdf) in pairs(gdf_storages)
        push!(fig, PlotlyJS.bar(x = subdf.Timeslice,
                    y = subdf.Value,
                    name=s.Storage))
    end
    PlotlyJS.plot(fig, Layout(title="Storage Level at each beginning of time slice for Region $(region)",
                        xaxis_title="Time (hours)",
                        yaxis_title="Storage level (PJ)",
                        barmode="stack"),
                        config=PlotConfig(scrollZoom=true))


end

function plot_duals(region; considered_dual=nothing, display_plot=true)
    col_names = ["Name", "Fuel", "Timeslice", "Region", "Value"]
    in_data = CSV.read("test\\TestData\\Results\\Duals_minimal_MinimalExample_globalLimit_dispatch3.csv", DataFrame, header=col_names, skipto=2)
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
        PlotlyJS.plot(fig, Layout(title="Energy Balance dual values for Region $(region)",
                        xaxis_title="Time (hours)",
                        yaxis_title="Dual (price)"),
                        config=PlotConfig(scrollZoom=true))
    end
    return considered_data

end

# plot_roa(tag_techno_sector,"DE","Power", ["Infeasibility_Power"])
# plot_net_trade("DE",["Power"])
# plot_demand(tag_techno_sector, "DE", "Power", ["Infeasibility_Power"], ["Power"], plot_prices=true, considered_dual=["Power"])
# plot_storage_status("DE",)
# plot_duals("DE")

tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLR",:Sector] .= "Buildings"
# plot_roa(tag_techno_sector,"DE","Buildings", ["Infeasibility_HRI"])
# plot_net_trade("DE",["Heat_Low_Residential", "Biomass", "Gas_Natural"])
# plot_demand(tag_techno_sector, "DE", "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential"], plot_prices=true, considered_dual=["Heat_Low_Residential"])

