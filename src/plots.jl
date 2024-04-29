
# """
#     plot_proc_distribution(stimerdf)

# Creates a plot showing the frequency and runtime impact of 
# all the SAS PROCs used in the workload.
# """
# function plot_proc_distribution(stimerdf; width=740)    
#     df = @chain stimerdf begin
#             @mutate(
#                 cleaned_desc = replace(desc, "NOTE: "=>"", "used (Total process time)"=>""),
#                 cpu_time = (system_cpu_time + user_cpu_time) / 1000,
#                 real_time = real_time / 1000
#             )
#             @filter(cleaned_desc != "The SAS System used:")
#             @filter(cleaned_desc != "SAS initialization used:")
#             @select(cleaned_desc, cpu_time, real_time)
#             @group_by(cleaned_desc)
#             @summarize(
#                 sum_cpu_time = sum(cpu_time), 
#                 mean_cpu_time = mean(cpu_time), 
#                 median_cpu_time = median(cpu_time),
#                 sum_real_time = sum(real_time), 
#                 mean_real_time = mean(real_time),
#                 median_real_time = median(real_time),
#                 ncnt = n()
#         )
#             @mutate(parallel_ratio =   sum_cpu_time / (sum_real_time + 0.0001))
#             #@filter(sum_cpu_time > 0.9) # remove proc's that did not consume any time
#     end

#     # check and see the spread of values for `sum_cpu_time` and if the 
#     # spread is too high use log scale for x-axis
#     sum_cpu_time = filter(x->x!=0, df.sum_cpu_time) # remove any zeros from the array (else result is Inf)
#     magnitude = -mapfoldr(round ∘ log10 ∘ abs, -, extrema(sum_cpu_time))
#     if magnitude > 6
#         xscale_type = "log"
#     else
#         xscale_type = "linear"
#     end

#     plt = df |> @vlplot(
#             mark={
#                 type="circle", 
#                 tooltip={content="data"}, 
#                 stroke="black", 
#                 strokeWidth=1
#                 },

#             x={
#                 field="sum_cpu_time", 
#                 scale={type=xscale_type}
#                 },
#             y={
#                 field="cleaned_desc"
#                 },
#             size={
#                 field="ncnt", 
#                 type="quantitative",
#                 scale={rangeMax=800, type="log"}
#                 },
#             color={
#                 field="parallel_ratio",
#                 type="quantitative"
#                 },
#             width=width
#     )
#     return plt
# end


