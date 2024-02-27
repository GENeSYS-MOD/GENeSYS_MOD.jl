# GENeSYS-MOD v3.1 [Global Energy System Model]  ~ March 2022
#
# #############################################################
#
# Copyright 2020 Technische Universit�t Berlin && DIW Berlin
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
# See the License for the specific language governing permissions &&
# limitations under the License.
#
# #############################################################

"""
Internal function used in the run pårocess to compute results. 
It also runs the functions for processing emissions and levelized costs.
"""

using CSV
using DataFrames
using PlotlyJS
    
# Read the CSV file into a DataFrame
dfp = CSV.read("/Users/dozeumhaj/Nextcloud/Projekte/LOTR/Results/output_annual_production_MiddleEarth_Gondor_globalLimit_364_dispatch.csv", DataFrame)

# Remove whitespace from column names
rename!(dfp, Symbol.(map(x -> strip(string(x)), names(dfp))))  # Convert column names to strings, strip whitespace, and convert back to symbols
dfp[!, :Value_twh] = dfp.Value / 3.6  # create TWh column
# Check the first few rows of the DataFrame to ensure data integrity
first(dfp, 5)
#group technologies
df=dfp
function group_technologies(df)
    df[!, :Technology_grouped] = df[!, :Technology]

    # Grouping technologies
    replacements = Dict(
        "D_Battery_Li-Ion" => "Storages",
        "D_PHS" => "Storages",
        "D_PHS_Residual" => "Storages",
        "HLI_Biomass_CHP" => "Biomass",
        "HLI_Biomass" => "Biomass",
        "HLR_Biomass" => "Biomass",
        "P_Biomass" => "Biomass",
        "P_Biomass_CCS" => "Biomass",
        "P_Gas_CCGT" => "Gas",
        "P_Gas_Engines" => "Gas",
        "P_Gas_OCGT" => "Gas",
        "P_Gas" => "Gas",
        "CHP_Gas_CCGT_Natural" => "Gas",
        "X_Electrolysis" => "Electrolysis",
        "HLI_Hardcoal_CHP" => "Hardcoal",
        "CHP_Coal_Hardcoal" => "Hardcoal",
        "CHP_Coal_Lignite" => "Hardcoal",
        "P_Coal_Hardcoal" => "Hardcoal",
        "Z_Import_Hardcoal" => "Hardcoal",
        "RES_Ocean" => "Ocean",
        "RES_Hydro_Dispatchable" => "Hydropower",
        "RES_Hydro_RoR" => "Hydropower",
        "RES_Hydro_Small" => "Hydropower",
        "RES_Hydro_Large" => "Hydropower",
        "RES_Grass" => "Biomass", ###
        "RES_Residues" => "Biomass", ###
        "RES_Wood" => "Biomass", ###
        "P_Coal_Lignite" => "Lignite",
        "P_Oil" => "Oil",
        "P_Nuclear" => "Nuclear",
        "RES_CSP" => "Solar PV",
        "RES_PV_Utility_Avg" => "Solar PV",
        "RES_PV_Utility_Inf" => "Solar PV",
        "RES_PV_Utility_Opt" => "Solar PV",
        "RES_PV_Utility_Opt_H2" => "Solar PV",
        "Res_PV_Utility_Tracking" => "Solar PV",
        "RES_PV_Rooftop_Commercial" => "Solar PV",
        "RES_PV_Rooftop_Residential" => "Solar PV",
        "RES_Wind_Offshore_Deep" => "Wind Offshore",
        "RES_Wind_Offshore_Shallow" => "Wind Offshore",
        "RES_Wind_Offshore_Shallow_H2" => "Wind Offshore",
        "RES_Wind_Offshore_Transitional" => "Wind Offshore",
        "RES_Wind_Onshore_Avg" => "Wind Onshore",
        "RES_Wind_Onshore_Inf" => "Wind Onshore",
        "RES_Wind_Onshore_Opt" => "Wind Onshore",
        "RES_Wind_Onshore_Opt_H2" => "Wind Onshore",
        "FRT_Rail_Electric" => "Demand [Transport]",
        "FRT_Rail_Conv" => "Demand [Transport]",
        "FRT_Road_BEV" => "Demand [Transport]",
        "FRT_Road_ICE" => "Demand [Transport]",
        "FRT_Road_PHEV" => "Demand [Transport]",
        "FRT_Road_OH" => "Demand [Transport]",
        "FRT_Ship_EL" => "Demand [Transport]",
        "FRT_Ship_Bio" => "Demand [Transport]",
        "FRT_Ship_Conv" => "Demand [Transport]",
        "PSNG_Rail_Electric" => "Demand [Transport]",
        "PSNG_Rail_Conv" => "Demand [Transport]",
        "PSNG_Road_BEV" => "Demand [Transport]",
        "PSNG_Road_PHEV" => "Demand [Transport]",
        "PSNG_Road_H2" => "Demand [Transport]",
        "PSNG_Road_ICE" => "Demand [Transport]",
        "PSNG_Air_Conv" => "Demand [Transport]",
        "PSNG_Air_H2" => "Demand [Transport]",
        "HLR_Direct_Electric" => "Demand [Buildings]",
        "HLR_Gas_Boiler" => "Demand [Buildings]",###
        "HLR_H2_Boiler" => "Demand [Buildings]",###
        "HLR_Hardcoal" => "Demand [Buildings]",###
        "HLR_Heatpump_Aerial" => "Demand [Buildings]",
        "HLR_Heatpump_Ground" => "Demand [Buildings]",
        "Power_Demand_IHS_Commercial" => "Demand [Buildings]",
        "Power_Demand_IHS_Residential" => "Demand [Buildings]",
        "HHI_DRI_EAF" => "Demand [Industry]",
        "HHI_Molten_Electrolysis" => "Demand [Industry]",
        "HHI_Scrap_EAF" => "Demand [Industry]",
        "HLI_Direct_Electric" => "Demand [Industry]",
        "HLI_Gas_CHP" => "Demand [Industry]",
        "HLI_Gas_Boiler" => "Demand [Industry]",
        "HLI_H2_Boiler" => "Demand [Industry]",
        "HLI_Hardcoal" => "Demand [Industry]",
        "HMI_Biomass" => "Demand [Industry]",
        "HMI_Steam_Electric" => "Demand [Industry]",
        "HMI_Gas" => "Demand [Industry]",
        "HMI_Hardcoal" => "Demand [Industry]",
        "HMI_HardCoal" => "Demand [Industry]",
        "HHI_BF_BOF" => "Demand [Industry]",
        "HLI_Geothermal" => "Demand [Industry]",
        "HLI_Lignite" => "Demand [Industry]",
        "HLI_Solar_Thermal" => "Demand [Industry]",
        "Power_Demand_IHS_Industrial" => "Demand [Industry]",
        "X_Fuel_Cell" => "Demand [Industry]"
    )

    for key in keys(replacements)
        df[!, :Technology_grouped] = replace(df[!, :Technology_grouped], key => replacements[key])
    end

    return df
