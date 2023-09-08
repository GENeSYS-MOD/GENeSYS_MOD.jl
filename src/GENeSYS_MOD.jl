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

module GENeSYS_MOD

using DataFrames
using Dates
using JuMP
using XLSX
using CSV
using TimerOutputs

const to = TimerOutput()

include("datastructures.jl")
include("utils.jl")
include("genesysmod_subsets.jl")
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
include("genesysmod_simple_dispatch.jl")
include(joinpath("equations", "objective.jl"))
include(joinpath("equations", "equa_cap_adequacy.jl"))
include(joinpath("equations", "equa_energy_balance.jl"))
include(joinpath("equations", "equa_trade.jl"))
include(joinpath("equations", "equa_acc.jl"))
include(joinpath("equations", "equa_capital_cost.jl"))
include(joinpath("equations", "equa_salvage.jl"))
include(joinpath("equations", "equa_op_cost.jl"))
include(joinpath("equations", "equa_disc_cost.jl"))
include(joinpath("equations", "equa_capacity.jl"))
include(joinpath("equations", "equa_activity.jl"))
include(joinpath("equations", "equa_re_target.jl"))
include(joinpath("equations", "other.jl"))

export genesysmod, genesysmod_simple_dispatch

end