# Quick Start

## Installation

1.	We suggest using [Visual Studio Code](https://code.visualstudio.com/).

2.	Download the latest stable version of [the Julia Programming Language (julialang.org)](https://julialang.org/downloads/).

3.	Install Julia extension in Visual Studio Code:
    *	Click 'Extensions' buttion in Visual Studio Code on the left ribbon.
    *	Search for 'Julia', then install. 

4.	Download an optimization solver and get a license:
    *	Gurobi
        - Academic licensed are issued by [Gurobi](https://www.gurobi.com/academia/academic-program-and-licenses/).
        - Commercial License.
    *	[CPLEX](https://www.ibm.com/products/ilog-cplex-optimization-studio/cplex-optimizer)
    *	[HiGHS](https://highs.dev/), open source solver.

5.	Clone the GitHub repository for [GENeSYS_MOD.jl](https://github.com/GENeSYS-MOD/GENeSYS_MOD.jl)
    *	Download git: [Git - Downloads](https://git-scm.com/)
    *	Navigate to the folder where you want the repo to be located.
    * Open Git Bash by right clicking in the chosen folder and choosing "Git Bash Here"
    * Type the following command in Git Bash:

```
git clone https://github.com/GENeSYS-MOD/GENeSYS_MOD.jl.git
git pull
```

6.	Open GENeSYS-MOD folder in Visual Studios
    *	File > Open folder

7.	Change to Julia environment for GENeSYS_MOD.jl.

8.  Open the Julia REPL by using the Alt+J+O command. The REPL(read-eval-print loop) is the interactive command line interface in Julia.

9.	Install packages in Visual Studio:
    *	In the REPL terminal, type ']' to change to enter pkg mode
    * Type 'add <package>', where package is equal to:
        - JuMP
        - Dates
        - XLSX
        - DataFrames
        - CSV	
        - Ipopt
        - <your chosen solver>

10.	Open 'test.jl' and try to run using "Julia: Execute active file in REPL".

## Running a case

Create a folder where you will be able to store your scripts, inputs and outputs of the model. You can then include tyhe following at the top of your script: 

```julia
Pkg.develop(path="..\\GENeSYS_MOD.jl")
using GENeSYS_MOD
```

Where you replace the path with the relative or absolute path to the package. Note the "\\".This will allow you to use the package functions.

You can then run the model by running the function `genesysmod` with the appropriate `Switch`.


## Using the published dataset

A dataset is published on the repository GENeSYS-MOD.data: (https://github.com/GENeSYS-MOD/GENeSYS_MOD.data)
This repository contains the data including the sources and assumptions necessay to run the model at a european level with a country resolution. Data for over regions may be added with time. 
It also conmtains the tools necessary to produce the input file for the model from this data. The tools are accessed via a jupyter notebook script. More information can be found on the repository.
