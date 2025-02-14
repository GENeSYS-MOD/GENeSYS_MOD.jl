import Pkg
using JuMP
using HiGHS

Pkg.add("HiGHS")
# Create a model with the HiGHS optimizer
model = Model(HiGHS.Optimizer)

# Define variables
@variable(model, x >= 0)
@variable(model, y >= 0)

# Define the objective function
@objective(model, Max, 3x + 4y)

# Define the constraints
@constraint(model, con1, 2x + y <= 20)
@constraint(model, con2, 4x - 5y >= -10)
@constraint(model, con3, x + 2y <= 15)

# Optimize the model
optimize!(model)

# Print the results
println("Optimal solution: x = ", value(x), ", y = ", value(y))
println("Objective value: ", objective_value(model))

# Extract and print the shadow price of the first constraint
shadow_price_con1 = shadow_price(con1)
println("Shadow price of constraint 1: ", shadow_price_con1)