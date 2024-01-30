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
Internal function used in the run process to create subsets.
"""
function make_subsets(Sets)
    Solar =["RES_PV_Rooftop_Residential",
    "RES_PV_Rooftop_Commercial",
    "RES_PV_Utility_Opt",
    "RES_PV_Utility_Avg",
    "RES_PV_Utility_Inf",
    "RES_CSP",
    "HLR_Solar_Thermal",
    "HLI_Solar_Thermal",
    "RES_PV_Utility_Tracking"]
    

    Wind = ["RES_Wind_Offshore_Deep",
    "RES_Wind_Offshore_Shallow",
    "RES_Wind_Offshore_Transitional",
    "RES_Wind_Onshore_Opt",
    "RES_Wind_Onshore_Avg",
    "RES_Wind_Onshore_Inf"
    ]
    

    Renewables = ["RES_Wind_Offshore_Deep",
    "RES_Wind_Offshore_Shallow",
    "RES_Wind_Offshore_Transitional",
    "RES_Wind_Onshore_Opt",
    "RES_Wind_Onshore_Avg",
    "RES_Wind_Onshore_Inf",
    "RES_PV_Rooftop_Residential",
    "RES_PV_Rooftop_Commercial",
    "RES_PV_Utility_Opt",
    "RES_PV_Utility_Avg",
    "RES_PV_Utility_Inf",
    "RES_CSP",
    "RES_Geothermal",
    "RES_Hydro_Small",
    "RES_Hydro_Large",
    "RES_Ocean",
    #"RES_BioMass",
    "P_Biomass",
    "P_Biomass_CCS",
    "HLR_Biomass",
    "HLR_Direct_Electric",
    "HLR_Solar_Thermal",
    "HLR_Heatpump_Aerial",
    "HLR_Heatpump_Ground",
    "HLR_Geothermal",
    "HLI_Biomass",
    "HLI_Direct_Electric",
    "HLI_Solar_Thermal",
    "HLI_Fuelcell",
    "HLI_Geothermal",
    "HMI_Biomass",
    "HMI_Steam_Electric",
    "HHI_Scrap_EAF",
    "HHI_H2DRI_EAF",
    "HHI_Molten_Electrolysis",
    "HHI_Bio_BF_BOF",
    "HLR_H2_Boiler",
    "HLI_H2_Boiler",
    "CHP_Biomass_Solid",
    "CHP_Biomass_Solid_CCS",
    "CHP_Gas_CCGT_Biogas",
    "CHP_Gas_CCGT_SynGas",
    "CHP_Gas_CCGT_Biogas_CCS",
    "RES_PV_Utility_Tracking"]
    

    CCS = ["P_Biomass_CCS",
    "HHI_BF_BOF_CCS",
    "HHI_DRI_EAF_CCS",
    "HMI_Gas_CCS",
    "HMI_HardCoal_CCS",
    "P_Coal_Hardcoal_CCS",
    "P_Coal_Lignite_CCS",
    "P_Gas_CCS",
    "X_SMR_CCS",
    "X_DAC_HT",
    "X_DAC_LT",
    "CHP_Biomass_Solid_CCS",
    "CHP_Coal_Hardcoal_CCS",
    "CHP_Coal_Lignite_CCS",
    "CHP_Gas_CCGT_Natural_CCS",
    "CHP_Gas_CCGT_Biogas_CCS"
    ]
    



    Transformation = ["X_Fuel_Cell",
    "X_Electrolysis",
    "X_Methanation",
    "X_Biofuel",
    "X_Powerfuel",
    "D_Battery_Li-Ion",
    "D_Battery_Redox",
    "D_Gas_Methane",
    "D_Gas_H2",
    "D_CAES",
    "D_Heat_HLI",
    "D_Heat_HLR",
    "D_PHS",
    "HLR_Gas_Boiler",
    "HLR_Biomass",
    "HLR_Hardcoal",
    "HLR_Lignite",
    "HLR_Direct_Electric",
    "HLR_Solar_Thermal",
    "HLR_Heatpump_Aerial",
    "HLR_Heatpump_Ground",
    "HLR_Geothermal",
    "HLR_Oil_Boiler",
    "HLR_H2_Boiler",
    "HLI_Gas_Boiler",
    "HLI_Biomass",
    "HLI_Hardcoal",
    "HLI_Lignite",
    "HLI_Direct_Electric",
    "HLI_Solar_Thermal",
    "HLI_Fuelcell",
    "HLI_Geothermal",
    "HLI_Oil_Boiler",
    "HLI_H2_Boiler",
    "HMI_Gas",
    "HMI_Biomass",
    "HMI_HardCoal",
    "HMI_Steam_Electric",
    "HMI_Oil",
    "HHI_BF_BOF",
    "HHI_DRI_EAF",
    "HHI_Scrap_EAF",
    "HHI_H2DRI_EAF",
    "HHI_Molten_Electrolysis",
    "HHI_Bio_BF_BOF",
    "HHI_BF_BOF_CCS",
    "HHI_DRI_EAF_CCS",
    "HMI_Gas_CCS",
    "HMI_HardCoal_CCS",
    "HLR_H2_Boiler",
    "HLI_H2_Boiler",
    "X_SMR",
    "X_SMR_CCS",
    "P_H2_OCGT",
    "CHP_Biomass_Solid",
    "CHP_Coal_Hardcoal",
    "CHP_Coal_Lignite",
    "CHP_Gas_CCGT_Natural",
    "CHP_Gas_CCGT_Biogas",
    "CHP_Gas_CCGT_SynGas",
    "CHP_Biomass_Solid_CCS",
    "CHP_Coal_Hardcoal_CCS",
    "CHP_Coal_Lignite_CCS",
    "CHP_Gas_CCGT_Natural_CCS",
    "CHP_Gas_CCGT_Biogas_CCS",
    "CHP_Hydrogen_FuelCell",
    "CHP_Oil"
    ]
    



    RenewableTransformation = ["X_Fuel_Cell",
    #"X_Electrolysis",
    #"X_Methanation",
    "HLR_Biomass",
    "HLR_Direct_Electric",
    "HLR_Solar_Thermal",
    "HLR_Heatpump_Aerial",
    "HLR_Heatpump_Ground",
    "HLR_Geothermal",
    "HLI_Biomass",
    "HLI_Direct_Electric",
    "HLI_Solar_Thermal",
    "HLI_Fuelcell",
    "HLI_Geothermal",
    "HMI_Biomass",
    "HMI_Steam_Electric",
    "HHI_H2DRI_EAF",
    "HHI_Molten_Electrolysis",
    "HLR_H2_Boiler",
    "HLI_H2_Boiler",
    "P_H2_OCGT",
    "CHP_Biomass_Solid",
    "CHP_Biomass_Solid_CCS",
    "CHP_Gas_CCGT_Biogas",
    "CHP_Gas_CCGT_SynGas",
    "CHP_Gas_CCGT_Biogas_CCS"
    ]



    FossilFuelGeneration = ["R_Coal_Hardcoal",
    "R_Coal_Lignite",
    "R_Oil",
    "R_Nuclear",
    "R_Gas",
    "Z_Import_Gas",
    "Z_Import_Oil",
    "Z_Import_Hardcoal"
    ]



    FossilFuels = ["Hardcoal",
    "Lignite",
    "Nuclear",
    "Oil",
    "Gas_Natural"]


    FossilPower = ["P_Coal_Hardcoal",
    "P_Coal_Lignite",
    "P_Nuclear",
    "P_Oil",
    "P_Coal_Hardcoal_CCS",
    "P_Coal_Lignite_CCS",
    "P_Gas_CCS",
    "P_Gas_CCGT",
    "P_Gas_OCGT",
    "P_Gas_Engines",
    "CHP_Coal_Hardcoal",
    "CHP_Coal_Lignite",
    "CHP_Gas_CCGT_Natural",
    "CHP_Coal_Hardcoal_CCS",
    "CHP_Coal_Lignite_CCS",
    "CHP_Gas_CCGT_Natural_CCS",
    "CHP_Oil"]


    CHPs = ["CHP_Biomass_Solid",
    "CHP_Coal_Hardcoal",
    "CHP_Coal_Lignite",
    "CHP_Gas_CCGT_Natural",
    "CHP_Gas_CCGT_Biogas",
    "CHP_Gas_CCGT_SynGas",
    "CHP_Biomass_Solid_CCS",
    "CHP_Coal_Hardcoal_CCS",
    "CHP_Coal_Lignite_CCS",
    "CHP_Gas_CCGT_Natural_CCS",
    "CHP_Gas_CCGT_Biogas_CCS",
    "CHP_Hydrogen_FuelCell",
    "CHP_Oil",
    "HLI_Convert_DH",
    "HLR_Convert_DH"]


    RenewableTransport = ["FRT_Rail_Electric",
    "FRT_Road_BEV",
    "FRT_Road_H2",
    "FRT_Road_PHEV",
    "FRT_Road_OH",
    "FRT_Ship_Bio",
    "PSNG_Air_Bio",
    "PSNG_Air_H2",
    "PSNG_Rail_Electric",
    "PSNG_Road_BEV",
    "PSNG_Road_H2",
    "PSNG_Road_PHEV"]


    Transport = ["FRT_Rail_Conv",
    "FRT_Rail_Electric",
    "FRT_Road_BEV",
    "FRT_Road_H2",
    "FRT_Road_ICE",
    "FRT_Road_PHEV",
    "FRT_Road_OH",
    "FRT_Ship_Bio",
    "FRT_Ship_Conv",
    "PSNG_Air_Bio",
    "PSNG_Air_Conv",
    "PSNG_Air_H2",
    "PSNG_Rail_Conv",
    "PSNG_Rail_Electric",
    "PSNG_Road_BEV",
    "PSNG_Road_H2",
    "PSNG_Road_ICE",
    "PSNG_Road_PHEV"]


    Passenger = ["PSNG_Air_Bio",
    "PSNG_Air_Conv",
    "PSNG_Air_H2",
    "PSNG_Rail_Conv",
    "PSNG_Rail_Electric",
    "PSNG_Road_BEV",
    "PSNG_Road_H2",
    "PSNG_Road_ICE",
    "PSNG_Road_PHEV"]


    Freight = ["FRT_Rail_Conv",
    "FRT_Rail_Electric",
    "FRT_Road_BEV",
    "FRT_Road_H2",
    "FRT_Road_ICE",
    "FRT_Road_PHEV",
    "FRT_Road_OH",
    "FRT_Ship_Bio",
    "FRT_Ship_Conv"]


    TransportFuels = ["Mobility_Passenger",
    "Mobility_Freight"]


    ImportTechnology = ["Z_Import_Hardcoal",
    "Z_Import_Oil",
    "Z_Import_Gas",
    "Z_Import_LNG",
    "Z_Import_H2"]


    Heat = ["HLR_Gas_Boiler",
    "HLR_Biomass",
    "HLR_Hardcoal",
    "HLR_Lignite",
    "HLR_Direct_Electric",
    "HLR_Solar_Thermal",
    "HLR_Heatpump_Aerial",
    "HLR_Heatpump_Ground",
    "HLR_Geothermal",
    "HLR_Oil_Boiler",
    "HLI_Gas_Boiler",
    "HLI_Biomass",
    "HLI_Hardcoal",
    "HLI_Lignite",
    "HLI_Direct_Electric",
    "HLI_Solar_Thermal",
    "HLI_Fuelcell",
    "HLI_Geothermal",
    "HLI_Oil_Boiler",
    "HMI_Gas",
    "HMI_Biomass",
    "HMI_HardCoal",
    "HMI_Steam_Electric",
    "HMI_Oil",
    "HHI_BF_BOF",
    "HHI_DRI_EAF",
    "HHI_Scrap_EAF",
    "HHI_H2DRI_EAF",
    "HHI_Molten_Electrolysis",
    "HHI_Bio_BF_BOF",
    "HHI_BF_BOF_CCS",
    "HHI_DRI_EAF_CCS",
    "HMI_Gas_CCS",
    "HMI_HardCoal_CCS",
    "HLR_H2_Boiler",
    "HLI_H2_Boiler",
    "CHP_Biomass_Solid",
    "CHP_Coal_Hardcoal",
    "CHP_Coal_Lignite",
    "CHP_Gas_CCGT_Natural",
    "CHP_Gas_CCGT_Biogas",
    "CHP_Gas_CCGT_SynGas",
    "CHP_Biomass_Solid_CCS",
    "CHP_Coal_Hardcoal_CCS",
    "CHP_Coal_Lignite_CCS",
    "CHP_Gas_CCGT_Natural_CCS",
    "CHP_Gas_CCGT_Biogas_CCS",
    "CHP_Hydrogen_FuelCell",
    "CHP_Oil",
    "HLI_Convert_DH",
    "HLR_Convert_DH"]


    PowerSupply = ["RES_Wind_Offshore_Deep",
    "RES_Wind_Offshore_Shallow",
    "RES_Wind_Offshore_Transitional",
    "RES_Wind_Onshore_Opt",
    "RES_Wind_Onshore_Avg",
    "RES_Wind_Onshore_Inf",
    "RES_PV_Rooftop_Residential",
    "RES_PV_Rooftop_Commercial",
    "RES_PV_Utility_Opt",
    "RES_PV_Utility_Avg",
    "RES_PV_Utility_Inf",
    "RES_PV_Utility_Tracking",
    "RES_CSP",
    "RES_Geothermal",
    "RES_Hydro_Small",
    "RES_Hydro_Large",
    "RES_Ocean",
    "P_Coal_Hardcoal",
    "P_Coal_Lignite",
    "P_Nuclear",
    "P_Oil",
    "P_Biomass",
    "P_Biomass_CCS",
    "P_Coal_Lignite_CCS",
    "P_Coal_Hardcoal_CCS",
    "P_Gas_CCS",
    "P_H2_OCGT",
    "P_Gas_CCGT",
    "P_Gas_OCGT",
    "P_Gas_Engines"]


    PowerBiomass = ["P_Biomass",
    "P_Biomass_CCS",
    "CHP_Biomass_Solid",
    "CHP_Biomass_Solid_CCS"]


    Coal = ["P_Coal_Hardcoal",
    "P_Coal_Lignite",
    "HLR_Hardcoal",
    "HLR_Lignite",
    "HLI_Hardcoal",
    "HLI_Lignite",
    "HMI_HardCoal",
    "HHI_BF_BOF",
    "HHI_BF_BOF_CCS",
    "HMI_HardCoal_CCS",
    "P_Coal_Hardcoal_CCS",
    "P_Coal_Lignite_CCS",
    "CHP_Coal_Hardcoal",
    "CHP_Coal_Lignite",
    "CHP_Coal_Hardcoal_CCS",
    "CHP_Coal_Lignite_CCS"]


    Lignite = ["P_Coal_Lignite",
    "HLR_Lignite",
    "HLI_Lignite",
    "P_Coal_Lignite_CCS",
    "CHP_Coal_Lignite",
    "CHP_Coal_Lignite_CCS"]


    Gas = ["HLR_Gas_Boiler",
    "HLI_Gas_Boiler",
    "HMI_Gas",
    "HHI_DRI_EAF",
    "HHI_DRI_EAF_CCS",
    "HMI_Gas_CCS",
    "P_Gas_CCS",
    "P_Gas_CCGT",
    "P_Gas_OCGT",
    "P_Gas_Engines",
    "CHP_Gas_CCGT_Natural",
    "CHP_Gas_CCGT_Biogas",
    "CHP_Gas_CCGT_SynGas",
    "CHP_Gas_CCGT_Natural_CCS",
    "CHP_Gas_CCGT_Biogas_CCS"]


    StorageDummies = ["D_Battery_Li-Ion",
    "D_Battery_Redox",
    "D_Gas_Methane",
    "D_Gas_H2",
    "D_Heat_HLI",
    "D_Heat_HLR",
    "D_PHS",
    "D_PHS_Residual",
    "D_CAES"]


    SectorCoupling = ["X_Fuel_Cell",
    "X_Electrolysis",
    "X_Methanation",
    "HLI_Fuelcell",
    "X_SMR",
    "X_SMR_CCS",
    "X_Biofuel",
    "X_Powerfuel",
    "P_H2_OCGT"]


    HeatFuels = ["Heat_Low_Industrial",
    "Heat_Medium_Industrial",
    "Heat_High_Industrial",
    "Heat_Low_Residential"]


    ModalGroups = ["MT_PSNG_ROAD",
    "MT_PSNG_RAIL",
    "MT_PSNG_AIR",
    "MT_FRT_ROAD",
    "MT_FRT_RAIL",
    "MT_FRT_SHIP"]


    PhaseInSet = [#"X_Fuel_Cell",
    "X_Electrolysis",
    "X_Biofuel",
    #"X_Methanation",
    "D_Battery_Li-Ion",
    "D_Battery_Redox",
    "D_Gas_Methane",
    "D_Gas_H2",
    "D_CAES",
    "D_Heat_HLR",
    "D_Heat_HLI",
    "D_PHS",
    "HLR_Biomass",
    "HLR_Direct_Electric",
    "HLR_Solar_Thermal",
    "HLR_Heatpump_Aerial",
    "HLR_Heatpump_Ground",
    "HLR_Geothermal",
    "HLI_Biomass",
    "HLI_Direct_Electric",
    "HLI_Solar_Thermal",
    "HLI_Fuelcell",
    "HLI_Geothermal",
    "HMI_Biomass",
    "HMI_Steam_Electric",
    "HHI_H2DRI_EAF",
    "HHI_Scrap_EAF",
    "HHI_Molten_Electrolysis",
    "HHI_Bio_BF_BOF",
    "RES_Wind_Offshore_Deep",
    "RES_Wind_Offshore_Shallow",
    "RES_Wind_Offshore_Transitional",
    "RES_Wind_Onshore_Opt",
    "RES_Wind_Onshore_Avg",
    "RES_Wind_Onshore_Inf",
    "RES_PV_Rooftop_Residential",
    "RES_PV_Rooftop_Commercial",
    "RES_PV_Utility_Opt",
    "RES_PV_Utility_Avg",
    "RES_PV_Utility_Inf",
    "RES_PV_Utility_Tracking",
    "RES_CSP",
    "RES_Geothermal",
    "RES_Hydro_Small",
    "RES_Hydro_Large",
    "RES_Ocean",
    #"RES_BioMass",
    "P_Biomass",
    "HLR_H2_Boiler",
    "HLI_H2_Boiler",
    "FRT_Road_BEV",
    "FRT_Road_H2",
    "FRT_Road_PHEV",
    "FRT_Road_OH",
    "FRT_Ship_Bio",
    "PSNG_Air_Bio",
    "PSNG_Air_H2",
    "PSNG_Road_BEV",
    "PSNG_Road_H2",
    "PSNG_Road_PHEV",
    "P_H2_OCGT",
    "CHP_Biomass_Solid",
    "CHP_Gas_CCGT_Biogas",
    "CHP_Gas_CCGT_SynGas",
    "CHP_Hydrogen_FuelCell"]
    append!(PhaseInSet,CCS)

    PhaseOutSet = ["P_Coal_Hardcoal",
    "P_Coal_Lignite",
    #"P_Nuclear",
    "P_Oil",
    "HLR_Gas_Boiler",
    "HLR_Hardcoal",
    "HLR_Lignite",
    "HLR_Oil_Boiler",
    "HLI_Gas_Boiler",
    "HLI_Hardcoal",
    "HLI_Lignite",
    "HLI_Oil_Boiler",
    "HMI_Gas",
    "HMI_HardCoal",
    "HMI_Oil",
    "HHI_BF_BOF",
    "CHP_Coal_Hardcoal",
    "CHP_Coal_Lignite",
    "CHP_Oil"]
    


    HeatSlowRamper = ["HLR_Oil_Boiler",
    "HHI_BF_BOF",
    "HHI_DRI_EAF",
    "HHI_Scrap_EAF",
    "HHI_H2DRI_EAF",
    "HHI_Molten_Electrolysis",
    "HHI_Bio_BF_BOF",
    "HHI_BF_BOF_CCS",
    "HHI_DRI_EAF_CCS"]



    HeatQuickRamper = ["HLR_Hardcoal",
    "HLR_Lignite",
    "HLR_Biomass",
    "HLR_Gas_Boiler",
    "HLR_Direct_Electric",
    "HLR_H2_Boiler",
    "HLI_Hardcoal",
    "HLI_Lignite",
    "HLI_Biomass",
    "HLI_Gas_Boiler",
    "HLI_Direct_Electric",
    "HLI_H2_Boiler",
    "HMI_Gas",
    "HMI_Steam_Electric",
    "HMI_Gas_CCS",
    "HMI_Biomass",
    "HMI_HardCoal",
    "HMI_Oil",
    "HMI_HardCoal_CCS"]


    Hydro = ["RES_Hydro_Large",
    "RES_Hydro_Small"]


    Geothermal = ["RES_Geothermal",
    "HLR_Geothermal",
    "HLI_Geothermal"]


    Onshore = ["RES_Wind_Onshore_Opt",
    "RES_Wind_Onshore_Avg",
    "RES_Wind_Onshore_Inf"]


    Offshore = ["RES_Wind_Offshore_Deep",
    "RES_Wind_Offshore_Shallow",
    "RES_Wind_Offshore_Transitional"]


    SolarUtility = ["RES_PV_Utility_Opt",
    "RES_PV_Utility_Avg",
    "RES_PV_Utility_Inf"]


    Oil = ["P_Oil",
    "HMI_Oil",
    "HLI_Oil_Boiler",
    "HLR_Oil_Boiler",
    "CHP_Oil"]


    HeatLowRes = ["HLR_Gas_Boiler",
    "HLR_Biomass",
    "HLR_Hardcoal",
    "HLR_Lignite",
    "HLR_Direct_Electric",
    "HLR_Solar_Thermal",
    "HLR_Heatpump_Aerial",
    "HLR_Heatpump_Ground",
    "HLR_Geothermal",
    "HLR_Oil_Boiler",
    "HLR_Convert_DH"]


    HeatLowInd = ["HLI_Gas_Boiler",
    "HLI_Biomass",
    "HLI_Hardcoal",
    "HLI_Lignite",
    "HLI_Direct_Electric",
    "HLI_Solar_Thermal",
    "HLI_Fuelcell",
    "HLI_Geothermal",
    "HLI_Oil_Boiler",
    "HLI_Convert_DH"]


    HeatMedInd = ["HMI_Gas",
    "HMI_Biomass",
    "HMI_HardCoal",
    "HMI_Steam_Electric",
    "HMI_Oil"]


    HeatHighInd = ["HHI_BF_BOF",
    "HHI_DRI_EAF",
    "HHI_Scrap_EAF",
    "HHI_H2DRI_EAF",
    "HHI_Molten_Electrolysis",
    "HHI_Bio_BF_BOF"]


    Biomass = ["RES_Grass",
    "RES_Wood",
    "RES_Residues",
    "RES_Paper_Cardboard",
    "RES_Roundwood",
    "RES_Biogas"]


    Households = ["RES_PV_Rooftop_Residential",
    "HLR_Gas_Boiler",
    "HLR_Biomass",
    "HLR_Hardcoal",
    "HLR_Direct_Electric",
    "HLR_Solar_Thermal",
    "HLR_Heatpump_Aerial",
    "HLR_Heatpump_Ground",
    "HLR_Oil_Boiler"]


    Companies = setdiff(Sets.Technology,["RES_PV_Rooftop_Residential",
    "HLR_Gas_Boiler",
    "HLR_Biomass",
    "HLR_Hardcoal",
    "HLR_Direct_Electric",
    "HLR_Solar_Thermal",
    "HLR_Heatpump_Aerial",
    "HLR_Heatpump_Ground",
    "HLR_Oil_Boiler"])
    


    HydrogenTechnologies = ["HLI_H2_Boiler",
    "HMI_H2",
    "P_H2_OCGT"]

    DummyTechnology = [
    "Infeasibility_HLI",
    "Infeasibility_HMI",
    "Infeasibility_HHI",
    "Infeasibility_HRI",
    "Infeasibility_Power",
    "Infeasibility_Mob_Passenger",
    "Infeasibility_Mob_Freight"
    ]
    
    Subsets=SubsetsIni(Solar,Wind,Renewables, CCS, Transformation,RenewableTransformation,
    FossilFuelGeneration,FossilFuels,FossilPower,CHPs,RenewableTransport,Transport,Passenger,
    Freight,TransportFuels,ImportTechnology,Heat,PowerSupply,PowerBiomass,Coal,Lignite,Gas,
    StorageDummies,SectorCoupling,HeatFuels,ModalGroups,PhaseInSet,PhaseOutSet,HeatSlowRamper,
    HeatQuickRamper,Hydro,Geothermal,Onshore,Offshore,SolarUtility,Oil,HeatLowRes,HeatLowInd,
    HeatMedInd,HeatHighInd,Biomass,Households,Companies,HydrogenTechnologies,DummyTechnology)

    return Subsets
end

"""
make_mapping(Sets,Params)

Creates a mapping of the allowed combinations of technology and fuel (and revers) and mode of operations.
"""
function make_mapping(Sets,Params)
    Map_Tech_Fuel = Dict(t=>[f for f ∈ Sets.Fuel if (any(Params.OutputActivityRatio[:,t,f,:,:].>0)
    || any(Params.InputActivityRatio[:,t,f,:,:].>0))] for t ∈ Sets.Technology)

   Map_Tech_MO = Dict(t=>[m for m ∈ Sets.Mode_of_operation if (any(Params.OutputActivityRatio[:,t,:,m,:].>0)
    || any(Params.InputActivityRatio[:,t,:,m,:].>0))] for t ∈ Sets.Technology)

   Map_Fuel_Tech = Dict(f=>[t for t ∈ Sets.Technology if (any(Params.OutputActivityRatio[:,t,f,:,:].>0)
    || any(Params.InputActivityRatio[:,t,f,:,:].>0))] for f ∈ Sets.Fuel)

    return Maps(Map_Tech_Fuel,Map_Tech_MO,Map_Fuel_Tech)
end