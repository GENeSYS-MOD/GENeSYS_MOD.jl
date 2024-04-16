# Quick Start

## Installation

1.	We suggest using [Visual Studio Code](https://code.visualstudio.com/): https://code.visualstudio.com/
2.	Download the latest stable version of [the Julia Programming Language (julialang.org)](https://julialang.org/downloads/)
3.	Install Julia extension in Visual Studio Code:
    a.	Click 'Extensions' buttion in Visual Studio Code on the left ribbon 
    b.	Search for 'Julia', then install. 
4.	Download an optimization solver and get a license:
    a.	Gurobi
        i.	Academic licensed are issued by Gurobi : https://www.gurobi.com/academia/academic-program-and-licenses/
        ii. Commercial License
    b.	CPLEX https://www.ibm.com/products/ilog-cplex-optimization-studio/cplex-optimizer
    c. HiGHS, open source solver: https://highs.dev/
5.	Clone the GitHub repository for GENeSYS-MOD.jl: https://github.com/GENeSYS-MOD/GENeSYS_MOD.jl
    a.	Download git: [Git - Downloads](https://git-scm.com/)
    b.	Navigate to the folder where you want the repo to be located.
    c. Open Git Bash by right clicking in the chosen folder and choosing "Git Bash Here"
    d. Type the following command in Git Bash:
    ```
    git clone https://github.com/GENeSYS-MOD/GENeSYS_MOD.jl.git
    git pull
    ```
6.	Open GENeSYS-MOD folder in Visual Studios
    a.	File > Open folder
7.	Change to Julia environment for GENeSYS_MOD.jl.
8.  Open the Julia REPL by using the Alt+J+O command. The REPL(read-eval-print loop) is the interactive command line interface in Julia.
10.	Install packages in Visual Studio:
    a.	In the REPL terminal, type ']' to change to enter pkg mode
    b. Type 'add <package>', where package is equal to:
        i.	JuMP
        ii.	Dates
        iii. XLSX
        iv. DataFrames
        v. CSV	
        vi. Ipopt
        vii. <your chosen solver>
10.	Open 'test.jl' and try to run using "Julia: Execute active file in REPL".


## Using the published dataset

A dataset is published on the repository GENeSYS-MOD.data: https://github.com/GENeSYS-MOD/GENeSYS_MOD.data
This repository contains the data including the sources and assumptions necessay to run the model at a european level with a country resolution. Data for over regions may be added with time. 
It also conmtains the tools necessary to produce the input file for the model from this data. The tools are accessed via a jupyter notebook script. More information can be found on the repository.