"""
    plot_proc_frequency(strimerdf, [width])

Creates a plot showing the frequency and runtime impact of 
all the SAS PROCs used in the workload.
"""
function plot_proc_frequency(stimerdf; width=740)    
    df = @chain stimerdf begin
            @mutate(
                cleaned_desc = replace(desc, "NOTE: "=>"", "used (Total process time)"=>""),
                cpu_time = (system_cpu_time + user_cpu_time) / 1000,
                real_time = real_time / 1000
            )
            @filter(cleaned_desc != "The SAS System used:")
            @filter(cleaned_desc != "SAS initialization used:")
            @select(cleaned_desc, cpu_time, real_time)
            @group_by(cleaned_desc)
            @summarize(
                sum_cpu_time = round(sum(cpu_time), digits=2), 
                mean_cpu_time = round(mean(cpu_time), digits=2), 
                median_cpu_time = round(median(cpu_time), digits=2),
                sum_real_time = round(sum(real_time), digits=2), 
                mean_real_time = round(mean(real_time), digits=2),
                median_real_time = round(median(real_time), digits=2),
                ncnt = n()
        )
            @filter(sum_real_time !== 0.0)
            @mutate(efficiency =   round(sum_cpu_time / (sum_real_time), digits=2))
            @arrange(efficiency)
            #@filter(sum_cpu_time > 0.9) # remove proc's that did not consume any time
    end

    # Generate hover text
    htext = ["""
            $(r.cleaned_desc)<br />
            sum_cpu_time: $(r.sum_cpu_time)<br />
            mean_cpu_time: $(r.mean_cpu_time)<br />
            sum_real_time: $(r.sum_real_time)<br />
            mean_real_time: $(r.mean_real_time)<br />
            frequency: $(r.ncnt)<br />
            efficiency: $(r.efficiency)
    """ for r in eachrow(df)]


    layout = Config(
        margin = Config(l=196),
        title="PROC Level Execution Time & Frequency<br />Size = Frequency | Color = Efficiency",
        xaxis = Config(
            title = "seconds (log-scale)",
            type = "log",
            autoscale = true
        ),
    )

    t = Config(
        type="scatter",
        mode="markers",
        marker = Config(
            size = map(df.ncnt) do x
                rmin, rmax = minimum(df.ncnt), maximum(df.ncnt)
                tmin, tmax = 20,50 # range to scale the values to
                ((x-rmin) / (rmax - rmin)) * (tmax - tmin) + tmin
            end,
            color = df.efficiency,
            # colorscale = "Hot",
            colorscale = [
                ["0.0", "rgb(165,0,38)"],
                ["0.111111111111", "rgb(215,48,39)"],
                ["0.222222222222", "rgb(244,109,67)"],
                ["0.333333333333", "rgb(253,174,97)"],
                ["0.444444444444", "rgb(254,224,144)"],
                ["0.555555555556", "rgb(224,243,248)"],
                ["0.666666666667", "rgb(171,217,233)"],
                ["0.777777777778", "rgb(116,173,209)"],
                ["0.888888888889", "rgb(69,117,180)"],
                ["1.0", "rgb(49,54,149)"]
            ],
            opacity = 0.5
        ),
        text = htext,
        hoverinfo = "text",
        x = df.sum_real_time,
        y = df.cleaned_desc
    )

    config = Config( 
                showLink=false, 
                staticPlot=false, 
                editable=true, 
                displayModeBar="hover", 
                # displayModeBar=true,
                displaylogo=false,
                toImageButtonOptions = Config(format="svg"),
                responsive=true
                # modeBarButtonsToAdd=[ "drawline","drawopenpath","drawclosedpath",
                #                       "drawcircle","drawrect","eraseshape"]
        )    


    Plot(t, layout, config)
    # df
end



# """
#     plot_concurrency(wlmmetrics)

# Plots an area chart that displays how many jobs were running at any given
# point in time during the workload was under execution.
# """
# function plot_concurrency(wlmmetrics::DataFrame; width=600)
#     jobdct = Dict( x.jobdef_name => (st=x.startedTimeStamp, et=x.endedTimeStamp) for x in eachrow(wlmmetrics))

#     workstart = minimum(wlmmetrics.startedTimeStamp)
#     workend   = maximum(wlmmetrics.endedTimeStamp)
#     timescale = workstart:Second(1):workend

#     jobbit = Dict()

#     for j in keys(jobdct)
#         startTime, endTime = jobdct[j]
#         startidx = map(x -> x==startTime, timescale) |> findfirst
#         endidx = map(x -> x==endTime, timescale) |> findfirst
#         bitarr = zeros(Int, length(timescale))
#         bitarr[startidx:endidx] .= 1
#         jobbit[j] = bitarr
#     end

#     hmapdata = sum((values(jobbit) |> collect))
#     ndf = DataFrame(dt=timescale, njobs=hmapdata)

#     ndf |> @vlplot(
#                 mark={:area, tooltip=true},
#                 x={field="dt", title="DateTime", type="ordinal", timeUnit="hoursminuteseconds"},
#                 y={field="njobs", type="quantitative", title="# of Running Jobs"},
#                 width=width,
#                 title="Concurrency"       
#             )
# end




# """
#     plot_gantt_chart(wlmmetrics; [width, height])

