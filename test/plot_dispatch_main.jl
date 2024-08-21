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
# extr_str_list1 = ["dispatch_HP_Bordeaux", "dispatch_HP_Marseille", "dispatch_HP_Montpellier" , "dispatch_HP_Paris", "dispatch_HP_Lille", "dispatch_HP_Lyon",  "dispatch_HP_Nantes", "dispatch_HP_Strasbourg", "dispatch_HP_Nice", "dispatch_HP_Toulouse"]
extr_str_list2 = ["dispatch_HP_Aggregation"]
extr_str_list1 = ["dispatch_HP_Bordeaux", "dispatch_HP_Marseille", "dispatch_HP_Montpellier" , "dispatch_HP_Paris", "dispatch_HP_Lille", "dispatch_HP_Lyon",  "dispatch_HP_Nantes", "dispatch_HP_Strasbourg", "dispatch_HP_Nice", "dispatch_HP_Toulouse"]
list_extr_str_list = [extr_str_list1, extr_str_list2]
name_list = ["cities", "FR"]
# extr_str_list = ["dispatch_representative_HP_Paris"]
# extr_str1 = "dispatch_FR_Aggregation"
# extr_str2 = "dispatch_FR_Nantes"
# extr_str = "run_aggregation_Lyon"
extr_str1 = "full_run"
extr_str2 = "full_run_increased"
# extr_str_list = ["full_run", "full_run_increased"]
# country = "FR"
# extr_str = "dispatch_HP_Bordeaux"
# extr_str = "run_aggregation_Nantes"
# extr_str = "dispatch_ES"
# extr_str_list = ["dispatch_ES"]
# country = "NO"
# , "dispatch_IT", "dispatch_DE_test", "dispatch_NO_test", "dispatch_aggregation_FR"]
# extr_str_list = ["dispatch_two_nodes_DE", "simple_dispatch_DE", "storage_dispatch_DE"]
# name_list = ["scenario $(i) year $(j)" for i in [0,3,5] for j in [2018, 2030, 2040, 2050]]
# extr_str_list = []
# for i in 1:7
#     push!(extr_str_list, "full_run_tax_$(i)")
#     push!(extr_str_list, "tax$(i)_15")
# end
extr_str_list = ["full_run_tax_$(i)" for i in 0:2]
# name_list = ["price 0-2018", "price 0-2050", "price 16-2018", "price 16-2050", "price 56-2018", "price 56-2050", "price 125", "price 250", "price 454", "price 579", "price 740"]
extr_str = "full_run_tax_0"
# extr_str = "dispatch_HP_Aggregation"
country = "FR"
# extr_str = "dispatch_Paris"
# extr_str_list = ["full_run"]

tag_techno_sector[tag_techno_sector.Technology .== "D_Battery_Li-Ion",:Sector] .= "Power"
tag_techno_sector[tag_techno_sector.Technology .== "D_Battery_Redox",:Sector] .= "Power"
# tag_techno_sector[tag_techno_sector.Technology .== "D_CAES",:Sector] .= "Power"
# tag_techno_sector[tag_techno_sector.Technology .== "D_PHS",:Sector] .= "Power"
# tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLR",:Sector] .= "Power"
# tag_techno_sector[tag_techno_sector.Technology .== "D_Gas_H2",:Sector] .= "Buildings"


