using JuMP, CPLEX

# Define the model
model = Model(CPLEX.Optimizer)

m, n = 5, 5
M, N = 1:m, 1:n

sensors = [
    ("wide camera", 3, 42),
    ("narrow camera", 6, 112),
    ("volumetric sensor", 1, 42),
    ("seismic detector", 1, 169),
    ("smoke detector", 1, 6)
]
s = size(sensors, 1)
S = 1:s
c = [i for (_, _, i) in sensors]

# Positions that need to be covered
req = [(2, 1), (2, 4), (4, 3), (5, 5)]

# Define the Variables
@variable(model, a[i in M, j in N, k in S], Bin)

# Define the Objective Function
@objective(model, Min, sum(c[k] * a[i, j, k] for i in M, j in N, k in S))

# Define the Constraints
# In this version, we have all five sensors, each with radius stored in 'sensors' array
# For each position that is required to be covered (stored in 'req' array),
# we create a constraint: at least one of the sensors that would cover it
# need to be activated.
for (req_x, req_y) in req
    constraint_vars = []

    for (k, (s_name, s_radius, s_cost)) in enumerate(sensors)
        for i in -s_radius:s_radius
            for j in -s_radius:s_radius
                scan_x = req_x + i
                scan_y = req_y + j

                if scan_x >= 1 && scan_x <= m && scan_y >= 1 && scan_y <= n
                    push!(constraint_vars, (scan_x, scan_y, k))
                end
            end
        end
    end

    @constraint(model, sum(a[i, j, k] for (i, j, k) in constraint_vars) >= 1)
end

optimize!(model)

println(model)

@show(value.(a))