module ViyaBatchJobs

using Accessors, 
        Dates, 
        JSON3, 
        DataStructures,
        DataFrames, 
        #Tidier,
        TidierData, 
        ProgressMeter, 
        Arrow, 
        TOML, 
        # VegaLite,
        Markdown,
        CSV,
        PlotlyLight,
        EasyConfig,
        Colors


include("structs/viyacli.jl")
include("structs/batchcode.jl")
include("structs/jobdefinition.jl")
include("structs/jobprofile.jl")
include("structs/jobstatus.jl")
include("structs/jobresult.jl")
include("structs/workload.jl")
include("structs/sastimer.jl")
include("utils.jl")
include("utils/cmd.jl")
include("utils/cli.jl")
include("plots.jl")

export 
    AbstractBatchCode,
    SASCode,
    AbstractJobDefinition,
    WLMJobDefinition,
    ViyaCLI,
    JobStatus,
    parse_jobstatus,
    JobProfile,
    parse_submitpgm,
    execute_cmd,
    cli_submitpgm,
    cli_jobstatus,
    cli_getresults,
    process_jobdefinition,
    apply_jobprofile,
    parse_timestamp,
    cmd_submitpgm,
    cmd_jobstatus,
    cmd_getresults,
    JobResult,
    Workload,
    profilenames,
    jobprofile,
    jobdefinition,
    jobnames,
    stagenames,
    searchpath,
    execution_plan,
    todict,
    print_node,
    batch_submit,
    isfinished,
    exitcode,
    runtime,
    starttime,
    endtime,
    waitingtime,
    build_resultsDF,
    SASTimer,
    parse_saslog,
    build_sastimerDF,
    _is_saslogfile_valid,
    summarize_results_from_dir,
    # plot_job_variance, # Vega
    # plot_gantt_chart, # Vega
    # plot_concurrency, # Vega
    # plot_proc_distribution, # Vega
    plot_proc_frequency,
    # plot_error_matrix, # Vega
    # plot_cpu_real_time, # Vega
    plot_io_efficiency,
    runtime_summary,
    plot_runtime_efficiency,
    plot_wlm_gantt_chart,
    summary_table


end # module ViyaBatchJobs
