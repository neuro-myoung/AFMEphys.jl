module AFMEphys

using CSV, DataFrames, Statistics, NumericalIntegration

include("fileManagement.jl")
include("preprocess.jl")

export makeFileList, preprocessFile, preprocessFolder

end
