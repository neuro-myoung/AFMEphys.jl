function findPeak(df::DataFrame, var::Symbol, window) ::Float64
  subset = filter(x -> x.ti>=(window[1]) && x.ti<(window[2]), df)

  return maximum(abs.(subset[!,var]))
end

function findReversal(df::DataFrame, window) ::Float64
  
  subset = filter(x -> x.ti>=(window[1]) && x.ti<(window[2]), df)
  
  ibest = 1
  dxbest = 10000
  for i in eachindex(subset[!,:i])
    dx = abs(subset[i, :i]-0)
    if subset[i, :i] > 3
      break
    elseif dx < dxbest
      dxbest = dx
      ibest = i
    end

  end
  
  return subset[ibest,:v]
end

function findSteadyState(df::DataFrame, var::Symbol, window) ::Float64
  
  subset = filter(x -> x.ti>=(window[1]) && x.ti<(window[2]), df)

  return mean(subset[!,var])
end


function findThreshLoc(df::DataFrame, threshold::Float64, window)::Int64
  
  subset = filter(x -> x.i >= threshold && x.ti >= window[1], df)
  return minimum(subset.index)
end

function summarizeData(fileList)
  
  colnames = [:path, :uniqueID, :date, :construct, :cell, :protocol, :velocity, :kcant, :dkcant, :osm, :Rs, :Rscomp, :Cm, :seal, :vhold, 				          :vstep, :peaki, :tpeaki, :peakf, :tpeakf, :peakw, :tpeakw, :wpeakf, :leak, :offset, :stdev, :delay, :thresh, :threshind, :fthresh, 
              :wthresh, :rev, :ss, :ssdensity]

  coltypes = [String, String, String, String, String, String, Float64, Float64, Float64, Int64, Float64, Int64, Float64, Float64, 
              Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, 
              Int64, Float64, Float64, Float64, Float64, Float64]

  summaryDf = DataFrame(coltypes, colnames)

  for i in 1:length(fileList)
    baseFileName = chop(fileList[i], tail=length("preprocessed.csv"))
    params = CSV.read(baseFileName * "params.csv", delim=",", DataFrame)
    df = CSV.read(fileList[i], delim=",", DataFrame)
  
    peaki = findPeak(df, :i_blsub, [700,1200])
    peakf = findPeak(df, :force, [700,1200])
    peakw = findPeak(df, :work, [700,1200])
    tpeakf = filter(x -> x.force == peakf, df).tin0[1]
    tpeaki = filter(x -> x.i_blsub == peaki, df).ti[1]
    tpeakw = filter(x -> x.work == peakw, df).tin0[1]
    wpeakf = filter(x -> x.force == peakf, df).work[1]
    offset = mean(filter(x -> x.ti >= 700 && x.ti <= 700+50, df).i)
    vstep = mean(filter(x -> x.ti >= 700 && x.ti <= 700+50, df).v)
    leak = mean(filter(x -> x.ti >= 50 && x.ti <= 150, df).i)
    stdev = std(filter(x -> x.ti >= 700 && x.ti <= 700+50, df).i)
    vhold = mean(filter(x -> x.ti >= 50 && x.ti <= 150, df).v)
    delay = tpeaki - tpeakf
    seal = vhold/leak
    thresh = abs(offset) + 5*stdev
    threshind = findThreshLoc(df, thresh, [700,1200])+1
    wthresh = df[threshind,:].work
    fthresh = df[threshind,:].force
    date = filter(row -> row[1] == "date", params)[1,2]
    cell = filter(row -> row[1] == "cell#", params)[1,2]
    Rs = parse(Float64, filter(row -> row[1] == "Rs", params)[1,2])
    Cm = parse(Float64,filter(row -> row[1] == "Cm", params)[1,2])
    Rscomp = parse(Int64,filter(row -> row[1] == "Rscomp", params)[1,2])
    kcant = parse(Float64,filter(row -> row[1] == "kcant", params)[1,2])
    dkcant = parse(Float64,filter(row -> row[1] == "dkcant", params)[1,2])
    protocol = filter(row -> row[1] == "protocol", params)[1,2]
    velocity = parse(Float64,filter(row -> row[1] == "velocity", params)[1,2])
    construct = filter(row -> row[1] == "construct", params)[1,2]
    osm = parse(Int64,filter(row -> row[1] == "mosm", params)[1,2])
    uniqueID = filter(row -> row[1] == "uniqueID", params)[1,2]
    path = fileList[i]
    rev = findReversal(df, [2500,3000])
    ss = findSteadyState(df, :i, [2960,3048])
    ssdensity = ss/Cm
    
    push!(summaryDf, (path, uniqueID, date, construct, cell, protocol, velocity, kcant, dkcant, osm, Rs, Rscomp, Cm, seal, vhold, 
          vstep, peaki, tpeaki, peakf, tpeakf, peakw, tpeakw, wpeakf, leak, offset, stdev, delay, thresh, threshind, fthresh, wthresh, 
          rev, ss, ssdensity))			
  end

  return summaryDf
end