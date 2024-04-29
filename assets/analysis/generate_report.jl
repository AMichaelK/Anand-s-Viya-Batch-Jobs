#!/bin/bash
#=
exec julia --project=@. -O0 --color=yes --startup-file=no "${BASH_SOURCE[0]}" "$@"
=#
#using Pkg; Pkg.activate(@__DIR__)

@info "loading packages"
using Pkg; Pkg.activate("."); Pkg.instantiate()


using CSV
using Dates
using JSON3
using Arrow
using Random
using ArgParse
using Markdown
using DataFrames, TidierData
using PrettyTables
using ViyaBatchJobs
using EasyConfig
using PlotlyLight

import Cobweb: h, Page, Javascript, save
# import Vega: savespec
# import VegaLite: @vlplot, VLSpec

@info "$(now()) modules loaded"




""" 
#######################################################################

**Helper Functions**: Functions used internally by rendering functions

#######################################################################
""" 

"""Convert VLSpec to JSON Dict"""
# function vl2json(obj::VLSpec)
#     io = IOBuffer()
#     savespec(io, obj; include_data=true)
#     seekstart(io)
#     str = read(io, String)
#     JSON3.read(str)
# end





"""
#######################################################################

**Render Objects**: Functions to handle different Julia objects and 
return rendered `Cobweb.Node`

#######################################################################
"""


function render_dict(o::Dict; show_level=1)
    oid = randstring('a':'z', 6) # unique id 
    ostr = JSON3.write(o) # Dict to JSON String

    jsstr = """document.getElementById("$oid").appendChild(
                 renderjson.set_show_to_level($show_level)($ostr)
        );"""
    
    h.div(
        h.div(id=oid),
        h.script(type="text/javascript", 
                 src="https://cdn.jsdelivr.net/npm/renderjson@1.4.0/renderjson.min.js"),
        Javascript(jsstr)
        ; class="container"
    )
end




# function render_vegalite(o::VLSpec)
#     oid = randstring('a':'z', 6) # unique id
#     jsn = vl2json(o)

#     jsstr = """var pltSpec = $jsn
#                 vegaEmbed($oid, pltSpec);"""

#     h.div(
#         h.div(id=oid),
#         Javascript(jsstr),
#         class="container"
#     )
# end



#render_plotlylite(o::Plot) = h.div(html(o); style="height: 400px")
render_plotlylite(o::Plot) = h.div(html(o); class="container")



function render_dataframe(o::DataFrame; 
                                alignment=:l,
                                table_class="table display compact nowrap table-striped table-hover table-sm",
                                table_style=Dict("width" => "90%;"), datatable=false
                                )


    ostr = pretty_table( String, o; backend=Val(:html), alignment=alignment,
                            table_class=table_class, table_style=table_style,
                            show_subheader = false )

    if datatable == true
        oid = randstring('a':'z', 6) # unique id
        iod_hash = "#"*oid
        
        ostr = replace(ostr, "<table class"=>"<table id = '$oid' class")
        jsstr = """\$(document).ready(function () {
            \$("#$(oid)").DataTable({
                scrollX: true,
            });
        });"""
        return h.div(
            Javascript(jsstr),
            ostr,
            class="container"
        )
    else
        return h.div(ostr; class="container")
    end
end





function render_list(o::Vector)
    h.div(
        h.ul(
            [h.li(i) for i in o]
        );
        class="container"
    )
end






"""
#######################################################################

**Render Report**: 

#######################################################################
"""


