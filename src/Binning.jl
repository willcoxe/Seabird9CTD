# Create a routine for binning values by depth in a DataFrame
# using Query
# using DataFramesMeta
# using DataFrames

export bin_seabird_data

function bin_seabird_data(df, binsize)
      # Copy dataframe to new dataframe to avoid editing the original dataframe
      #df = myDF

      # set size of bins, assumed that the depth column is :depSM in input dataframe.
      binInterval = binsize/2
      binCol = df.depSM

      # #
      # columnnames = names(df)
      # columns = [Symbol(col) => Float64[] for col in columnnames]
      # newDF = DataFrame(columns...)

      uniDep = [Int(round(df.depSM[i])) for i in 1 : size(df)[1]]
      minDep = Int(round(minimum(binCol)))
      maxDep = Int(round(maximum(binCol)))

      ## Main functionality of this script

      # Get all the file numbers
      #fnumbers = unique(df.fNum)

      # Remove all the irrelevant columns for the moment
      tstq = df[!, Not([:longitude, :latitude, :fName])]   #, :convLat, :convLon])]
      @debug "Processing for " join(names(tstq), " ")

      # duplicate @testdf!
      # columnnames = names(tstq)
      # columns = [Symbol(col) => Float64[] for col in columnnames]
      # newDF = DataFrame(columns...)
      newDF = empty(tstq)
      #println(names(newDF))

      # Want to add a bindepth column eventually. Need to add chosen values to array for each iteration
      bindepths = []
      count = 0

      #recordnumber = 1     # if by number record addition is necessary
      #fileno = 1            # Starting filenumber is 1st file

      # While the file number is under the maximum file number
      #while fileno <= length(fnumbers)
      for fileno in unique(df.fNum)

            # All the data for this one file number in tst DataFrame
            tst = @where(tstq, :fNum .== fileno)

            # Remove sampletime and utctime since these can't be averaged in the same way
            #tst = tst[:, Not([:sampletime,:utcstart])]

            # create the dataframe based on the named columns in tst
            #columnnames = names(tst)
            #columns = [Symbol(col) => Float64[] for col in columnnames]
            #tmpDF = DataFrame(columns...)

            # Select the values for the depth between max and min depths
            #maxDep = tail(tst,1)[:depSM][1]     # maximum depth based on the deepest value for the file
            #maxDep = last(df)[:depSM]
            maxDep = maximum(tst.depSM)
            calcDep = minDep                    # minimum depth prob always 0

            while calcDep <= maxDep
                  #println(calcDep, " <= ", maxDep, " & count ", count+=1)
                  # append the appropriate bindepth to bindepth array
                  # have to do this for each calculated value so the lengths
                  # stay the same,
                  #println("Adding ", calcDep, " to bindepths for file ", fileno, " total = ", length(bindepths))
                  append!(bindepths, calcDep)

                  # use binintervals to +/- the depths
                  fra = calcDep - binInterval
                  to = calcDep + binInterval

                  # if needed check which depths it is using from the list
                  #println("For file ", fileno, " from " , fra, "to ", to)

                  # query dataframe between those depths
                  if fra < 0
                        q = @where(tst, :depSM .> 0, :depSM .< to)
                   else
                        q = @where(tst, :depSM .> fra, :depSM .< to)
                  end

                  # for each named column, get the average value for that depth
                  newlst = []

                  if !isempty(q)
                        for col in eachcol(q)
                               # get utcstart time for diff with sampletime
                               utcstart_time = DateTime(q.utcstart[1])

                               # if the is datetime: calculate mean time by utcstart + average milliseconds expired
                              if eltype(col) .== DateTime
                                    millisecs = Dates.Millisecond(0)
                                    for val in col
                                          millisecs += DateTime(val) - utcstart_time  #- DateTime(row.utcstart)
                                    end
                                    # return subq
                                    subq = utcstart_time +
                                          Dates.Millisecond(Int(round(millisecs/Dates.Millisecond(length(col)))))
                              else
                                    # just take the mean of any float64 column
                                    #println("test, eltype", eltype(col))
                                    subq=mean(col)
                              end

                              if !@isdefined(subq)
                                     subq = missing
                              end

                              # push the mean value calculated to the list made for this depth
                              push!(newlst, subq)
                        end
                        # push this line of averages to the dataframe
                        #println("Writing line ", newlst)
                        push!(newDF, newlst)

                  else
                        # or if the line is empty; remove depth from bindepth
                        pop!(bindepths)
                  end

                  # Go to next bin interval
                  calcDep += binsize

            end


            #fileno += 1
      end
      #println("bindeps: ",length(bindepths), " => ", nrow(newDF))
      # Finally, add the bindepths array as a column to make sure these are there
      newDF.bindepth = bindepths

      # remove NaNs
      newDF = filter(:prDM => x -> !any(f -> f(x), (ismissing, isnothing, isnan)), newDF)

      return(newDF)
end
