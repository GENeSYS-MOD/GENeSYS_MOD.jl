# GENeSYS-MOD v3.1 [Global Energy System Model]  ~ March 2022
#
# #############################################################
#
# Copyright 2020 Technische Universität Berlin and DIW Berlin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# #############################################################
"""
Return all variables in the model
"""
function _registered_variables(model)
    collect(keys(object_dictionary(model)))
end

"""
Write the values of each variable in the model to CSV files.
"""
function genesysmod_results_raw(model, Switch,extr_str)
    vars = _registered_variables(model)
    Threads.@threads for v in vars
        if v ∉ [:cost, :z]
            @debug "Saving " v
            fn = joinpath(Switch.resultdir, string(v) * "_" * Switch.model_region * "_"
             * Switch.emissionPathway * "_" * Switch.emissionScenario * "_" * extr_str * ".csv")
            CSV.write(fn, JuMP.Containers.rowtable(value, model[v])) 
        end
    end
end

"""
Write the values of each element of VarPar to CSV files.
"""
function genesysmod_write_varpar(VarPar, Switch,extr_str)
    Threads.@threads for i in 1:length(fieldnames(typeof(VarPar)))
        v = getfield(VarPar, i)
        fn = joinpath(Switch.resultdir, string(fieldnames(typeof(VarPar))[i]) * "_" * Switch.model_region * "_"
             * Switch.emissionPathway * "_" * Switch.emissionScenario * "_" * extr_str * ".csv")
        CSV.write(fn, JuMP.Containers.rowtable(value, v)) 
    end
end

function genesysmod_getduals(model,Switch,extr_str)
    df=DataFrames.DataFrame(names=[],values=[])
    for (F, S) in list_of_constraint_types(model)
        for con in all_constraints(model, F, S)
            if dual(con) != 0 && name(con) != ""
                push!(df,(name(con),dual(con)))
            end
        end
    end
    fn = joinpath(Switch.resultdir, "Duals" * "_" * Switch.model_region * "_"
             * Switch.emissionPathway * "_" * Switch.emissionScenario * "_" * extr_str * ".csv")
    CSV.write(fn, df)
end

function genesysmod_getspecifiedduals(model,Switch,extr_str, specified_constraints)
    df=DataFrames.DataFrame(names=[],values=[])
    for con in specified_constraints
        if dual(constraint_by_name(model,con)) != 0 && name(constraint_by_name(model,con)) != ""
            push!(df,(name(constraint_by_name(model,con)),dual(constraint_by_name(model,con))))
        end
    end
    date = Dates.now()
    formatted_date = Dates.format(date, "mmdd_HHMM")
    fn = joinpath(Switch.resultdir, "Selected_Duals" * "_" * Switch.model_region * "_"
             * Switch.emissionPathway * "_" * Switch.emissionScenario * "_" * extr_str * ".csv")
    CSV.write(fn, df)
end

function genesysmod_getdualsbyname(model,Switch,extr_str, constr_name)
    df=DataFrames.DataFrame(names=[],values=[])
    constr_list=[]
    for (F, S) in list_of_constraint_types(model)
        for con in all_constraints(model, F, S)
            if occursin(constr_name, name(con))
                push!(constr_list,con)
            end
        end
    end
    for con in constr_list
        if dual(con) != 0
            push!(df,(name(con),dual(con)))
        end
    end
    date = Dates.now()
    formatted_date = Dates.format(date, "mmdd_HHMM")
    fn = joinpath(Switch.resultdir, constr_name * "_" * Switch.model_region * "_"
             * Switch.emissionPathway * "_" * Switch.emissionScenario * "_" * extr_str * ".csv")
    CSV.write(fn, df)

    return df
end