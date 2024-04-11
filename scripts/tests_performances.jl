import Pkg
cd("C:\\Users\\zoeb\\Documents\\dev\\Inputdata")
Pkg.activate(".")
using JuMP
using CSV
using XLSX
using DataFrames
using Dates

data_frame_test = CSV.read("output_production_test.csv", DataFrame)

# we select only the rows with the desired technology
# but it creates a copy of the dataframe, whereas we would like to change directly the values in the original dataframes
subset_df = data_frame_test[in.(data_frame_test.Technology, Ref(["P_Nuclear","P_Biomass"])),:]
subset_df[!,:Sector] .= "Test"
# subset(data_frame_test, :Technology=> tech -> in.(tech,["P_Nuclear","P_Biomass"]))

container_test = JuMP.Containers.DenseAxisArray(zeros(7,7,5),[2018,2025,2030,2035,2040,2045,2050],["BE","CH","DE","ES","FR","IT","NL"],[8,1929,3850,5771,7692])
dim_names = [Symbol("Year"), Symbol("Region"), Symbol("TimeSlice")]

var_val = value.(container_test)

tup_dim = (dim_names...,)

value_col = Symbol("Value")

ind = reshape([collect(k[i] for i in 1:length(dim_names)) for k in Base.Iterators.product(container_test.axes...)],:,1)

# for i in eachindex(ind)
#     println(ind[i])
# end

colnames = [:Region, :Sector, :TimeSlice, :Type, :Unit, :PathwayScenario, :Year, :Value]

df = DataFrame([merge(NamedTuple{tup_dim}(ind[i]), NamedTuple{(value_col,)}(var_val[(ind[i]...,)...])) for i in 1:length(ind)])
df2 = DataFrame([merge(NamedTuple{tup_dim}(ind[i]), NamedTuple{(value_col,)}(var_val[(ind[i]...,)...])) for i in 1:length(ind)])
first(df,5)
dict_col_value = Dict(:Sector=>"Transportation", :Type=>"Production", :Unit=>"billion km",
                            :PathwayScenario=>"minimal")

function merge_df(df, dict_col_value, final_df, colnames)
    for (col, value) in dict_col_value
        df[!,col] .= value
        final_df[!,col] .= value        
        # print(col)
    end
    if !isempty(df)
        select!(df,colnames)
        append!(final_df, df)
    end
end

date_b = Dates.now()
merge_df(df,dict_col_value, df2, colnames)
date_e = Dates.now()
print("With a function :", date_e - date_b)

df = DataFrame([merge(NamedTuple{tup_dim}(ind[i]), NamedTuple{(value_col,)}(var_val[(ind[i]...,)...])) for i in 1:length(ind)])
df2 = DataFrame([merge(NamedTuple{tup_dim}(ind[i]), NamedTuple{(value_col,)}(var_val[(ind[i]...,)...])) for i in 1:length(ind)])

date_b = Dates.now()
for (col, value) in dict_col_value
    df[!,col] .= value
    df2[!,col] .= value
    # print(col)
end
if !isempty(df)
    select!(df,colnames)
    append!(df2, df)
end
date_e = Dates.now()
print("Without function :", date_e - date_b)

setindex!(dict_col_value, "Power", :Sector)
# dict_col_value[:Sector] .= "Power"
df[!,:Value] .= df[!,:Value].+10
first(df,5)