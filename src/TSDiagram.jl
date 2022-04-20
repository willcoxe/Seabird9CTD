export make_ts_diagram

using Plots
using Plots.Measures
using GibbsSeaWater

#=
make_ts_diagram(df)
where df[:, []:potential_temp, :salinity, :pressure, :other_var]

Requires a dataframe input with 3 columns in order of
    1. Potential temperature (if necessary, can be created using GibbsSeaWater.jl)
    2. salinity (e.g. sal00 column)
    3. pressure (as obtained from bin_seabird_data, generally prDM)
    4. colour points of scatter plot by this column

output is a TS diagram
=#
function make_ts_diagram(newDF)

    #remove NaNs from salinity and temperature lists
    newDF = filter(:1 => x -> !any(f -> f(x), (ismissing, isnothing, isnan)), newDF)
    newDF = filter(:2 => x -> !any(f -> f(x), (ismissing, isnothing, isnan)), newDF)
    newDF = filter(:3 => x -> !any(f -> f(x), (ismissing, isnothing, isnan)), newDF)

    #     start                 step         stop
    t = minimum(newDF[:,1]) -1  : 1          : maximum(newDF[:,1]) +1   # temperature range (min Temp) -1  to (Max temp) +1 for margins
    s = minimum(newDF[:,2]) -1  : 0.5        : maximum(newDF[:,2]) +1   # salinity as above

    maxp = maximum(newDF[:,3]) + 1
    minp = minimum(newDF[:,3]) -1
    p = minp: maxp/length(s)    : maxp   # pressure has to be length of salinity vector to repeat up

    # function to get density
    f(s, t, p) = begin
        GibbsSeaWater.gsw_rho(s,t,p) #- 1000 # calc density for S, T, P
    end

    # create grid from density function
    S = repeat(reshape(s, 1, :), length(t), 1)  # repeat S along y axis
    T = repeat(t, 1, length(s))                 # repeat potT along X axis
    P = repeat(p', length(t), 1)                # repeat the transpose of p along t

    Z = map(f, S, T, P)                         # map density contours onto grid

    # create actual contours (with colourmap acton, , c = :acton)
    # using Plots.Measures for 10mm
    tl = string("TS-Diagram coloured by ", names(newDF)[4])
    println(tl)
    contour(s, t, Z,
                 xlabel="Salinity",
                 ylabel="Potential Temperature (C)",
                 #title=tl,
                 left_margin = 10mm,
                 bottom_margin=10mm,
                 top_margin=20mm,
                 right_margin=10mm,
                 legend=false,
                 fill=false,
                 #c= :viridis,
                 #seriescolor=:viridis,
                 levels = 6,
                 contour_labels=true,
                 cbar=true,
                 dpi=300)

    # Round the values for the groups
    scattergroup = map(x->round(x, digits=2), newDF[:,4])

    # Create colour gradient for the maximum bindepth as the final value
    #l = length(unique(newDF[:,4]))
    l = length(unique(scattergroup))

    E(g::ColorGradient) = RGB[g[z] for z=LinRange(0,1,l)]

    scatter!(newDF[:,2],
                  newDF[:,1],
                  group=scattergroup,
                  legend=:outertopright,
                  #ms=10,
                  #thickness_scaling=0.1, #35,
                  legendfontsize = 4,
                  palette= cgrad(:heat) |> E,
                  dpi=300,
                  markersize=5,
                  size=(800,600)
                  #cbar=true,
                  #seriescolor=:heat,
                  )

    # l = @layout [grid(1,1)]# a{0.01w}]
    # plot(h1,h2,layout=l)
end