function build_nodes(rootdir::AbstractString)

    html_nodes = []
    wlmmetrics = Arrow.Table(joinpath(rootdir, "metrics.arrow")) |> DataFrame
    stimer_metrics = CSV.read(joinpath(rootdir, "fullstimer.csv"), DataFrame)


    # ---------------------------------------------------------- #
    # runtime summary from WLM
    # ---------------------------------------------------------- #
    section_text = h.div(
        h.hr(class="border border-dark border-2 opacity-50"),
        h.h2("Runtime Summary"),
        html(md"""
        Total runtime summary by stage as reported by FULLSTIMER log entries and Workload Manager
        ```text
        - stimer_sys: is sum of `sys_time` of all jobs in the stage reported by FULLSTIMER
        - stimer_user: is sum of `user_time` of all jobs in the stage reported by FULLSTIMER
        - stimer_real: is sum of `real_time` of all jobs in the stage reported by FULLSTIMER
        - wlm_real: is the sum of runtime of all individual jobs in a stage reported by WLM
        - wlm_wait: is the sum of time spent by all jobs waiting to get scheduled by WLM
        - wlm_clock: is the total clock time from the beginning of the stage to end
        - stimer_nrec & wlm_nrec should be equal, representing the completed jobs observed by WLM and Compute
        ```
        """);
        class="container bg-light lh-1 border"
    )
    push!(html_nodes, section_text)

    summaryDF = runtime_summary(wlmmetrics, stimer_metrics)
    push!(html_nodes, render_dataframe(summaryDF))


    # ---------------------------------------------------------- #
    # summary of failed jobs
    # ---------------------------------------------------------- #
    section_text = h.div(
        h.hr(class="border border-dark border-2 opacity-50"),
        h.h2("Failed Jobs"),
        html(md"""
        The table below would be empty when all jobs completed as expected. Jobs with "failed" status 
        and "returnCode" == 1 are SAS jobs that completed but with "WARNING" messages in the log. These
        jobs are not really failed jobs and should not be treated as such. 
        """
        );
        class="container bg-light lh-1 border"
    )
    push!(html_nodes, section_text)

    failedDF = summarize_results_from_dir(rootdir)
    failedDF = @chain failedDF begin
        @filter(status=="failed")
    end
    push!(html_nodes, render_dataframe(failedDF))

    # ---------------------------------------------------------- #
    # Visualizing Execution 
    # ---------------------------------------------------------- #
    section_text = h.div(
        h.hr(class="border border-dark border-2 opacity-50"),
        h.h2("Visualizing Execution"),
        html(md"""
        This chart visualizes the execution of all the jobs in the workload over time. 
        It could be helpful in understanding when each job was executed and how long 
        it took with respect to the other jobs.
        """); 
        class="container bg-light lh-1 border"
    )
    push!(html_nodes, section_text)

    # plt_gantt = plot_gantt_chart(wlmmetrics, width=740)
    # push!(html_nodes, render_vegalite(plt_gantt))
    plt_gantt = plot_wlm_gantt_chart(wlmmetrics)
    push!(html_nodes, render_plotlylite(plt_gantt))
    

    # ---------------------------------------------------------- #
    # Concurrency
    # ---------------------------------------------------------- #
    # section_text = h.div(
    #     h.hr(class="border border-dark border-2 opacity-50"),
    #     h.h2("Job Concurrency"),
    #     html(md"""
    #     The visualization shows the concurrency at any given point in time when the 
    #     workload was being executed. It can come handy to visually see how heavily the 
    #     system was being taxed during the exection of the workload.
    #     """); 
    #     class="container bg-light lh-1 border"
    # )
    # push!(html_nodes, section_text)
    
    # plt_concurrency = plot_concurrency(wlmmetrics, width=740)    
    # push!(html_nodes, render_vegalite(plt_concurrency))


    # ---------------------------------------------------------- #
    # Job Variance
    # ---------------------------------------------------------- #
    # section_text = h.div(
    #     h.hr(class="border border-dark border-2 opacity-50"),
    #     h.h2("Job Variance"),
    #     html(md"""
    #     In this visualization the sas program is extracted from job definition and their 
    #     runtime is plotted grouped together. The plot can come handy to see the variance 
    #     of runtime of the same code.
        
    #     This could be due to different reasons like, different parameters (MEMSIZE, 
    #     SORTSIZE et. al.) used in the job definition or due to contention due to other 
    #     jobs it may be competing with for resources.
    #     """); 
    #     class="container bg-light lh-1 border"
    # )
    # push!(html_nodes, section_text)

    # plt_variance = plot_job_variance(wlmmetrics, width=740)
    # push!(html_nodes, render_vegalite(plt_variance))


    # ---------------------------------------------------------- #
    # PROC Distribution
    # ---------------------------------------------------------- #
    section_text = h.div(
        h.hr(class="border border-dark border-2 opacity-50"),
        h.h2("PROC Distribution"),
        html(md"""
        This visualization shows the distribution of different SAS PROCs
        used in the workload, how many time was each PROC called and the time
        used by these PROCs.
    
        - Parallel Ratio is `(usr_time + sys_time) / real_time`
        """); 
        class="container bg-light lh-1 border"
    )
    push!(html_nodes, section_text)

    #plt_procdistr = plot_proc_distribution(stimer_metrics, width=640)
    plt_procdistr = plot_proc_frequency(stimer_metrics)
    push!(html_nodes, render_plotlylite(plt_procdistr))  


    # ---------------------------------------------------------- #
    # CPU Time vs Real Time
    # ---------------------------------------------------------- #
    # section_text = h.div(
    #     h.hr(class="border border-dark border-2 opacity-50"),
    #     h.h2("CPU & Real Time"),
    #     html(md"""
    #     Plots the `system_cpu_time` & `user_cpu_time` against `real_time` for
    #     each job in the workload. This can be helpful in identifying where the 
    #     time was spent during execution. 
    #     """); 
    #     class="container bg-light lh-1 border"
    # )
    # push!(html_nodes, section_text)

    # plt_cpureal = plot_cpu_real_time(stimer_metrics, width=640)
    # push!(html_nodes, render_vegalite(plt_cpureal)) 


    # ---------------------------------------------------------- #
    # IO Efficiency
    # ---------------------------------------------------------- #
    # section_text = h.div(
    #     h.hr(class="border border-dark border-2 opacity-50"),
    #     h.h2("IO Efficiency"),
    #     html(md"""
    #     Plot `(sys_time + usr_time) / real_time` ratio for every test. The tests
    #     where the ratio is less than 0.7 is considered tests starved for IO and points
    #     to snemic storage subsystem.  
    #     """); 
    #     class="container bg-light lh-1 border"
    # )
    # push!(html_nodes, section_text)

    # plt = plot_io_efficiency(stimer_metrics)
    # push!(html_nodes, render_plotlylite(plt))


    # ---------------------------------------------------------- #
    # Combined Runtime Efficiency
    # ---------------------------------------------------------- #
    section_text = h.div(
        h.hr(class="border border-dark border-2 opacity-50"),
        h.h2("Runtime Efficiency"),
        html(md"""
        Plot `(sys_time + usr_time) / real_time` ratio for every test. The tests
        where the ratio is less than 0.7 is considered tests starved for IO and points
        to snemic storage subsystem.  
        """); 
        class="container bg-light lh-1 border"
    )
    push!(html_nodes, section_text)

    plt = plot_runtime_efficiency(stimer_metrics)
    push!(html_nodes, render_plotlylite(plt))


    # ---------------------------------------------------------- #
    # Summary All Jobs
    # ---------------------------------------------------------- #
    section_text = h.div(
        h.hr(class="border border-dark border-2 opacity-50"),
        h.h2("Per Job Summary"),
        html(md"""
        """); 
        class="container bg-light lh-1 border"
    )
    push!(html_nodes, section_text)

    jobsummaryDF = summary_table(wlmmetrics)
    push!(html_nodes, render_dataframe(jobsummaryDF, datatable=true))

    return html_nodes
