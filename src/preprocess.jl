function rescale!(df, dict)
		
  df[!,[:ti, :tin0, :tz, :tlat, :tv]] .*= dict[:t]
  df[!,[:v]] .*= dict[:v]
  df[!,[:i]] .*= dict[:i]

  return df
end

function blSubtract!(df, var::Symbol, window)

  subset =filter(x -> x.ti>=(window[1]) && x.ti<(window[2]), df)
  insertcols!(df, Symbol(var,'_',"blsub") => df[!,var].-mean(subset[!,var]))
  
  return df

end

function v2nm(V, calibration)
  
  gain = 20
  dist = gain * calibration * V
  
  return dist
end

function positionCorrection!(df, sensitivity, calibration=15.21)
  
  positionRaw = v2nm(df[!,:z], calibration)
  insertcols!(df, :deflection => df[!,:in0_blsub] .* sensitivity)
  insertcols!(df, :position => positionRaw .- df[!,:deflection] .- 								minimum(positionRaw))
  
  return df
end

function calculateForce!(df, kcant)
  
  insertcols!(df, :force => df[!,:deflection] .* kcant)
  
end

function calculateWork!(df)
  
  insertcols!(df, :work => cumul_integrate(df[!, :position], df[!, :force]))
  
  return df
end

function preprocessFile(df, dict, sensitivity, kcant, window)

  dfCopy = deepcopy(df)
  rescale!(dfCopy, dict)
  blSubtract!(dfCopy, :i, window)
  blSubtract!(dfCopy, :in0, window)
  positionCorrection!(dfCopy, sensitivity)
  calculateForce!(dfCopy, kcant)
  calculateWork!(dfCopy)
  
  return dfCopy

end

function preprocessFolder(path, suffixIdentifier, window)
	rescaleDict = Dict(:t => 1000, :i => 1e12, :v => 1e3);
		
	fileList = makeFileList(path, suffixIdentifier)	

	outputList = Vector{String}()
	for file in fileList
		dat = CSV.read(file, delim=",", DataFrame, header=["index", "ti", "i", "tv", "v","tin0","in0", "tz", "z","tlat","lat"])
		
		baseFilename = chop(file, tail=length(suffixIdentifier))
		
		sensitivityFile = CSV.read(baseFilename * "sensitivity.csv", delim=",", DataFrame, header=false)
				
		paramFile = CSV.read(baseFilename * "params.csv", delim=",", DataFrame, header=false, datarow=2)
		
		sensitivity = mean(sensitivityFile[!,1])
		kcant = parse(Float64, filter(row -> row[1] == "kcant", paramFile)[1,2])
			
		datProcessed = preprocessFile(dat, rescaleDict, sensitivity, kcant, window)
			
		CSV.write(baseFilename * "preprocessed.csv", datProcessed)
		push!(outputList, baseFilename * "preprocessed.csv")
	end
			
	return outputList
end
