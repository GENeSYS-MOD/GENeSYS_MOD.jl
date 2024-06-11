using XLSX
using DataFrames
using Colors
using ColorSchemes

include("plot_dispatch.jl")


## Loading the dispatch data (rate of activity) and the tag to sector data, to keep the data of only one sector
input_data_model = XLSX.readxlsx("test\\TestData\\Inputs\\RegularParameters_Europe_openENTRANCE_technoFriendly.xlsx")
tag_techno_sector = DataFrame(XLSX.gettable(input_data_model["Par_TagTechnologyToSector"]))

year_split=1/350
# colors = palette(:tab20)
colors = distinguishable_colors(25)

## Plot for power sector ##
# extr_str = "dispatch2"
# extr_str = "DE_dispatch"
# extr_str = "one_node_storage_new_demand"
# extr_str = "one_node_storage_30"
# extr_str = "two_nodes_30"
# extr_str = "DE_run_10"
# extr_str = "one_node_10"
# extr_str = "full_run_30"
# extr_str_list = ["one_node_storage_04", "two_nodes_new_demand", "one_node_new_demand"]
# extr_str_list = ["two_nodes_30", "one_node_storage_30"]
extr_str_list = ["run_FR_Nice", "run_FR_Paris"]
extr_str = "run_FR_Nice"

tag_techno_sector[tag_techno_sector.Technology .== "D_Battery_Li-Ion",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_Battery_Redox",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_CAES",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_PHS",:Sector] .= "Power"
# plot_roa(extr_str, tag_techno_sector,"DE",2050, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], colors, year_split = year_split)
# plot_roa(extr_str, tag_techno_sector,"DE",2050, "Power", ["Infeasibility_Power"], colors)
# plot_net_trade(extr_str, "DE",["Power"])
# plot_demand(extr_str, tag_techno_sector, "DE", 2050, "Power", ["Infeasibility_Power"], ["Power"], plot_prices=true, considered_dual=["Power"], year_split=year_split)
# plot_demand(extr_str, tag_techno_sector, "DE", 2050, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], ["Power"])
# plot_storage_status(extr_str, "DE")
# plot_duals(extr_str, "DE")
# plot_period_comparison_roa(extr_str_list, 7000:8760, "DE", 2050, tag_techno_sector, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], colors)
# plot_capacities("dispatch2", "DE_dispatch", "DE", tag_techno_sector, "Power", colors)
# write_demand(extr_str, tag_techno_sector, "DE", "Power", ["Infeasibility_Power"], ["Power"], considered_dual=["Power"])
# plot_year_comparison_demand(extr_str_list, "DE", tag_techno_sector, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], ["Power"])

## Plot for residential heating sector ##

tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLR",:Sector] .= "Buildings"
tag_techno_sector[tag_techno_sector.Technology .== "D_Gas_H2",:Sector] .= "Buildings"
# plot_roa(extr_str, tag_techno_sector,"DE","Buildings", ["Infeasibility_HRI"], colors)
# plot_net_trade(extr_str, "DE",["Heat_Low_Residential", "Biomass", "Gas_Natural"])
plot_demand(extr_str, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential"], plot_prices=true, considered_dual=["HeatLowResidential", "Power"], year_split=year_split)
# plot_demand(extr_str, tag_techno_sector, "DE", "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential"])
# plot_RE_heat(extr_str, tag_techno_sector, "DE", ["Infeasibility_Power"], colors)
# plot_period_comparison_roa(extr_str_list, 1:350, "FR", 2050, tag_techno_sector, "Buildings", ["Infeasibility_HRI"], colors)
# plot_year_comparison_demand(extr_str_list, "DE", tag_techno_sector, "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential"])

## Plot for industrial heating sector ##

tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLI",:Sector] .= "Industry"
# plot_roa(extr_str, tag_techno_sector,"DE","Industry", ["Infeasibility_HLI", "Infeasibility_HMI", "Infeasibility_HHI"], colors)
# plot_demand(extr_str, tag_techno_sector, "DE", "Industry", ["Infeasibility_HLI", "Infeasibility_HMI", "Infeasibility_HHI"], ["Heat_Low_Industrial", "Heat_High_Industrial", "Heat_Medium_Industrial"], plot_prices = true, considered_dual=["HeatLowIndustrial", "HeatHighIndustrial", "HeatMediumIndustrial"])