#processes the V scripts output by the models and turns particles into bootstrapped confidence intervals
#needs the ground_truth_V.csv file from ideal_V.jl

using MetaGen
using JSON
using Pipe: @pipe
using CSV
using Bootstrap

include("helper_bootstrap_V.jl")

function bootstrap_V(path::String)
    office_subset = ["chair", "bowl", "umbrella", "potted plant", "tv"]

    num_particles = 100
    n_possible_objects = length(office_subset)

    online_data = CSV.read(path * "online_V.csv", DataFrame; delim = "&")
    #retro_data = CSV.read(path * "retro_V.csv", DataFrame; delim = "&")
    #lesioned_data = CSV.read(path * "lesioned_V.csv", DataFrame; delim = "&")
    ground_truth_data = CSV.read(path * "../ground_truth_V.csv", DataFrame; delim = "&")

    #make CI on the average value for each entry in the V matrix
    #online_ci_averages = confidence_interval(online_data, num_particles, n_possible_objects, 1000, 0.95)

    #get MSE for each particle
    online_ci_MSE = MSE_and_confidence_interval(online_data, ground_truth_data, num_particles, n_possible_objects, 1000, 0.95)

    #merge them all together
    #online_V_processed = hcat(select(online_data, 1:2*n_possible_objects+1), online_ci_averages, online_ci_MSE, select(online_data, length(names(online_data))))

    online_V_processed = hcat(select(online_data, 1:2), online_ci_MSE)


    CSV.write(path * "online_V_processed.csv", online_V_processed)
end