end

group_technologies(df)

# Print the resulting DataFrame
#println(df)
dfp=df 
# Create dataframe for electricity generation figure
dfp_elec = combine(groupby(dfp, [:Year, :Fuel, :Type, :Technology_grouped]), :Value_twh => sum)
    
# Filter for Power production
dfp_elec = combine(groupby(filter(row -> row.Fuel == "Power" && row.Type == "Production", dfp), [:Year, :Fuel, :Type, :Technology_grouped]), :Value_twh => sum)


show(dfp_elec, allrows=true, allcols=true)

#dfp_elec = combine(groupby(filter(row -> row.Technology_grouped != "Demand", dfp), [:Year, :Fuel, :Type, :Technology_grouped]), :Value_twh => sum)
#show(dfp_elec, allrows=true, allcols=true)

# Filter rows for electricity dispatch figure
#dfp_disp = combine(groupby(dfp, [:Year, :Fuel, :Type, :Technology_grouped]), :Value_twh => sum)
#dfp_disp = filter(row -> row[:Fuel] == "Power" && (row[:Category] in ["Power", "Industry", "Transformation", "Consuming"]) && (row[:Type] in ["Production", "Use"]) && row[:Year] == 2050, dfp)

tech_colors = Dict(
    "Solar PV" => "#ffeb3b",
    "Wind Offshore" => "#215968",
    "Wind Onshore" => "#518696",
    "Biomass" => "#7cb342",
    "Hydropower" => "#0c46a0",
    "Ocean" => "#a0cbe8",
    "Nuclear" => "#ae393f",
    "Oil" => "#252623",
    "Lignite" => "#754937",
    "Hardcoal" => "#5e5048",
    "Electrolysis" => "#28dddd",
    "Demand [Buildings]" => "#c3b4b2",
    "Demand [Industry]" => "#a39794",
    "Demand [Transport]" => "#a39794",
    "Gas" => "#e54213"
)


