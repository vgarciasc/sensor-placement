using JuMP, CPLEX
using Colors, Plots
using CSV, DataFrames

# ==============
# INITIALIZATION
# ==============

# Read data from scenario CSV
filename = "points_3.csv"
data = CSV.read(filename, DataFrame, header=true)

data_req = data[(data[:, "Camara Gran Angular"] .+
                 data[:, "Camara Angulo Estrecho"] .+
                 data[:, "Sensor Volumetrico"] .+
                 data[:, "Detector sismico"] .+
                 data[:, "Detector humo"]) ./ 5 .> 0.3, :]
req_x = Array{Int32}((data_req[:, "Coord_x (m)"] .+ 10) ./ 10)
req_y = Array{Int32}((data_req[:, "Coord_y (m)"] .+ 10) ./ 10)
req = [(req_x[i], req_y[i]) for i in 1:size(req_x, 1)]

data_spots = data[data[:, "Punto de Vigilancia"] .== 1, :]
spots_x = Array{Int32}((data_spots[:, "Coord_x (m)"] .+ 10) ./ 10)
spots_y = Array{Int32}((data_spots[:, "Coord_y (m)"] .+ 10) ./ 10)
spots = [(spots_x[i], spots_y[i]) for i in 1:size(spots_x, 1)]

m, n = 50, 50
M, N = 1:m, 1:n

sensors = [
    ("wide camera", 3, 42),
    ("narrow camera", 6, 112),
    ("volumetric sensor", 4, 93),
    ("seismic detector", 2, 8),
    ("smoke detector", 1, 6)
]
s = size(sensors, 1)
S = 1:s
c = [i for (_, _, i) in sensors]


# ============
# OPTIMIZATION
# ============

# Define the model
model = Model(CPLEX.Optimizer)

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

for pos_x in M
    for pos_y in N
        if (pos_x, pos_y) ∉ spots
            @constraint(model, sum(a[pos_x, pos_y, k] for k in S) == 0)
        end
    end
end

optimize!(model)


# =============
# VISUALIZATION
# =============

# We will create a matrix where:
#   0 -> Nothing
#   1 -> Sensor placed
#   2 -> Covered by sensor
#   3 -> Required to be covered by sensor
# Then we will plot it using heatmap

sol = Array{Int32}(round.(value.(a)))
matrix = copy(sol)

for (req_x, req_y) in req
    for k in S
        if matrix[req_x, req_y, k] == 0
            matrix[req_x, req_y, k] = 3
        end
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

for (spot_x, spot_y) in spots
    for k in S
        if matrix[spot_x, spot_y, k] == 0
            matrix[spot_x, spot_y, k] = 4
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
    elseif i == 3
        return colorant"red"
    elseif i == 4
        return colorant"purple"
    end
end

hms = []
for (k, (s_name, s_radius, s_cost)) in enumerate(sensors)
    hm = plot(num2col.(matrix[:, :, k]), legend=false, title=s_name, axis=:none, 
    top_margin=2Plots.mm, bottom_margin=2Plots.mm)
    push!(hms, hm)
end
p = plot(hms..., layout=(1, 5), size=(1500, 300), show=true, 
    suptitle="Total cost: $(objective_value(model)), filename: $filename, formulation 1",
    top_margin=2Plots.mm, bottom_margin=2Plots.mm)
savefig(p, "tmp.png")

println("Total cost: ", objective_value(model))