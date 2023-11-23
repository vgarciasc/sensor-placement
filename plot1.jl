using Colors, Plots

m, n = 5, 5
M, N = 1:m, 1:n

# Sensor data
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
sol = zeros(m, n, s)
sol[:, :, 1] = [0 0 0 0 0; 0 0 1 0 0; 0 1 0 0 0; 1 0 0 0 0; 0 0 0 0 0]
sol[:, :, 2] = [0 0 0 0 0; 0 0 1 0 1; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
sol[:, :, 3] = [0 0 0 0 0; 0 0 1 1 1; 1 1 0 0 0; 1 0 0 0 0; 0 0 0 0 0]

matrix = copy(sol)

for (req_x, req_y) in req
    for k in S
        matrix[req_x, req_y, k] = 2
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
                                matrix[s_pos_x, s_pos_y, k] = 3
                            end
                        end
                    end
                end
            end
        end
    end
end

@show(matrix)
hms = []
for (k, (s_name, s_radius, s_cost)) in enumerate(sensors)
    hm = heatmap(matrix[:, :, k], c=cgrad([:black, :red, :lime], categorical=true), legend=false)
    push!(hms, hm)
end

plot(hms..., layout=(1, 5), size=(1500, 300))