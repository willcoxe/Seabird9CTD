```
This script opens SeaBird 9 CTD files and writes them to a dataframe.
Replies on:
   DelimitedFiles.jl
   DataFrames.jl
   StatsBase.jl
   Glob.jl
```
using DelimitedFiles
using DataFrames
using DataFramesMeta
using StatsBase
using Glob
using StatsBase # for countmap
using Dates # to make sure the datetime for each sample is present
using DataStructures # so I can use counter
# Removes characters from strings with RemChar.jl in package

export df_from_cnv
export cnv_directory

##
```
This function reads a SeaBird 9 file and returns a DataFrame containing columns for each variable.
It currently requires manual input of a filenumber so each individual file contents can be added.
Requires RemChar.jl to be loaded to deal with some special escape characters remaining in the column names.
```
function df_from_cnv(fileNumber, f)

    # Reading the contents of the file per line to obtain
    # 1. Intrument data
    # 2. Column headers
    whole_f = readlines(f)
    instrument_data = []
    columns = []
    #end_header = 1;
    local x = 1
    activities = []
    latitudes = []
    longitudes = []
    utctime = []
    hexfile = []

    for line in whole_f
        # Match the lines starting with *, these are the instrument data
        m = match(r"^(\*)", line)
        if m != nothing
            push!(instrument_data, line)

            # first want activity 398 from line FileName = D:\CTD_SBE911\DAT\26DA.2017.9.398.hex
            # alt = C:\Data\CTD\2021\KnudRasmussen_2021\2021CTD-Aug\Raw\KR21046.hex
            e = match(r"FileName", line)
            if e != nothing
                try
                    push!(activities, parse(Int32, split(line, ".")[4,1]))
                catch
                    a = split(line, "\\")                   # edited april 2022
                    push!(activities, chop(last(a), tail =4, head=2))
                end

            end

            # want latitude for this file
            e = match(r"(NMEA Latitude)", line)
            if e != nothing
                push!(latitudes, join(split(line, " ")[5:7], " "))
            end

            # want longitude for this file
            g = match(r"(NMEA Longitude)", line)
            if g != nothing
                push!(longitudes, join(split(line, " ")[5:7], " "))
            end

            # want to add the UTC time to the file
            h = match(r"(NMEA UTC)", line)
            if h != nothing
                push!(utctime, join(split(line, " ")[6:10], " "))
            end

            # Match the hex filename e.g.
            # "* FileName = D:\CTD_SBE911\DAT\26DA.2017.9.48.hex"
            k = match(r"(FileName)", line)
            if k != nothing
                push!(hexfile, last(split(line, "\\")))
            end
        end

        # Match the lines containing '# name', these are the column headers
        n = match(r"^(# name )", line)
        if n != nothing
            elements = split(line, " ")
            push!(columns, rstrip(elements[5],[':']))
        end
        #println(columns)
        # Match the word END since this is where the real data begins
        if match(r"(END)", line) != nothing
            #println(x, ":   ",line)
            global end_header = x
        end

        # set counter to next line
        x += 1

    end

    ## read delimited part of file
    contents = readdlm(f, header=false, skipstart=end_header)
    #println(contents)

    ## Read all data into a dataframe
    df = DataFrame(contents, :auto)

    ## Fix duplicates in column string if they exist: Need StatsBase to use countmap
    duplicates = []
    if isdefined([v for (k,v) in countmap(columns)], 1)
        println("Adding ", k, " ", v, " to duplicates")
        push!(duplicates, [k for (k,v) in countmap(columns) if v==2][1])
    else
        duplicates = columns
    end


    ## Write new column headers to dataframe
    global o = 1
    global t = 1

    #println(columns)
    #println(duplicates)
    # if length of columns is not equal to lenth of unique columns: have a duplicate value
    if length(unique(columns)) != length(columns)
        # find the duplicate : need using DataStructures for counter
        dupcol = [k for (k,v) in DataStructures.counter(columns) if v > 1][1]
        countcol = 1
        countdup = 1
        for c in columns
            if c == dupcol
                #println(c, "=>", dupcol, "   :", countcol)
                columns[countcol] = join([dupcol, countdup], "")
                countdup = countdup + 1
            end
            countcol = countcol+1
        end
    end

    ## check cols still same length as df header?

    #### Removed April 2022 (not sure if gonna work) >> why timesS1 and 2 removed?
    for c in columns
        # Check not a duplicate!
        for dup in duplicates
            # If not a duplicate > write header
            #if c != dup
            #    println(c, " ", dup)
            #    rename!(df, names(df)[o] =>  columns[o])
                #println("success for ", names(df)[o])
            # If it is a duplicate add a number to the end to make it not a duplicate > write header
            #else
                #rename!(df, names(df)[o] => join([columns[o], t]))
                rename!(df, names(df)[o] => columns[o])
                #println(c , " is a duplicate")
                global t +=1
            #end
        end
        global o += 1
    end
    ###########

    # add actvities
    df[!, :activity] = vcat(fill.(activities[1], size(df)[1])...)

    # repeat array of this one latitude onto dataframe
    if typeof(longitudes[1]) == String   #
    #if isdefined(latitudes,1)
        df[!, :latitude] = vcat(fill.(latitudes[1], size(df)[1])...)
    end

    # do same for longitude
    if typeof(longitudes[1]) == String   #
    #if isdefined(longitudes,1)
        df[!,:longitude] = vcat(fill.(longitudes[1], size(df)[1])...)
    end
    # repeat array of this one time onto dataframe
    if typeof(longitudes[1]) == String   #
    #if isdefined(utctime,1)
        df[!, :utcstart] = vcat(fill.(utctime[1], size(df)[1])...)
        df[!, :utcstart] = DateTime.(df.utcstart, "u dd yyyy  HH:SS:MM") # convert to datetime
    end

    # need to get the exact time/date for each sampled depth
    # need to remove all the nans/undefs/etc before this can be run.
    if "timeS1" in names(df)
        df[!, :timeS1] = replace!(df.timeS1, -9.990e-29 => NaN)
        df[!, :timeS1] = replace!(df.timeS1, 99e-29  => NaN)
        df = filter(:timeS1 => x -> !any(f -> f(x), (ismissing, isnothing, isnan)), df)

        df[!, :s]  = map(y->split(y, ".")[1], map(x -> string(x), df.timeS1))
        df[!, :s]  = map(s -> Dates.Second(s), df.s)
        df[!, :ms] = map(y->split(y, ".")[2], map(x -> string(x), df.timeS1))
        df[!, :ms] = map(ms -> Dates.Millisecond(ms), df.ms)

        # put times together
        df[!, :sampletime] = df.utcstart .+ df.s .+ df.ms

        # Drop some columns
        df = select!(df, Not(:s))
        df = select!(df, Not(:ms))
    end

    #println("Longitude!! ", longitudes)
    if typeof(longitudes[1]) == String   # make sure that if the latitude was given in MNEA it gets added to the df
        # convert longitudes/latitudes
        lon = split(longitudes[1], " ")  #"006 03.31 W"
        lat = split(latitudes[1], " ")   #"79 37.21 N"

        lonsec = parse(Float64, lon[2])/60
        latsec = parse(Float64, lat[2])/60

        coLat = parse(Float64,lat[1]) + latsec
        coLon = - parse(Float64,lon[1]) - lonsec

        df[!, :convLat] = vcat(fill.(coLat, size(df)[1])...)
        df[!, :convLon] = vcat(fill.(coLon, size(df)[1])...)

    #elseif isdefined(NMEAlat)


    end

    # Add filenumber, filename to distinguish stations
    fName = split(f, "/")

    # Changed from 8 to 5 for no reason; edited 15/01/2021
    #df[!, :fName] = vcat(fill.(fName[8], size(df)[1])...)
    df[!, :fName] = vcat(fill.(fName[end], size(df)[1])...)
    df[!, :fNum] = vcat(fill.(fileNumber, size(df)[1])...)

    # # need to add an activity column to match with any other files
    # # (e.g. from samples/bottles)
    # sep = split(fName[end], ".")
    # #pop!(sep)
    # println(sep)
    # #df[!, :activity] = vcat(fill.(sep[end], size(df)[1])...)
    #
    # # Add real station number from file
    # #section = split(fName[5], ".")

    ## Here 'station' is actually 'activity'
    section = split(fName[end], ".")
    pop!(section)
    #println(activities)
    #println(section)
    sect = 0
    try
        sect = parse(Int32, section[end])
    catch
        sect = parse(Int32, activities[1])
    end

    df[!, :station] = vcat(fill.(sect, size(df)[1])...)
    #return(section[4])

    # add hexfilename (need this for matching the activity)
    df[!, :hexfn] = vcat(fill.(hexfile, size(df)[1])...)

    # replace column names with better column names
    remCharDf(df)

    # if required print results
    #println(size(whole_f), "==> x ", x, "==> lat ", latitudes, "==> length df", size(df))
    return(df)
end

## For each file add to dataframe

function cnv_directory(directory)
    @info "Parsing files for " directory

    # glob cnv files in this directory
    files = glob("*.cnv", directory)
    @info "Total num files: " length(files)

    # Run script on all the files in this directory
    for s in 1:1:length(files)
        @debug "Parsing file number = ", s, " with filename: ", files[s]
        if s == 1 #!@isdefined(myDF)
            # Print out to doublecheck all files are being processed
            @debug "defining myDF"
            global myDF = df_from_cnv(s, files[s])
        else
            @debug "adding to myDF"
            global myDF = vcat(myDF, df_from_cnv(s, files[s]))
        end
    end
    return(myDF);
end