end


function render_report(nodes::Vector; title="Report Title")
    page = 
        h.html(
            h.head(
                h.title(title),
                h.meta(charset="utf-8"),
                h.meta(name="viewport", content="width=device-width, initial-scale=1"),
                h.link(crossorigin="anonymous", 
                        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/css/bootstrap.min.css", 
                        rel="stylesheet", 
                        integrity="sha384-KK94CHFLLe+nY2dmCWGMq91rCGa5gtU4mk92HdvYe+M/SXH301p5ILy+dN9+nJOZ"),
                h.link(href="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism.min.css", rel="stylesheet"),
                h.script(src="https://cdn.jsdelivr.net/npm/vega@5"),
                h.script(src="https://cdn.jsdelivr.net/npm/vega-lite@5"),
                h.script(src="https://cdn.jsdelivr.net/npm/vega-embed@6"),
                h.script(crossorigin="anonymous", src="https://code.jquery.com/jquery-3.7.0.min.js", 
                        integrity="sha256-2Pmvv0kuTBOenSvLm6bvfBSSHrUJ+3A7x6P5Ebd07/g="),
                h.script(src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"),
                h.link(href="https://cdn.datatables.net/1.13.4/css/jquery.dataTables.min.css", rel="stylesheet")
            ),
            h.body(
                [n for n in nodes]
            )
        )
    
    page
end








"""Parse commandline arguments"""
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--debug"
            help = "increase verbosity (debugging)"
            action = :store_true
        "outputdir"
            help = "Path to output directory"
            required = true
    end

    parse_args(s)
end


function main()
    args = parse_commandline()
    rootdir = args["outputdir"]
    outputfile = joinpath(rootdir, "report.html")
    nodes = build_nodes(rootdir)
    report = render_report(nodes; title=basename(rootdir))
    page = Page(report)
    save(page, outputfile)

    @info "$(now()) file $(outputfile) written"
end

main()