# Generates a gantt chart visualizing job execution using the fields 
# `startedTimeStamp`, `endedTimeStamp` returned by Workload Manager as job status.
# Default setting is to return a VegaLite JSON payload which can be consumed inside 
# an html page. If `return_plot` is set to `true` then a VegaLite plot is returned. 

# If `width` is set to "container" along with a static height then the width uses
# responsive styling and changes with the viewport. If `height` is not defined and
# width is set to "container" then height is calculated based on the number of elements
# in the chart. 
# """
# function plot_gantt_chart(df::DataFrame; width=600, height=nothing)
#     # ndf = @transform(df, :runtime = :endedTimeStamp - :startedTimeStamp)
#     ndf = deepcopy(df)
#     ndf = @chain ndf begin
#         @mutate(runtime = Second(endedTimeStamp - startedTimeStamp))
#         @mutate(starttime = startedTimeStamp, endtime = endedTimeStamp)
#         @select(name, description, stage, tags, code_name, sasoption, 
#                 profile, queue, fileSetId, state, 
#                 submittedTimeStamp, startedTimeStamp, endedTimeStamp,
#                 starttime, endtime, returnCode)
#         @arrange(starttime)
#     end

#     nbars = size(ndf)[1]

#     height = height
#     if height === nothing
#         height = nbars * 10 # 10 per bar
#     end
    
#     plt = ndf |> 
#         @vlplot(mark={type="bar", tooltip={content="data"}}, 
#                 y={field="name", type="ordinal", sort="stage"}, 
#                 x={field="startedTimeStamp", type="temporal"}, 
#                 x2={field="endedTimeStamp", type="temporal"}, 
#                 width = width,
#                 height = height,
#                 color="returnCode:n", 
#                 title="Execution Order & Time")
#     plt
# end



# """
#     plot_job_variance(wlmmetrics)

# Plot the variance of job runtime for the same SAS code across the workload. 
# """
# function plot_job_variance(wlmmetrics; width=600)
#     df = @chain wlmmetrics begin
#             @mutate(totalRunTimeSec = Second(totalRunTime))
#             @mutate(totalRunTimeSec = getfield(totalRunTimeSec, :value))
#             @select(code_name, totalRunTimeSec, stage)
#     end

#    plt = df |> @vlplot(
#             mark = {type="point", tooltip={content="data"}},
#             x = {field = "code_name", type="nominal"},
#             y = {field = "totalRunTimeSec", type="quantitative"},
#             color = {field = "stage"},
#             width = width,
#             title = "Runtime Variance"
#     )

#     return plt
# end




# """
#     plot_error_matrix(df; [return_plot, height, width])

# Generates an error matrix heatmap showing `stage` in one axis and count of `returnCode`  
# returned by jobs in the respective stage. A visual element to provide the outcome of the
# workload for visually ensuring all the jobs completed with expected return code. 
# """
# function plot_error_matrix(df::DataFrame; height=200, width=200)
#     # rdf = @select(df, :stage, :returnCode)
#     rdf = df[!, [:stage, :returnCode]]
#     rdf = groupby(rdf, [:stage, :returnCode])
#     rdf = combine(rdf, :returnCode => length => :num)

#     plt = rdf |> @vlplot( 
#                         x="returnCode:n", 
#                         y="stage:o", 
#                         title="Return Code by Stage",
#                         width=width, height=height) +

#                 @vlplot(
#                         mark={type="rect", tooltip={content="data"}}, color="returnCode:n") +

#                 @vlplot(mark={type="text"}, text="num:n")

#     plt
# end





# function plot_cpu_real_time(stimer::DataFrame; width=600)

#     df = @chain stimer begin
#         @filter(desc == "NOTE: The SAS System used:")
#         @select(jobname, sys_cpu = system_cpu_time, user_cpu = user_cpu_time, real = real_time)
#         @pivot_longer(sys_cpu:real, names_to="time_kind", values_to="time_value")
#         @mutate(time_value = time_value / 1000)
#         @mutate(group = if_else(time_kind == "real", "real", "cpu"))
#     end 
    
