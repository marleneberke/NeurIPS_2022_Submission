#For separately getting the Jaccard similarity between objects inferred to be in
#the room and the average Euclidean distance between matched inferred objects
#and ground-truth objects

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

#for one scene, calulate Jaccard sim and the average distance between pairs
#each element of the vector is an Object3D.
#dists is an array that will contain the distance between every paired object ever
function similarity(gt::Vector{Any}, obs::Vector{Any}, dists::Array{Float64})
    gt_categories = last.(gt)
    obs_categories = last.(obs)
    #J = jaccard_similarity(gt_categories, obs_categories)
    union_val = 0
    #weighted_intersection = 0
    intersection = 0

    costs = 0
    for category in 1:params.n_possible_objects
        gt_index = findall(gt_categories .== category)
        obs_index = findall(obs_categories .== category)

        n_matches = 0
        if !isempty(gt_index) && !isempty(obs_index)
            cost_matrix = calculate_matrix(gt[gt_index], obs[obs_index])
            #println(cost_matrix)
            #println(size(cost_matrix))
            assignment, cost = hungarian(cost_matrix)
            costs = costs + cost
            n_matches = sum(assignment!=0) #how many things got matched up
            for i = 1:length(cost) #length of cost is always 1. it's just the total cost
                if assignment[i] != 0 #skip unpaired stuff
                    dist = cost_fxn(obs[obs_index][i], gt[gt_index][assignment[i]])
                    push!(dists, dist)
                end
            end

            intersection = intersection + n_matches
        end
        union_val = union_val + length(obs_index) + length(gt_index) - n_matches #subtract n_matches to avoid double counting
    end

    if union_val == 0 && weighted_intersection == 0
        return 1., costs/intersection, dists #costs / intersection so it returns average distance
    else
        return intersection/union_val, costs/intersection, dists
    end
end


function similarity_3D(num_videos::Int64, dict, ground_truth_world_states, inferred_world_states)
    sim = zeros(num_videos)
    dist = zeros(num_videos)
    dists = Float64[] #track the distance between each paried object
    for v = 1:num_videos
        sim[v], dist[v], dists = similarity(ground_truth_world_states[v], inferred_world_states[v, "inferred_best_world_state"], dists)
    end
    return sim, dist, dists
end

function write_3D_accuracy_csvs(full_path::String, lesioned_path::String, json_file_path::String, num_videos::Int64, num_training_videos::Int64)
    online_data = CSV.read(full_path * "online_ws.csv", DataFrame; delim = "&")
    retro_data = CSV.read(full_path * "retro_ws.csv", DataFrame; delim = "&")
    lesioned_data = CSV.read(lesioned_path * "retro_ws.csv", DataFrame; delim = "&")

    ################################################################################
    #could equally use input or output dictionary
    #dict = @pipe path * "../data_labelled_detr.json" |> open |> read |> String |> JSON.parse

    dict = @pipe json_file_path |> open |> read |> String |> JSON.parse

    online_data = sort!(online_data, :video_number) #undoes whatever shuffle happened
    retro_data = sort!(retro_data, :video_number)
    lesioned_data = sort!(lesioned_data, :video_number)

    ground_truth_world_states = get_ground_truth(dict, num_videos)
    ################################################################################
    online_world_states = new_parse_data(online_data, num_training_videos, num_particles)
    retrospective_world_states = new_parse_data(retro_data, num_videos, num_particles)
    lesioned_world_states = new_parse_data(lesioned_data, num_videos, num_particles)

    Jacc_sim_online, avg_dist_online, dists_online = similarity_3D(num_training_videos, dict,
    ground_truth_world_states, online_world_states)

    Jacc_sim_retro, avg_dist_retro, dists_retro = similarity_3D(num_videos, dict,
    ground_truth_world_states, retrospective_world_states)

    Jacc_sim_lesioned, avg_dist_lesioned, dists_lesioned = similarity_3D(num_videos, dict,
    ground_truth_world_states, lesioned_world_states)

    new_df = DataFrame(video = 1:num_videos,
        Jacc_sim_online = vcat(Jacc_sim_online, fill(NaN, num_videos - num_training_videos)),
        avg_dist_online = vcat(avg_dist_online, fill(NaN, num_videos - num_training_videos)),
        Jacc_sim_retrospective = Jacc_sim_retro,
        avg_dist_retro = avg_dist_retro,
        Jacc_sim_lesioned = Jacc_sim_lesioned,
        avg_dist_lesioned = avg_dist_lesioned)

    CSV.write(full_path * "similarity3D.csv", new_df)

    cil = 0.95
    mean_online = sum(dists_online)/length(dists_online)
    bs_online = bootstrap(mean, dists_online, BasicSampling(1000))
    bci_online = confint(bs_online, BasicConfInt(cil))

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
    #
    # println("length(dists_retro) ", length(dists_retro))
    # println("length(dists_lesioned) ", length(dists_lesioned))

    # avg_dists = DataFrame(online_mean = sum(dists_online)/length(dists_online),
    #                     retro = sum(dists_retro)/length(dists_retro),
    #                     lesioned = sum(dists_retro)/length(dists_lesioned))
    # println(avg_dists)
    # CSV.write(full_path * "3D_dists.csv", new_df)
end
