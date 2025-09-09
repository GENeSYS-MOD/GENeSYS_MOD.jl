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
Main module for `GENeSYS_MOD.jl`.

This module provides the means to run GENeSYS-MOD in julia. It is a translation of the
GAMS version of the model.
"""
module GENeSYS_MOD

using DataFrames
using Dates
using JuMP
using XLSX
using CSV
using Statistics

const DenseArray = JuMP.Containers.DenseAxisArray

include("datastructures.jl")
include("utils.jl")
include("genesysmod.jl")
include("genesysmod_dec.jl")
include("genesysmod_timeseries_reduction.jl")
include("genesysmod_dataload.jl")
include("genesysmod_settings.jl")
include("genesysmod_bounds.jl")
include("genesysmod_equ.jl")
include("genesysmod_employment.jl")
include("genesysmod_variable_parameter.jl")
include("genesysmod_results_raw.jl")
include("genesysmod_results.jl")
include("genesysmod_levelizedcosts.jl")
include("genesysmod_emissionintensity.jl")
include("genesysmod_dispatch.jl")
include.(filter(f-> occursin(r".jl$",f) && occursin("scenariodata",f), readdir(joinpath(pkgdir(GENeSYS_MOD,"src")))))

export genesysmod, genesysmod_dispatch
export genesysmod_build_model, genesysmod_build_model_dispatch
export NoInfeasibilityTechs, WithInfeasibilityTechs # for use with the switch infeasibility_techs
export OneNodeSimple, TwoNodes, OneNodeStorage
export NoRawResult, CSVResult, TXTResult, TXTandCSV

end
