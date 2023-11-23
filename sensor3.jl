using JuMP, CPLEX
using Colors, Plots

# Define the model
model = Model(CPLEX.Optimizer)

m, n = 5, 5
M, N = 1:m, 1:n

sensors = [
    ("wide camera", 3, 42),
    ("narrow camera", 6, 112),
    ("volumetric sensor", 1, 42),
    ("seismic detector", 1, 169),
    ("smoke detector", 1, 60)
]
s = size(sensors, 1)
S = 1:s
c = [i for (_, _, i) in sensors]

# Positions that need to be covered
req = [(2, 1), (2, 3), (4, 3), (5, 5)]

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
        for i in 
            for j in -s_radius:s_radius
                d = dist((req_x, req_y), (i, j))
                if d < s_radius
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




# VISUALIZATION
# =============
# We will create a matrix where:
#   0 -> Nothing
#   1 -> Sensor placed
#   2 -> Covered by sensor
#   3 -> Required to be covered by sensor
# Then we will plot it using heatmap

sol = Array{Int32}(value.(a))
matrix = copy(sol)

for (req_x, req_y) in req
    for k in S
        matrix[req_x, req_y, k] = 3
    end
end

for (k, (_, s_radius, _)) in enumerate(sensors)
    for i in M
        for j in N
            if sol[i, j, k] == 1
                for x in -s_radius:s_radius
                    for y in -s_radius:s_radius
                        s_pos_x = i + x
                        s_pos_y = j + y
                        
                        if s_pos_x >= 1 && s_pos_x <= m && s_pos_y >= 1 && s_pos_y <= n
                            if matrix[s_pos_x, s_pos_y, k] == 0
                                matrix[s_pos_x, s_pos_y, k] = 2
                            end
                        end
                    end
                end
            end
        end
    end
end

function num2col(i)
    if i == 0
        return colorant"black"
    elseif i == 1
        return colorant"blue"
    elseif i == 2
        return colorant"lime"
    else
        return colorant"red"
    end
end

hms = []
for (k, (s_name, s_radius, s_cost)) in enumerate(sensors)
    # hm = heatmap(reverse(matrix[:, :, k], dims=1), axis=:none, legend=false,
    #              title=s_name)
    hm = plot(num2col.(matrix[:, :, k]), legend=false, title=s_name, axis=:none)
    push!(hms, hm)
end
p = plot(hms..., layout=(1, 5), size=(1500, 300), show=true)
savefig(p, "tmp.png")

println("Total cost: ", objective_value(model))
@show(matrix)