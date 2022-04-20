## Diagrams with depth
using Plots
using Plots.Measures

"""
Diagrams of station number and depth profile
Station = fNum
Depth = depSM or prDM or bindepth
Value = whatever you want the depth profile for,
	e.g. par, oxygen saturation, salinity, temperature etc

If df2 = Seabird9CTD.bin_seabird_data(df, 10)
then depth diagrams created by station for say salinity using
	depth_profile(df2[:, [:fNum, :bindepth, :sal00]])
"""
function depth_profile(df)
	# Filter out any lines with NaNs
	df = filter(:1 => x -> !any(f -> f(x), (ismissing, isnothing, isnan)), df)
	df = filter(:2 => x -> !any(f -> f(x), (ismissing, isnothing, isnan)), df)
	df = filter(:3 => x -> !any(f -> f(x), (ismissing, isnothing, isnan)), df)

	# Station number is a float, want absolute values
	absvals = []
	for i in df[:,:1]
		push!(absvals, abs(i))
	end

	# Set appropriate colour gradient
	l = length(unique(df[:,:1])) # by station number
    E(g::ColorGradient) = RGB[g[z] for z=LinRange(0,1,l)]

	# Plot diagram
	plot(df[:, :3], 				# want this to be parameter to make depth profile for
		df[:, :2], 					# depth on the y axis
		yflip = true, 				# need to flip the y axis to get a downward profile
		group = absvals, 			# group this by station number
		palette= cgrad(:phase) |> E, # set colours
		thickness_scaling=0.5, 	# letters small in legend
		legend = :outerright,
		dpi=300,
		xlabel = names(df)[3],
		ylabel = names(df)[2],
		title="Depth profile for stations",
		margin = 10mm)

end
