using GENeSYS_MOD
using HiGHS
using Ipopt

model, data = genesysmod(;elmod_daystep = 80, elmod_hourstep = 1, solver=HiGHS.Optimizer, DNLPsolver = Ipopt.Optimizer, threads=0, 
inputdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Inputs"),
resultdir = joinpath(pkgdir(GENeSYS_MOD),"test","TestData","Results"),
data_file="RegularParameters_testdata",
hourly_data_file = "Timeseries_testdata",
);