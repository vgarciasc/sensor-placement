using CSV, DataFrames

# Read data from "Scenario0.csv"
data = CSV.read("Scenario0.csv", DataFrame, header=true)
data