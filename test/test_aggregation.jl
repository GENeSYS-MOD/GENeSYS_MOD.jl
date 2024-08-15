# using Pkg

# Pkg.develop(path="..\\GENeSYS_MOD.jl")
# # Pkg.activate("GENeSYS_MOD")
# Pkg.instantiate()
# import GENeSYS_MOD
using GENeSYS_MOD

using HiGHS
using Ipopt
using Gurobi

# genesysmod(;elmod_daystep = 30, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
# inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
# resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
# data_file="RegularParameters_Europe_openENTRANCE_technoFriendly",
# hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
# switch_raw_results = 1,
# write_reduced_timeserie = 0,
# extr_str_results = "full_run_HP",
# data_base_region = "DE",
# switch_infeasibility_tech = 1
# )

# genesysmod(;elmod_daystep = 1, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
# inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
# resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
# data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_FR",
# hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
# switch_raw_results = 1,
# write_reduced_timeserie = 0,
# extr_str_results = "run_dispatch_FR",
# data_base_region = "FR",
# switch_infeasibility_tech = 1
# )

# genesysmod(;elmod_daystep = 1, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
# inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
# resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
# data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_DE",
# hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
# switch_raw_results = 1,
# write_reduced_timeserie = 0,
# extr_str_results = "run_dispatch_DE",
# data_base_region = "DE",
# switch_infeasibility_tech = 1
# )
for i in 0:7
    genesysmod(;elmod_daystep = 15, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
    inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
    resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
    data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_tax$(i)",
    hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
    switch_raw_results = 1,
    write_reduced_timeserie = 0,
    extr_str_results = "tax$(i)_15",
    data_base_region = "DE",
    switch_infeasibility_tech = 1
    )
end


# for city in ["Paris", "Lyon", "Marseille", "Toulouse", "Bordeaux", "Strasbourg", "Lille", "Nantes", "Montpellier", "Nice"]

    # genesysmod(;elmod_daystep = 1, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
    # inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
    # resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
    # data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_FR",
    # hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly_demand_Aggregation",
    # switch_raw_results = 1,
    # write_reduced_timeserie = 0,
    # extr_str_results = "aggregation_HP_Aggregation",
    # data_base_region = "FR",
    # switch_infeasibility_tech = 1
    # )
    

    # genesysmod_simple_dispatch(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
    # inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
    # resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
    # data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch_FR",
    # hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly_demand_Aggregation",
    # switch_raw_results = 1,
    # year=2050,
    # data_base_region = "FR",
    # extr_str_results = "dispatch_HP_Aggregation",
    # extr_str_dispatch = "aggregation_HP_Aggregation"
    # )

# end
# for country in ["DE"]
#     genesysmod_simple_dispatch_one_node_storage(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
#     inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
#     resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
#     data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch_$(country)",
#     hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
#     switch_raw_results = 1,
#     year=2050,
#     data_base_region = country,
#     extr_str_results = "storage_difference_$(country)",
#     extr_str_dispatch = "full_run_HP"
#     )
# end

#     # genesysmod_simple_dispatch_two_nodes(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
#     # inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
#     # resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
#     # data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch_full_region",
#     # hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
#     # switch_raw_results = 1,
#     # year=2050,
#     # considered_region = country,
#     # data_base_region = country,
#     # extr_str_results = "dispatch_two_nodes_$(country)",
#     # extr_str_dispatch = "full_run"
#     # )
#     end

# genesysmod_simple_dispatch_two_nodes(;elmod_daystep = 0, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
# inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
# resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
# data_file="RegularParameters_Europe_openENTRANCE_technoFriendly_dispatch_full_region",
# hourly_data_file = "Timeseries_Europe_openENTRANCE_technoFriendly",
# switch_raw_results = 1,
# year=2050,
# considered_region = "DE",
# data_base_region = "DE",
# extr_str_results = "dispatch_two_nodes_DE",
# extr_str_dispatch = "full_run"
# )
