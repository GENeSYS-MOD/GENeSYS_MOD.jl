# Script to extract TotalCapacityAnnual entries for specified regions and technologies from a text file
import os  # For file handling
import re  # For extracting numeric values using regular expressions
from collections import defaultdict  # For summing capacities by region

# List of regions to filter
regions = [
    "AT", "BE", "CH", "CZ", "DE", "EE", "FI", "FR", "ES", "IE", "LT", "LU", "LV", "NL", "PL", "UK", 
    "NO1", "NO2", "NO3", "NO4", "NO5", "World", "DK1", "DK2", "SE1", "SE2", "SE3", "SE4", "OFFBE", 
    "OFFGBMid", "OFFGBScot", "OFFGBSor", "OFFDK1", "OFFDK2", "OFFDE", "OFFNL1", "OFFNL2", 
    "NONordvestC", "NONordvestA", "NOVestA", "NOVestB", "NOVestE", "NOVestF", "NOSorB", 
    "NOSorC", "NOSorF", "NOSoennaA"
]

# List of technologies to filter
technologies = [
    "A_Air", "A_Rooftop_Commercial", "A_Rooftop_Residential", "CHP_Biomass_Solid", "CHP_Biomass_Solid_CCS",
    "CHP_Coal_Hardcoal", "CHP_Coal_Hardcoal_CCS", "CHP_Coal_Lignite", "CHP_Coal_Lignite_CCS", "CHP_Gas_CCGT_Biogas",
    "CHP_Gas_CCGT_Biogas_CCS", "CHP_Gas_CCGT_Natural", "CHP_Gas_CCGT_Natural_CCS", "CHP_Gas_CCGT_SynGas",
    "CHP_Hydrogen_FuelCell", "CHP_Oil", "D_Battery_Li-Ion", "D_Battery_Redox", "D_CAES", "D_Gas_H2",
    "D_Gas_Methane", "D_Heat_HLI", "D_Heat_HLR", "D_PHS_Residual", "FRT_Rail_Conv", "FRT_Rail_Electric",
    "FRT_Road_BEV", "FRT_Road_H2", "FRT_Road_ICE", "FRT_Road_LNG", "FRT_Road_OH", "FRT_Road_PHEV",
    "FRT_Ship_Bio", "FRT_Ship_Conv", "FRT_Ship_LNG", "HLI_Convert_DH", "HLR_Convert_DH", "HHI_BF_BOF",
    "HHI_BF_BOF_CCS", "HHI_Bio_BF_BOF", "HHI_DRI_EAF", "HHI_DRI_EAF_CCS", "HHI_H2DRI_EAF",
    "HHI_Molten_Electrolysis", "HHI_Scrap_EAF", "HLI_Biomass", "HLI_Direct_Electric", "HLI_Fuelcell",
    "HLI_Gas_Boiler", "HLI_Geothermal", "HLI_H2_Boiler", "HLI_Hardcoal", "HLI_Lignite", "HLI_Oil_Boiler",
    "HLI_Solar_Thermal", "HLR_Biomass", "HLR_Direct_Electric", "HLR_Gas_Boiler", "HLR_Geothermal",
    "HLR_H2_Boiler", "HLR_Hardcoal", "HLR_Heatpump_Aerial", "HLR_Heatpump_Ground", "HLR_Lignite",
    "HLR_Oil_Boiler", "HLR_Solar_Thermal", "HMI_Biomass", "HMI_H2", "HMI_Gas", "HMI_Gas_CCS",
    "HMI_HardCoal", "HMI_HardCoal_CCS", "HMI_Oil", "HMI_Steam_Electric", "P_Biomass", "P_Biomass_CCS",
    "P_Coal_Hardcoal", "P_Coal_Hardcoal_CCS", "P_Coal_Lignite", "P_Coal_Lignite_CCS", "P_Gas_CCGT",
    "P_Gas_Engines", "P_Gas_OCGT", "P_Gas_CCS", "P_H2_OCGT", "P_Nuclear", "P_Oil", "PSNG_Air_Bio",
    "PSNG_Air_Conv", "PSNG_Air_H2", "PSNG_Rail_Conv", "PSNG_Rail_Electric", "PSNG_Road_BEV",
    "PSNG_Road_H2", "PSNG_Road_ICE", "PSNG_Road_LNG", "PSNG_Road_PHEV", "R_Coal_Hardcoal",
    "R_Coal_Lignite", "R_Gas", "R_Nuclear", "R_Oil", "RES_Biogas", "RES_CSP", "RES_Geothermal",
    "RES_Grass", "RES_Hydro_Large", "RES_Hydro_Small", "RES_Ocean", "RES_Paper_Cardboard",
    "RES_PV_Rooftop_Residential", "RES_PV_Utility_Avg", "RES_PV_Utility_Inf", "RES_PV_Utility_Opt",
    "RES_PV_Utility_Tracking", "RES_Residues", "RES_Roundwood", "RES_Wind_Offshore_Deep",
    "RES_Wind_Offshore_Shallow", "RES_Wind_Offshore_Transitional", "RES_Wind_Onshore_Avg",
    "RES_Wind_Onshore_Inf", "RES_Wind_Onshore_Opt", "RES_Wood", "X_Biofuel", "X_DAC_HT", "X_DAC_LT",
    "X_Electrolysis", "X_Fuel_Cell", "X_Gasifier", "X_Liquifier", "X_Methanation", "X_Powerfuel",
    "X_SMR", "X_ATR_CCS", "Z_ETS_Buy", "Z_ETS_Sell", "Z_Import_Gas", "Z_Import_Hardcoal", "Z_Import_LNG",
    "Z_Import_Oil", "RES_PV_Rooftop_Commercial", "D_PHS", "Z_Import_H2"
]


# Function to extract and sum capacities per region
def extract_and_sum_capacities(file_path, regions, technologies):
    region_capacity = defaultdict(float)  # Dictionary to store summed capacities for each region

    try:
        with open(file_path, 'r') as file:
            for line in file:
                if "TotalCapacityAnnual[2050" in line:  # Check for relevant lines
                    for region in regions:
                        for technology in technologies:
                            if f"{region}" in line and f"{technology}" in line:
                                # Extract capacity value using regular expressions
                                capacity_match = re.search(r"[\d\.\-eE]+", line.split(']')[-1])
                                if capacity_match:
                                    capacity_value = float(capacity_match.group())  # Convert to float
                                    region_capacity[region] += capacity_value  # Add to the region's total
                                break

        # Print summed capacities
        print("Summed TotalCapacityAnnual for each region:")
        for region, total_capacity in region_capacity.items():
            print(f"{region}: {total_capacity:.2f}")
        
        # Save to file
        output_file = "summed_capacities_by_region.txt"
        with open(output_file, 'w') as out_file:
            for region, total_capacity in region_capacity.items():
                out_file.write(f"{region}: {total_capacity:.2f}\n")
        print(f"\nSummed capacities saved to: {output_file}")

    except FileNotFoundError:
        print("Error: File not found. Please check the file path.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Path to the input file
file_path = "input_file.txt"  # Replace with the actual path to your text file


# Run the function
extract_and_sum_capacities("Z:/Spesialization_project/dev_jl/Results/Spatial/ScenarioRun_granularity1000_tradecost0.001/TradeInvestments_offshore_noTrade_granularity1000.txt","CZ", technologies)
