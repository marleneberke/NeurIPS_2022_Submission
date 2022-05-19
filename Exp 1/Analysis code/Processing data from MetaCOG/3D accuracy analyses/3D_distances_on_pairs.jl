#For figuring out which ground-truth objects are correctly inferred by both retro
#Metagen and by lesioned MetaGen and calculating the average Euclidean distance
#between paired inferrred and ground-truth objects for that subset of inferred
#objects that both retro and lesioned got.

using Hungarian
using CSV
using DataFrames
using JSON
using Pipe: @pipe
using MetaGen

function cost_fxn(obs::Object3D, gt::Object3D)
    d = sqrt((obs[1] - gt[1])^2 + (obs[2] - gt[2])^2 + (obs[3] - gt[3])^2)
    return d
    #return minimum([1., (d / 362.)^2]) #don't want cost greater than 1 for a pairing
    #362 is diagonal of a 256 by 256 image
end

function calculate_matrix(gt::Vector{Any}, obs::Vector{Any})
    matrix = Matrix{Float64}(undef, length(obs), length(gt)) #obs are like workers, gt like tasks
    for i = 1:length(obs)
        for j = 1:length(gt)
            matrix[i,j] = cost_fxn(obs[i], gt[j])
        end
    end
    return matrix
end

#dists is an array that will contain the distance between every paired object ever
#gt_paired is an array that contains the gt object that got paired
function get_pairs(gt::Vector{Any}, obs::Vector{Any}, gts_paired::Vector{Any}, dists::Array{Float64})
    gt_categories = last.(gt)
    obs_categories = last.(obs)

    for category in 1:params.n_possible_objects
        gt_index = findall(gt_categories .== category)
        obs_index = findall(obs_categories .== category)

        if !isempty(gt_index) && !isempty(obs_index)
            cost_matrix = calculate_matrix(gt[gt_index], obs[obs_index])
            assignment, _ = hungarian(cost_matrix)
            println("assignment ", assignment)
            for i = 1:length(assignment)
                if assignment[i] != 0 #skip unpaired stuff
                    println("gt[gt_index] ", gt[gt_index])
                    println("assignment[i] ", assignment[i])
                    dist = cost_fxn(obs[obs_index][i], gt[gt_index][assignment[i]])
                    push!(dists, dist)
                    push!(gts_paired, gt[gt_index][assignment[i]])
                end
            end
        end
    end
    return gts_paired, dists
end


function pair_up(num_videos::Int64, dict, ground_truth_world_states, inferred_world_states)
    gts_paired = []
    dists = Float64[] #track the distance between each paried object
    for v = 1:num_videos
        gts_paired, dists = get_pairs(ground_truth_world_states[v], inferred_world_states[v, "inferred_best_world_state"], gts_paired, dists)
    end
    return gts_paired, dists
end

function print_distances(full_path::String, lesioned_path::String, json_file_path::String, num_videos::Int64, num_training_videos::Int64)
    retro_data = CSV.read(full_path * "retro_ws.csv", DataFrame; delim = "&")
    lesioned_data = CSV.read(lesioned_path * "retro_ws.csv", DataFrame; delim = "&")

    ################################################################################
    #could equally use input or output dictionary
    #dict = @pipe path * "../data_labelled_detr.json" |> open |> read |> String |> JSON.parse

    dict = @pipe json_file_path |> open |> read |> String |> JSON.parse

    retro_data = sort!(retro_data, :video_number)
    lesioned_data = sort!(lesioned_data, :video_number)

    ground_truth_world_states = get_ground_truth(dict, num_videos)
    ################################################################################
    retrospective_world_states = new_parse_data(retro_data, num_videos, num_particles)
    lesioned_world_states = new_parse_data(lesioned_data, num_videos, num_particles)

    gt_paired_lesioned, dists_lesioned = pair_up(num_videos, dict,
    ground_truth_world_states, lesioned_world_states)

    gt_paired_retro, dists_retro = pair_up(num_videos, dict,
    ground_truth_world_states, retrospective_world_states)

    println("length(dists_lesioned) ", length(dists_lesioned))
    println("length(dists_retro) ", length(dists_retro))


    indices_of_intersection_retro = findall(in(gt_paired_lesioned), gt_paired_retro)
    indices_of_intersection_lesioned = findall(in(gt_paired_retro), gt_paired_lesioned)

    println("length(indices_of_intersection_lesioned) ", length(indices_of_intersection_lesioned))
    println("length(indices_of_intersection_retro) ", length(indices_of_intersection_retro))

    dists_retro = dists_retro[indices_of_intersection_retro]
    dists_lesioned = dists_lesioned[indices_of_intersection_lesioned]

    println("length(dists_lesioned) ", length(dists_lesioned))
    println("length(dists_retro) ", length(dists_retro))


    cil = 0.95
    mean_retro = sum(dists_retro)/length(dists_retro)
    bs_retro = bootstrap(mean, dists_retro, BasicSampling(1000))
    bci_retro = confint(bs_retro, BasicConfInt(cil))

    mean_lesioned = sum(dists_lesioned)/length(dists_lesioned)
    bs_lesioned = bootstrap(mean, dists_lesioned, BasicSampling(1000))
    bci_lesioned = confint(bs_lesioned, BasicConfInt(cil))

    return bci_retro, bci_lesioned

    #println("mean_online ", mean_online)
    #println("bci_online ", bci_online)
    # println("mean_retro ", mean_retro)
    # println("bci_retro ", bci_retro)
    # println("mean_lesioned ", mean_lesioned)
    # println("bci_lesioned ", bci_lesioned)

    # avg_dists = DataFrame(online_mean = sum(dists_online)/length(dists_online),
    #                     retro = sum(dists_retro)/length(dists_retro),
    #                     lesioned = sum(dists_retro)/length(dists_lesioned))
    # println(avg_dists)
    # CSV.write(full_path * "3D_dists.csv", new_df)
end