# Create an empty plot
elec_fig = Plot()

# Set the layout for the plot
layout!(elec_fig, Layout(title="Electricity Generation"))

# Add traces to the plot
for i in 1:length(dfp_elec.Technology_grouped)
    push!(elec_fig, 
        bar(
            x = dfp_elec.Year,
            y = dfp_elec.Value_twh_sum,
            marker_color = tech_colors[dfp_elec.Technology_grouped[i]],
            name = dfp_elec.Technology_grouped[i]
        )
    )
end

# Show the plot
display(elec_fig)



# Plot Electricity Generation
elec_fig = plot(
    x = dfp_elec.Year,
    y = dfp_elec[!, Symbol("Value_twh_sum")],
    marker_color = [tech_colors[tech] for tech in dfp_elec.Technology_grouped],
    name = dfp_elec.Technology_grouped,
    layout = Layout(
        title = "Electricity Generation"
    ),
    kind = "bar"
)

# Plot Electricity Generation
elec_fig = plot(
    layout = Layout(
        title = "Electricity Generation"
    )
)

for tech in unique(dfp_elec.Technology_grouped)
    dfp_tech = filter(row -> row[:Technology_grouped] == tech, dfp_elec)
    push!(elec_fig, bar(
        x = dfp_tech.Year,
        y = dfp_tech[!, Symbol("Value_twh_sum")],
        marker_color = tech_colors[tech],
        name = tech
    ))
end

# Plot Dispatch
disp_fig = plot(
    layout = Layout(
        title = "Electricity Dispatch"
    )
)

push!(disp_fig, bar(
    x = dfp_disp.Timeslice,
    y = dfp_disp[!, Symbol("Value_twh_sum")]
))

# Show plots
display(elec_fig)
display(disp_fig)




dfp_elec = filter(row -> row[:Fuel] == "Power" && (row[:Category] in ["Power", "Storages", "Transformation"]) && row[:Type] == "Production", dfp)
    
    # Create data frame for dispatch figure
    dfp_disp = combine(groupby(dfp, [:Year, :Fuel, :Type, :Category, :Technology_grouped, :Timeslice]), :Value_twh => sum)
    
    dfp_disp = filter(row -> row[:Fuel] == "Power" && (row[:Category] in ["Power", "Industry", "Transformation", "Consuming"]) && (row[:Type] in ["Production", "Use"]) && row[:Year] == 2050, dfp)
    
    tech_colors = Dict(
        "Solar PV" => "#ffeb3b",
        "Wind Offshore" => "#215968",
        "Wind Onshore" => "#518696",
        "Biomass" => "#7cb342",
        "Hydropower" => "#0c46a0",
        "Ocean" => "#a0cbe8",
        "Nuclear" => "#ae393f",
        "Oil" => "#252623",
        "Lignite" => "#754937",
        "Hardcoal" => "#5e5048",
        "Electrolysis" => "#28dddd",
        "Demand [Buildings]" => "#c3b4b2",
        "Demand [Industry]" => "#a39794",
        "Gas" => "#e54213"
    )
    
    # Plot Electricity Generation
    elec_fig = plot(
        layout = Layout(
            title = "Electricity Generation"
        )
    )
    
    for tech in dfp_elec.Technology_grouped
        push!(elec_fig, bar(
            x = dfp_elec.Year,
            y = dfp_elec[!, Symbol("Value_twh_sum")],
            marker_color = tech_colors[tech],
            name = tech
        ))
    end
    
    # Plot Dispatch
    disp_fig = plot(
        layout = Layout(
            title = "Electricity Dispatch"
        )
    )
    
    push!(disp_fig, bar(
        x = dfp_disp.Timeslice,
        y = dfp_disp[!, Symbol("Value_twh_sum")]
    ))
    
    # Show plots
    display(elec_fig)
    display(disp_fig)