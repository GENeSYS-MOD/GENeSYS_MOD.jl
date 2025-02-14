# Script to extract TotalCapacityAnnual entries for specified regions and technologies from a text file
import os  # For checking file paths and general OS operations

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
    "H2"]

# Function to extract lines matching regions and technologies
def extract_lines(file_path, regions, technologies):
    extracted_data = []

    try:
        with open(file_path, 'r') as file:
            for line in file:
                if "NetTradeAnnual[2050 " in line:  # Check for TotalCapacityAnnual in the line
                    for region in regions:
                        for technology in technologies:
                            if f"{region}" in line and f"{technology}" in line:
                                extracted_data.append(line.strip())
                                break

        # Print extracted results
        print("Extracted NetTrade lines:")
        for entry in extracted_data:
            print(entry)
        print(f"\nTotal entries found: {len(extracted_data)}")

        # Optionally save to a file
        output_file = "filtered_regions_technologies.txt"
        with open(output_file, 'w') as out_file:
            for entry in extracted_data:
                out_file.write(entry + '\n')
        print(f"\nFiltered data saved to: {output_file}")

    except FileNotFoundError:
        print("Error: File not found. Please check the file path.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Path to the input file
file_path = "Z:/Spesialization_project/dev_jl/Results/Spatial/CPLEX_run_H2trade_on_400.txt"  # Replace with the actual path to your text file

# Run the function
extract_lines(file_path, regions, technologies)
