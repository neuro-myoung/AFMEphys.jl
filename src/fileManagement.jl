function makeFileList(path, suffixIdentifier)

  fileList = Vector{String}()
  for (root, dirs, files) in walkdir(path)
      rootList = split(root,"\\")
    for file in files
      if last(file, length(suffixIdentifier)) == suffixIdentifier
        push!(rootList, file)
        push!(fileList, join(rootList, "\\"))
      end
    end
  end
  
  return fileList
end