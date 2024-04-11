import Pkg
cd("C:\\Users\\zoeb\\Documents\\dev\\Results")
Pkg.activate(".")
using JuMP
using CSV
using XLSX
using DataFrames
using Dates
using StatsPlots
using PlotlyJS

production_by_techno_df = CSV.read("output_annual_production_minimal_MinimalExample_globalLimit_dispatch.csv", DataFrame)
print(first(production_by_techno_df,5))

subset_df = production_by_techno_df[in.(production_by_techno_df.Region,Ref(["IT"])),:]

#subset_df = df_energy_balance[in.(df_energy_balance.Technology, Ref(tmp_techs)),:]
print(first(subset_df,5))

@df subset_df groupedbar(:Year, :Value, group=:Sector, bar_position=:stack)