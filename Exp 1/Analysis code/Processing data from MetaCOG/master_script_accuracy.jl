# # #For some reason, have to add CSV with "using CSV" before activating the MetaGen environment
# #
#
# NN = "detr"
# overall_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/Final_Results/Full/"
#
# #file_path = overall_path*"../data_labelled_"*NN*".json"
# file_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/data_labelled_"*NN*".json"
#
# num_training_videos = 50
# num_frames = 20
# office_subset = ["chair", "bowl", "umbrella", "potted plant", "tv"]
#
# fitted_threshold = 0.0
#
# include("bootstrap_preprocess_data_hungarian.jl")
#
# num_videos = 100
# top_n = 5
# threshold = 0.0 #threshold for MetaGen inputs
# num_particles = 100
# params = Video_Params(n_possible_objects = 5)
#
# for i = 0:3
#     path = overall_path * "/shuffle_" *string(i)* "_" *NN* "/"
#     write_accuracy_csvs(path, fitted_threshold, top_n, num_videos, num_training_videos, num_frames)
# end

################################################################################
# include("accuracy_just_retro.jl")
#
# NN = "detr"
# #NN2 = "retinanet"
# overall_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/Final_Results/Lesioned/"
# #
# json_file_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/data_labelled_"*NN*".json"
# #folder_path  = overall_path*"mean_of_prior/"*NN
#
# num_videos = 100
# left_off = 1
# num_frames = 20
# office_subset = ["chair", "bowl", "umbrella", "potted plant", "tv"]
# threshold = 0.0 #threshold for MetaGen inputs
# num_particles = 100
# params = Video_Params(n_possible_objects = 5)
#
#
# for i = 0:3
#     path = overall_path*"/shuffle_" *string(i)* "_" *NN* "/"
#     accuracy_just_retro(json_file_path, path)
# end

################################################################################
# using Random
# using Bootstrap
# using Statistics
#
# Random.seed!(1234)
#
# NN = "detr"
# full_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/Final_Results/Full/"
# lesioned_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/Final_Results/Lesioned/"
# json_file_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/data_labelled_"*NN*".json"
#
# include("3D_accuracy.jl")
#
# num_videos = 100
# num_training_videos = 50
# num_particles = 100
#
# retro_mean = zeros(4)
# retro_lower = zeros(4)
# retro_upper = zeros(4)
# lesioned_mean = zeros(4)
# lesioned_lower = zeros(4)
# lesioned_upper = zeros(4)
# for i = 0:3
#     full_path_shuffle_n = full_path * "/shuffle_" *string(i)* "_" *NN* "/"
#     lesioned_path_shuffle_n = lesioned_path * "/shuffle_" *string(i)* "_" *NN* "/"
#     retro, lesioned = write_3D_accuracy_csvs(full_path_shuffle_n, lesioned_path_shuffle_n, json_file_path, num_videos, num_training_videos)
#     retro_mean[i+1] = retro[1][1]
#     retro_lower[i+1] = retro[1][2]
#     retro_upper[i+1] = retro[1][3]
#     lesioned_mean[i+1] = lesioned[1][1]
#     lesioned_lower[i+1] = lesioned[1][2]
#     lesioned_upper[i+1] = lesioned[1][3]
# end
# println("total mean retro ", mean(retro_mean))
# println("total lower retro ", mean(retro_lower))
# println("total lower upper ", mean(retro_upper))
# println("total mean lesioned ", mean(lesioned_mean))
# println("total lower lesioned ", mean(lesioned_lower))
# println("total upper lesioned ", mean(lesioned_upper))

################################################################################
using Random
using Bootstrap
using Statistics

Random.seed!(1234)

NN = "faster_rcnn"
full_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/Final_Results/Full/"
lesioned_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/Final_Results/Lesioned/"
json_file_path = "/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/data_labelled_"*NN*".json"

include("3D_distances_on_pairs.jl")

num_videos = 100
num_particles = 100

retro_mean = zeros(4)
retro_lower = zeros(4)
retro_upper = zeros(4)
lesioned_mean = zeros(4)
lesioned_lower = zeros(4)
lesioned_upper = zeros(4)
for i = 0:3
    full_path_shuffle_n = full_path * "/shuffle_" *string(i)* "_" *NN* "/"
    lesioned_path_shuffle_n = lesioned_path * "/shuffle_" *string(i)* "_" *NN* "/"
    retro, lesioned = print_distances(full_path_shuffle_n, lesioned_path_shuffle_n, json_file_path, num_videos, num_training_videos)
    retro_mean[i+1] = retro[1][1]
    retro_lower[i+1] = retro[1][2]
    retro_upper[i+1] = retro[1][3]
    lesioned_mean[i+1] = lesioned[1][1]
    lesioned_lower[i+1] = lesioned[1][2]
    lesioned_upper[i+1] = lesioned[1][3]
end
println("total mean retro ", mean(retro_mean))
println("total lower retro ", mean(retro_lower))
println("total lower upper ", mean(retro_upper))
println("total mean lesioned ", mean(lesioned_mean))
println("total lower lesioned ", mean(lesioned_lower))
println("total upper lesioned ", mean(lesioned_upper))