#     # Calculate height of plot based on number of jobs * 24
#     height = (unique(df.jobname) |> length) * 24
    
#     df |> @vlplot(
#             mark={type="bar", tooltip=true}, 
#             x={field="time_value", title="Seconds", type="quantitative"}, 
#             y={field="jobname", title="Job Name"}, 
#             color="time_kind", 
#             yOffset="group", width=width, height=height,
#             title = "CPU Time vs Real Time"
#         )
# end



"""
    runtime_summary(wlmmetrics, stimer_metrics)

Returns a DataFrame with the overall runtime for each stage as reported
by Workload Manager and also by FULLSTIMER. 
"""
function runtime_summary(wlmmetrics, stimer_metrics)
    stimerDF = @chain stimer_metrics begin
        @filter(desc == "NOTE: The SAS System used:")
        @mutate(efficiency=(system_cpu_time+user_cpu_time)/real_time)
        @select(jobname, jobqueue, stage = jobstage, system_cpu_time, user_cpu_time, real_time, efficiency)
        @group_by(stage)
        @summarize(
                stimer_real = sum(real_time)/1000, 
                stimer_sys  = sum(system_cpu_time)/1000, 
                stimer_user = sum(user_cpu_time)/1000, 
                stimer_nrec = n(),
                efficiency = mean(efficiency)
                )
        end

    wlmDF = @chain wlmmetrics begin
        @select(stage, totalRunTime, totalWaitTime, endedTimeStamp, startedTimeStamp)
        @mutate(
                totalRunTime = getfield(totalRunTime, :value), 
                totalWaitTime = getfield(totalWaitTime, :value),
        )
        @group_by(stage)
        @mutate(WallClockTime = Second(maximum(endedTimeStamp) - minimum(startedTimeStamp)))
        @mutate(WallClockTime = getfield(WallClockTime, :value))
        @summarize(
                wlm_real  = sum(totalRunTime), 
                wlm_wait  = sum(totalWaitTime),
                wlm_clock = Second(maximum(endedTimeStamp) - minimum(startedTimeStamp)),
                wlm_nrec  = n()
        )
        @mutate(wlm_clock = getfield(wlm_clock, :value))
    end

    combinedDF = @left_join(wlmDF, stimerDF)

    @chain combinedDF begin
        @select(stage, stimer_sys, stimer_user, stimer_real, wlm_real, wlm_wait, wlm_clock, stimer_nrec, wlm_nrec, efficiency)
    end
end



"""
    summary_table(wlmmetrics)

Returns a per job summary table from WLM output.
"""
function summary_table(wlmmetrics)
    @chain wlmmetrics begin
        @select(stage, name, queue, profile, state, returnCode, totalRunTime, totalWaitTime, processId, id, source, fileSetId)
        @arrange(stage, name)
    end
end


""" 
    plot_io_efficiency(stimer)

Returs the IO efficiency of the tests (user+sys) / real time
"""
function plot_io_efficiency(stimer::DataFrame)
    ndfX = @chain stimer begin
                @select( desc, jobname, user_cpu_time, system_cpu_time, real_time )
                @filter( desc != "NOTE: SAS initialization used:")
                # set the IoCpuRatio to 0 if real_time == 0 (later filter these records as they are not of interest)
                @mutate( IoCpuRatio = if_else(real_time > 0, (user_cpu_time + system_cpu_time) / real_time, 0) )
                @filter( IoCpuRatio != 0 )
                # only get the final fullstimer block
                @filter(desc == "NOTE: The SAS System used:")
                @select(jobname, IoCpuRatio)
                @arrange(jobname) 
    end

    Preset.PlotContainer.responsive!()
    t = Config(type="scatter", x=ndfX[!, :jobname], y=ndfX[!, :IoCpuRatio], mode="markers")

    config = Config( showLink=false, 
                     staticPlot=false, 
                     editable=true, 
                     displayModeBar="hover", 
                     #displayModeBar=true,
                     displaylogo=false,
                     responsive=true,
                     toImageButtonOptions = Config(format="svg")
                     # modeBarButtonsToAdd=[ "drawline","drawopenpath","drawclosedpath",
                     #                       "drawcircle","drawrect","eraseshape"]
    )

    layout = Config(
		title = "IO Efficiency", 
		shapes = [
			Config(type="rect", xref="paper", yref="y", x0=0, y0=0.00, x1=1, y1=0.70, fillcolor= "#ffd3d3", opacity=0.2,
					line = Config(color="rgb(255, 0, 0)", width=0, dash="dot"))
		],
        yaxis = Config(title="cpu_time / real_time")
	)
    Plot(t, layout, config)
