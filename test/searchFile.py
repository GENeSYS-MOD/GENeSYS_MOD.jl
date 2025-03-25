import re

def search_export_values(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    results = []
    for value in range(300, 8701, 300):
        pattern = re.escape(f"Export[2018,{value},Power,SE3,DE]")
        if re.search(pattern, content):
            results.append(value)
    
    return results



search_export_values("Z:/Spesialization_project/dev_jl/Input/New_CPLEX_Results/TradeInvestments_nth300_fixed_H2Trade.txt")