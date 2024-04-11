import Pkg
cd("C:\\Users\\zoeb\\Documents\\dev")
Pkg.activate(".")
Pkg.develop(path="..\\GENeSYS_MOD.jl")
using GENeSYS_MOD
using GLPK
#using CPLEX
using Gurobi
using Ipopt

model,dicts=genesysmod(;elmod_daystep = 16, elmod_hourstep = 1, solver=Gurobi.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath(pkgdir(GENeSYS_MOD),"..","dev","Inputdata"),
resultdir = joinpath(pkgdir(GENeSYS_MOD),"..","dev","Results"),
data_file="output_long_few_zones",
hourly_data_file="output_timeseries",
switch_base_year_bounds = 0
)