end




"""
    plot_runtime_efficiency(stimerDF)

"""
function plot_runtime_efficiency(stimerDF::DataFrame; 
    short_label_len=20,
    effiency_threshold=0.7,
    width::Union{Symbol, Int} = :auto,
    height::Union{Symbol, Int} = :auto,
    tick_font_size = 10
    )

    # Prepare DataFrame
    df = @chain stimerDF begin
            @filter(desc == "NOTE: The SAS System used:")
            @mutate(efficiency=(system_cpu_time+user_cpu_time)/real_time)
            @mutate( # convert time to seconds from millisecond
                system_cpu_time = system_cpu_time / 1000,
                user_cpu_time = user_cpu_time / 1000,
                real_time = real_time / 1000
            )
            @select(jobname, system_cpu_time, user_cpu_time, real_time, efficiency)
            @arrange(desc(efficiency))
        end

    total_real_time = round(Int, sum(df.real_time))
    total_usr_time = round(Int, sum(df.user_cpu_time))
    total_sys_time = round(Int, sum(df.system_cpu_time))
    avg_efficiency = round(mean(df.efficiency), digits=3)
    title = """Average Efficiency = $(avg_efficiency)<br>
            Total Real Time = $(total_real_time)s<br>
            Total USR+SYS Time = $(total_usr_time+total_sys_time)s"""

    # for clean plot shorten jobnames to jobname_len
    short_jobnames = map(df.jobname) do x
        if length(x) > short_label_len
            x = x[end-short_label_len:end]
        else
            x
        end
    end

    # Prepare text for mouse-over (hover)
    htext = map(eachrow(df)) do rec
                """jobname: $(rec.jobname)<br>
                USR: $(rec.user_cpu_time)<br>
                SYS: $(rec.system_cpu_time)<br>
                USR+SYS: $(round(rec.user_cpu_time+rec.system_cpu_time; digits=2))<br>
                REAL: $(rec.real_time)<br>
                EFFICIENCY: $(round(rec.efficiency; digits=2))"""
    end


    # Plotly Element to define efficiency band
    efficiency_rect = [
        Config(
            type = "rect",
            # x-reference is assigned to the plot paper [0,1]
            xref = "x2",
            # y-reference is assigned to the y-values 
            yref = "paper",
            x0 = 0,
            y0 = 0,
            x1 = effiency_threshold,
            y1 = 1,
            fillcolor = "#000000",
            opacity = 0.1,
            line = Config( width = 1)
        )
    ]

    # Calculate the width of the plot use 100px per group
    if width == :auto
        plot_width = 1024
    else
        plot_width = width
    end

    if height == :auto
        plot_height = size(df)[1] * 48
    else
        plot_height = height
    end


    # Plotly Layout
    layout = Config(
        title = title,
        margin = Config(l=196, t=240),
        shapes = efficiency_rect,
        width=plot_width,
        height=plot_height,
        barmode="stack",

        yaxis = Config(
            type = "multicategory", 
            title = "Jobs",
            tickangle = 0,
            tickfont = Config(size=tick_font_size),
            dividerwidth = 0.5,
            showdivider = true,
            dividercolor = "#0F0F0F"
        ),

        xaxis2 = Config(
            title = "Efficiency",
            overlaying = "x",
            side = "top",
            gridcolor = "#FFFFFF",
            rangemode = "tozero",
            autorange = true
        ),

        xaxis = Config(
            title = "Second(s)",
            rangemode = "tozero",
            autorange = true
        )
    )

    # Define individual Traces
    t1 = Config(
        type = "bar",
        y = [ short_jobnames, 
            ["cpu" for x in 1:length(short_jobnames)] ],
        x = df.user_cpu_time,
        orientation = "h",
        name = "USR",
        secondary_y = false
    )

    t2 = Config(
        type = "bar",
        y = [ short_jobnames, 
            ["cpu" for x in 1:length(short_jobnames)] ],
        x = df.system_cpu_time,
        orientation = "h",
        name = "SYS",
        secondary_y = false
    )

    t3 = Config(
        type = "bar",
        y = [ short_jobnames, 
            ["real" for x in 1:length(short_jobnames)] ],
        x = df.real_time,
        orientation = "h",
        name = "REAL",
        secondary_y = false
    )

    t4 = Config(
        type = "scatter",
        mode = "markers+lines",
        y = [ short_jobnames, 
            ["cpu" for x in 1:length(short_jobnames)] ],
        x = df.efficiency,
        # text = df.jobname,
        text = htext,
        hoverinfo = "text",
        name = "Efficiency",
        hovertext = htext,
        xaxis = "x2"
    )


    config = Config( 
            showLink=false, 
            staticPlot=false, 
            editable=false, 
            displayModeBar="hover", 
            #displayModeBar=false,
            displaylogo=false,
            toImageButtonOptions = Config(format="svg"),
            responsive=true
            # modeBarButtonsToAdd=[ "drawline","drawopenpath","drawclosedpath",
            #                       "drawcircle","drawrect","eraseshape"]
    )

    trace = [t1, t2, t3, t4]
    Plot(trace, layout, config)
