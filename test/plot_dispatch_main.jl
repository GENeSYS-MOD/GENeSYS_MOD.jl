using XLSX
using DataFrames
using Colors
using ColorSchemes

include("plot_dispatch.jl")


## Loading the dispatch data (rate of activity) and the tag to sector data, to keep the data of only one sector
input_data_model = XLSX.readxlsx("test\\TestData\\Inputs\\RegularParameters_Europe_openENTRANCE_technoFriendly.xlsx")
tag_techno_sector = DataFrame(XLSX.gettable(input_data_model["Par_TagTechnologyToSector"]))

year_split=1/8760
# colors = palette(:tab20)
colors = distinguishable_colors(25)

## Plot for power sector ##
# extr_str = "dispatch2"
extr_str = "DE_dispatch"

tag_techno_sector[tag_techno_sector.Technology .== "D_Battery_Li-Ion",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_Battery_Redox",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_CAES",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_PHS",:Sector] .= "Power"
# plot_roa(extr_str, tag_techno_sector,"DE","Power", ["Infeasibility_Power"], colors)
# plot_net_trade(extr_str, "DE",["Power"])
# plot_demand(extr_str, tag_techno_sector, "DE", "Power", ["Infeasibility_Power"], ["Power"], plot_prices=true, considered_dual=["Power"])
# plot_demand(extr_str, tag_techno_sector, "DE", "Power", ["Infeasibility_Power"], ["Power"])
# plot_storage_status(extr_str, "DE")
# plot_duals(extr_str, "DE")
# plot_period_comparison_roa("dispatch2", "DE_dispatch", 1:2000, "DE", tag_techno_sector, "Power", ["Infeasibility_Power"], colors)
# plot_capacities("dispatch2", "DE_dispatch", "DE", tag_techno_sector, "Power", colors)
write_demand(extr_str, tag_techno_sector, "DE", "Power", ["Infeasibility_Power"], ["Power"], considered_dual=["Power"])

## Plot for residential heating sector ##

tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLR",:Sector] .= "Buildings"
# plot_roa(extr_str, tag_techno_sector,"DE","Buildings", ["Infeasibility_HRI"], colors)
# plot_net_trade(extr_str, "DE",["Heat_Low_Residential", "Biomass", "Gas_Natural"])
# plot_demand(extr_str, tag_techno_sector, "DE", "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential"], plot_prices=true, considered_dual=["Heat_Low_Residential"])
# plot_demand(extr_str, tag_techno_sector, "DE", "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential"])

## Plot for industrial heating sector ##

tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLI",:Sector] .= "Industry"
# plot_roa(extr_str, tag_techno_sector,"DE","Industry", ["Infeasibility_HLI", "Infeasibility_HMI", "Infeasibility_HHI"], colors)
# plot_demand(extr_str, tag_techno_sector, "DE", "Industry", ["Infeasibility_HLI", "Infeasibility_HMI", "Infeasibility_HHI"], ["Heat_Low_Industrial", "Heat_High_Industrial", "Heat_Medium_Industrial"], plot_prices = true, considered_dual=["Heat_Low_Industrial", "Heat_High_Industrial", "Heat_Medium_Industrial"])