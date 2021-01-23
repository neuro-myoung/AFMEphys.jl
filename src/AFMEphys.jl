module AFMEphys

using CSV, DataFrames, Statistics, NumericalIntegration

include("fileManagement.jl")
include("preprocess.jl")
include("summarize.jl")

export makeFileList, preprocessFile, preprocessFolder, findReversal, findPeak, findSteadyState, summarizeData 

end
