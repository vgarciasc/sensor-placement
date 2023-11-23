using JuMP, CPLEX

# Define the model
model = Model(CPLEX.Optimizer)

m, n = 5, 5
M, N = 1:m, 1:n

# Positions that need to be covered
req = [(2, 1), (2, 4), (4, 3), (5, 5)]

# Define the Variables
@variable(model, a[i in M, j in N], Bin)

# Define the Objective Function
@objective(model, Min, sum(a[i, j] for i in M, j in N))

# Define the Constraints
# In this version, we have only one sensor, which has a radius of 1 unit. 
# For each position that is required to be covered (stored in 'req' array),
# we create a constraint: at least one of the sensors that would cover it
# need to be activated.
for (req_x, req_y) in req
    sensor_x = []
    sensor_y = []

    for i in -1:1
        for j in -1:1
            scan_x = req_x + i
            scan_y = req_y + j

            if scan_x >= 1 && scan_x <= m && scan_y >= 1 && scan_y <= n
                push!(sensor_x, scan_x)
                push!(sensor_y, scan_y)
            end
        end
    end

    @constraint(model, sum(a[i, j] for i in sensor_x, j in sensor_y) >= 1)
end

optimize!(model)

println(model)

@show(value.(a))