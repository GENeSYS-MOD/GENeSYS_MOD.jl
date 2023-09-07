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

"""
function _registered_variables(model)
    collect(keys(object_dictionary(model)))
end

"""

"""
function genesysmod_results_raw(model, Switch,extr_str)
    file = open(joinpath(Switch.resultdir,"log_raw_results.txt"), "a")

    vars = _registered_variables(model)
    start = Dates.now()
    Threads.@threads for v in vars
        if v ∉ [:cost, :z]
            @debug "Saving " v
            fn = joinpath(Switch.resultdir, string(v) * "_" * Switch.model_region * "_" * Switch.emissionPathway * "_" * Switch.emissionScenario * "_" * extr_str * ".csv")
            CSV.write(fn, JuMP.Containers.rowtable(value, model[v])) 
            write(file, "$(v): $(Dates.now()-start) \n")
        end
    end
    close(file)

end