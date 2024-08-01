using XLSX
using DataFrames
using Colors
using ColorSchemes

include("plot_dispatch.jl")


## Loading the dispatch data (rate of activity) and the tag to sector data, to keep the data of only one sector
input_data_model = XLSX.readxlsx("test\\TestData\\Inputs\\RegularParameters_Europe_openENTRANCE_technoFriendly.xlsx")
tag_techno_sector = DataFrame(XLSX.gettable(input_data_model["Par_TagTechnologyToSector"]))

year_split=1/13
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
extr_str_list1 = ["dispatch_aggregation_Bordeaux", "dispatch_aggregation_Marseille", "dispatch_aggregation_Montpellier" , "dispatch_aggregation_Paris", "dispatch_aggregation_Lille", "dispatch_aggregation_Lyon",  "dispatch_aggregation_Nantes", "dispatch_aggregation_Strasbourg", "dispatch_aggregation_Nice", "dispatch_aggregation_Toulouse"]
extr_str_list2 = ["dispatch_aggregation_FR"]
list_extr_str_list = [extr_str_list1, extr_str_list2]
name_list = ["cities", "FR"]
# extr_str1 = "dispatch_FR_Aggregation"
# extr_str2 = "dispatch_FR_Nantes"
# extr_str = "run_aggregation_Lyon"
# extr_str1 = "full_run"
# extr_str2 = "full_run_increased"
extr_str_list = ["full_run", "full_run_increased"]
# country = "FR"
# extr_str = "dispatch_aggregation_$(country)"
# extr_str = "run_aggregation_Nantes"
# extr_str = "dispatch_ES"
# extr_str_list = ["dispatch_ES"]
# country = "NO"
# , "dispatch_IT", "dispatch_DE_test", "dispatch_NO_test", "dispatch_aggregation_FR"]
# extr_str_list = ["dispatch_two_nodes_DE", "simple_dispatch_DE", "storage_dispatch_DE"]
# extr_str_list = ["full_run_tax_$(i)" for i in 0:7]
extr_str = "full_run_tax_7"
# extr_str = "dispatch_representative_Paris"
# extr_str_list = ["full_run"]

tag_techno_sector[tag_techno_sector.Technology .== "D_Battery_Li-Ion",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_Battery_Redox",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_CAES",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_PHS",:Sector] .= "Power"
# tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLR",:Sector] .= "Buildings"
# tag_techno_sector[tag_techno_sector.Technology .== "D_Gas_H2",:Sector] .= "Buildings"
# plot_roa(extr_str, tag_techno_sector,"DE",2050, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], colors, year_split = year_split)
# plot_roa(extr_str, tag_techno_sector,country,2050, "Power", ["Infeasibility_Power"], colors)
# plot_net_trade(extr_str, "DE",["Power"])
# plot_demand(extr_str, tag_techno_sector, "DE", 2050, "Power", ["Infeasibility_Power"], ["Power"], plot_prices=true, considered_dual=["Power"], year_split=year_split)
# plot_demand(extr_str, tag_techno_sector, "FR", 2050, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], ["Power"], year_split=year_split)
# plot_storage_status(extr_str2, "FR", 2050)
# plot_duals(extr_str_list, "FR", considered_dual=["HeatLowResidential"])
# plot_period_comparison_roa(extr_str_list, 1:8760, "DE", 2050, tag_techno_sector, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power", "X_Electrolysis"], colors)
# plot_capacities(extr_str_list, "ES", 2050, tag_techno_sector, "Industry", colors)
# write_demand(extr_str, tag_techno_sector, "DE", "Power", ["Infeasibility_Power"], ["Power"], considered_dual=["Power"])
# plot_year_comparison_demand(extr_str_list, "DE", 2050,tag_techno_sector, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], ["Power"], year_split = year_split)
# compare_roa_in_time(extr_str1, extr_str2, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI"], colors, year_split=year_split)
# plot_price_and_dummy(extr_str, tag_techno_sector, country, 2050, "Buildings", ["Infeasibility_HRI"], colors, considered_dual= ["HeatLowResidential", "H2"])
plot_capacities(extr_str_list, "FR", 2050, tag_techno_sector, "Buildings", colors)

## Plot for residential heating sector ##

# tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLR",:Sector] .= "Buildings"
tag_techno_sector[tag_techno_sector.Technology .== "X_Methanation",:Sector] .= "Industry"
# tag_techno_sector[tag_techno_sector.Technology .== "X_Electrolysis",:Sector] .= "Buildings"
# plot_roa(extr_str, tag_techno_sector,country,2050, "Buildings", ["Infeasibility_HRI", "HLI_Gas_Boiler", "HMI_Gas", "X_Methanation", "X_Electrolysis"], colors)
# plot_roa(extr_str, tag_techno_sector,country,2050, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"], colors)
# plot_net_trade(extr_str, "DE",["Heat_Low_Residential", "Biomass", "Gas_Natural"])
# plot_demand(extr_str, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential"], plot_prices=true, considered_dual=["HeatLowResidential", "Power"], year_split=year_split)
# plot_demand(extr_str, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential", "D_Heat_HLR"])
# plot_RE_heat(extr_str, tag_techno_sector, "DE", ["Infeasibility_Power"], colors)
# plot_period_comparison_roa(extr_str_list, 1:13, "DE", 2050, tag_techno_sector, "Buildings", ["Infeasibility_HRI","D_Heat_HLR"], colors)
# plot_year_comparison_demand(extr_str_list, "DE", 2050, tag_techno_sector, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"], ["Heat_Low_Residential"], year_split = year_split)

## Plot for industrial heating sector ##

tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLI",:Sector] .= "Industry"
# plot_roa(extr_str, tag_techno_sector,country,2050,"Industry", ["Infeasibility_HLI", "Infeasibility_HMI", "Infeasibility_HHI"], colors)
# plot_demand(extr_str, tag_techno_sector, "NO", 2050, "Industry", ["Infeasibility_HLI", "Infeasibility_HMI", "Infeasibility_HHI"], ["Heat_Low_Industrial", "Heat_High_Industrial", "Heat_Medium_Industrial"], plot_prices = true, considered_dual=["HeatLowIndustrial", "HeatHighIndustrial", "HeatMediumIndustrial"])

# peaking_production(extr_str_list, tag_techno_sector, "FR", 2050, "Power", ["Infeasibility_HRI", "D_Heat_HLR"], id= "FR")
# capacities_production_sum(extr_str_list1, "FR", 2050, ["Heat_Low_Residential"], tag_techno_sector, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"])
# plot_peaking_production(list_extr_str_list, name_list, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"])
# plot_production_capacities(list_extr_str_list, name_list, tag_techno_sector, "FR", 2050, "Buildings", ["Heat_Low_Residential"], ["Infeasibility_HRI", "D_Heat_HLR"])
# max_use_capacities(extr_str, tag_techno_sector, country, 2050, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"])