end





"""
    catmap(vec, lookup)
Given a vector of data `vec` encode each unique value with values from `lookup` and
return the encoded values in form of a new vector
"""
function catmap(vec::Vector, lookup::Vector)
    uniqkeys = unique(vec) |> sort
    nuniq = length(uniqkeys)

    @assert nuniq <= length(lookup) # number of unique items should be < lookup vector

    lookup_dict = Dict(zip(uniqkeys, lookup[1:nuniq]))
    map(x->lookup_dict[x], vec)
end



"""
    plot_wlm_gantt_chart(wlmmetrics)

"""
function plot_wlm_gantt_chart(wlmmetrics::DataFrame)

    # filter dataset
    df = @chain wlmmetrics begin
            @select( name, 
                     startedTimeStamp, 
                     endedTimeStamp, 
                     totalRunTime, 
                     returnCode, 
                     code_name, 
                     sasoption 
                    )
            @arrange( desc(startedTimeStamp), 
                      desc(totalRunTime) 
                    )
    end


    # calculate x range (min, max)
    xmin = df.startedTimeStamp |> minimum
    xmax = df.endedTimeStamp |> maximum
    # adjust xmax to allow space for labels / text
    xmax = xmax + Second(300)

    # Create unique color codes for each returnCode => rCodeColors
    num_returncodes = unique(df.returnCode) |> length
    color_seed = [colorant"green", colorant"orange", colorant"red"]
    rcode_colors = distinguishable_colors(num_returncodes, color_seed)
    rcode_hexcolors = hex.(rcode_colors)
    df[!, :rCodeColor] = catmap(df.returnCode, rcode_hexcolors)


    # each bar in gantChart would be a seperate trace
    # iterate over each record and create a trace
    traces = Config[]
    for (idx,rec) in enumerate(eachrow(df))

        # create text to show on hover
        hattrs = [ "startTime", 
                   "endTime", 
                   "runTime", 
                   "returnCode", 
                   "code_name"
                ]
        hvals  = [ rec.startedTimeStamp, 
                   rec.endedTimeStamp, 
                   rec.totalRunTime, 
                   rec.returnCode, 
                   rec.code_name
                ]
        htext  = ["$(k) = $(v)<br>" for (k,v) in zip(hattrs, hvals)] |> join
        
        
        # attributes for trace Gantt Chart
        lineattr = Config( width=8, color=rec.rCodeColor )
        trace = Config( mode = "lines+text", 
                        line = lineattr, 
                        x = [rec.startedTimeStamp, rec.endedTimeStamp], 
                        y = [idx, idx], name="",
                        text = ["", "$(rec.totalRunTime.value) sec"],
                        textfont = Config(size=10, family="Courier New"),
                        textposition = "center right",
                        hoverinfo = "text",
                        hovertext = htext,
                        hoverlabel = Config(align="left", bgcolor="white"),
                        showlegend=false
                )
        push!(traces, trace)
    end




    # Prepare DataFrame for Concurrency
    # and layer on top of Gantt Chart

    jobdct = Dict( x.jobdef_name => (st=x.startedTimeStamp, et=x.endedTimeStamp) for x in eachrow(wlmmetrics))

    workstart = minimum(wlmmetrics.startedTimeStamp)
    workend   = maximum(wlmmetrics.endedTimeStamp)
    timescale = workstart:Second(1):workend

    jobbit = Dict()

    for j in keys(jobdct)
        startTime, endTime = jobdct[j]
        startidx = map(x -> x==startTime, timescale) |> findfirst
        endidx = map(x -> x==endTime, timescale) |> findfirst
        bitarr = zeros(Int, length(timescale))
        bitarr[startidx:endidx] .= 1
        jobbit[j] = bitarr
    end

    hmapdata = sum((values(jobbit) |> collect))
    ndf = DataFrame(dt=timescale, njobs=hmapdata)

    ct = Config( type = "scatter", 
                 fill = "tozeroy", 
                 mode = "lines",
                 x = ndf.dt, 
                 y = ndf.njobs,
                 yaxis = "y2", 
                 xaxis = "x", # used shared x-axis
                 name = "concurrency",
                 showlegend = false,
                 fillcolor = "rgba(14, 14, 14, 0.5)",
                 line = Config(color="rgba(184, 53, 58, 0.5)", width=2)
                )
    push!(traces, ct)





    layout = Config(
                    # yaxis2 = Config(
                    #     title = "Efficiency",
                    #     overlaying = "y",
                    #     side = "right",
                    #     gridcolor = "#FFFFFF",
                    #     autorange = true
                    # ),
                    height = length(traces) * 24,
                    title = "Execution Order & Concurrency Chart",
                    hovermode = "closest",
                    autosize = true,
                    margin = Config( l=150, r=40, pad=0 ),
                    

                    xaxis = Config(
                                range=(xmin, xmax),
                                domain = [0, 1]    
                    ),
                    yaxis = Config(
                                tickmode = "array", 
                                tickvals = 1:size(df)[1], 
                                ticktext = df.name,
                                domain = [0.25, 1]
                    ),

                    xaxis2 = Config(
                                domain = [0, 1]
                    ),
                    yaxis2 = Config(
                                domain = [0, 0.15]
                    ),

                    grid = Config(
                                rows = 2, 
                                columns = 1, 
                                #pattern = "independent",
                    )
            )

        config = Config( 
                showLink=false, 
                staticPlot=false, 
                editable=true, 
                displayModeBar="hover", 
                # displayModeBar=true,
                displaylogo=false,
                toImageButtonOptions = Config(format="svg"),
                responsive=true
                # modeBarButtonsToAdd=[ "drawline","drawopenpath","drawclosedpath",
                #                       "drawcircle","drawrect","eraseshape"]
        )    

    plt = Plot(traces, layout, config)
    return plt
end