# in the internal report
# plot_roa(extr_str, tag_techno_sector,"FR",2050, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power", "D_Battery_Li-Ion"], colors, year_split = year_split)
# plot_net_trade(extr_str1, "DE",2050, ["Power"])
# plot_demand(extr_str1, tag_techno_sector, "DE", 2050, "Power", ["Infeasibility_Power"], ["Power"], plot_prices=true, considered_dual=["Power"], year_split=year_split)
# plot_storage_status(extr_str1, "DE", 2050)
# plot_duals(extr_str_list, "FR", 2050, considered_dual=["HeatLowResidential"])
# plot_period_comparison_roa(extr_str_list, 1:13, nothing, 2050, tag_techno_sector, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], colors, name_list=name_list)
# plot_capacities(extr_str_list, "ES", 2050, tag_techno_sector, "Industry", colors)
# plot_year_comparison_demand(extr_str_list, "FR", 2050,tag_techno_sector, "Power", ["Infeasibility_Power"], ["Power"], year_split = year_split, name_list=name_list)
# compare_roa_in_time(extr_str1, extr_str2, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI"], colors, year_split=year_split)
# plot_price_and_dummy(extr_str, tag_techno_sector, country, 2050, "Buildings", ["Infeasibility_HRI"], colors, considered_dual= ["HeatLowResidential"])
# peaking_production(extr_str_list, tag_techno_sector, "FR", 2050, "Power", ["Infeasibility_HRI", "D_Heat_HLR"], id= "FR")
# df = capacities_production_sum(extr_str_list, "FR", 2050, ["Heat_Low_Residential"], tag_techno_sector, "Buildings", ["D_Heat_HLR"])
# print(df)
# plot_peaking_production(list_extr_str_list, name_list, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"])
# plot_production_capacities(list_extr_str_list, name_list, tag_techno_sector, "FR", 2050, "Buildings", ["Heat_Low_Residential"], [])
# max_use_capacities(extr_str, tag_techno_sector, country, 2050, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"])
# plot_emissions(extr_str_list, ["Buildings", "Power", "Industry"],[2018,2050], name_list=name_list)
# plot_accumulated_emissions(extr_str_list, ["Buildings", "Power", "Industry"], name_list=name_list)

#### For power plots 

# plot_roa(extr_str, tag_techno_sector,country,2050, "Power", ["Infeasibility_Power"], colors)
# plot_demand(extr_str, tag_techno_sector, "FR", 2050, "Power", ["Infeasibility_Power", "D_Trade_Storage_Power"], ["Power"], year_split=year_split)
# write_demand(extr_str, tag_techno_sector, "DE", 2050, "Power", ["Infeasibility_Power"], ["Power"], considered_dual=["Power"])


## Plot for residential heating sector ##

# tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLR",:Sector] .= "Buildings"
# tag_techno_sector[tag_techno_sector.Technology .== "X_Methanation",:Sector] .= "Industry"
# tag_techno_sector[tag_techno_sector.Technology .== "X_Electrolysis",:Sector] .= "Buildings"

# plot_capacities(extr_str_list, "FR", 2050, tag_techno_sector, "Buildings", colors)
# plot_roa(extr_str, tag_techno_sector,country,2050, "Buildings", ["Infeasibility_HRI", "HLI_Gas_Boiler", "HMI_Gas", "X_Methanation", "X_Electrolysis"], colors)
# plot_roa(extr_str, tag_techno_sector,country,2050, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"], colors)
# plot_net_trade(extr_str, "DE",["Heat_Low_Residential", "Biomass", "Gas_Natural"])
# plot_demand(extr_str, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential"], plot_prices=true, considered_dual=["HeatLowResidential", "Power"], year_split=year_split)
# plot_demand(extr_str, tag_techno_sector, "FR", 2050, "Buildings", ["Infeasibility_HRI"], ["Heat_Low_Residential", "D_Heat_HLR"])
# plot_period_comparison_roa(extr_str_list, 1:13, nothing, 2050, tag_techno_sector, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"], colors, year_split=year_split, name_list=name_list)
# plot_year_comparison_demand(extr_str_list, "DE", 2050, tag_techno_sector, "Buildings", ["Infeasibility_HRI", "D_Heat_HLR"], ["Heat_Low_Residential"], year_split = year_split)

## Plot for industrial heating sector ##

tag_techno_sector[tag_techno_sector.Technology .== "D_Heat_HLI",:Sector] .= "Industry"
# plot_roa(extr_str, tag_techno_sector,country,2050,"Industry", ["Infeasibility_HLI", "Infeasibility_HMI", "Infeasibility_HHI"], colors)