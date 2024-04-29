#!/bin/bash
#=
exec julia --project=@. -O0 --color=yes --startup-file=no "${BASH_SOURCE[0]}" "$@"
=#

using Dates
using TOML
using JSON3
using ArgParse
using DataFrames, TidierData
using ViyaBatchJobs
using DataStructures
using ProgressMeter
using Arrow
using CSV
using PrettyTables

using Term
import Term: Tree

println("modules loaded: $(now())")

struct Arguments
    workdir::AbstractString
    workload::AbstractString
    insecure::Bool
    debug::Bool
    dryrun::Bool
    interval::Int64
    viyacli::AbstractString
end


"""Parse commandline arguments"""
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--debug"
            help = "increase verbosity (debugging)"
            action = :store_true
	    "--interval"
	        help = "seconds beween checks to see if the jobs are finished running"
	        arg_type = Int64
	        default = 60
        "--workdir"
            help = """directory to use for saving output, default is to use
                    the location of workload configuration file"""
            arg_type = String
            default = nothing
        "--insecure"
            help = """Allows connections to TLS sites without validating the server certificates"""
            action = :store_true
        "--dryrun"
            help = """Only print the sas-viya submit commands on the terminal"""
            action = :store_true
        "--viyacli"
            help = """Path to sas-viya cli. Default: is to search the system path"""
            arg_type = String
            default = searchpath("sas-viya")
        "workload"
            help = "Path to workload (TOML)"
            required = true
    end

    args = parse_args(s)

    # Check if the workload file exists
    !(isfile(args["workload"])) && @error "can't open workload file $(args["workload"])"

    # Check if the workload location is absolute path if not then convert it to absolute path
    args["workload"] = isabspath(args["workload"]) ? args["workload"] : abspath(args["workload"])

    # if workdir not specified then use basedir of workload config
    if args["workdir"] === nothing
        args["workdir"] = dirname(args["workload"])
    else # convert the specified path to absolute path
        isdir(abspath(args["workdir"])) || error("Cannot access $(args["workdir"])")
        args["workdir"] = abspath(args["workdir"])
    end

    Arguments(  
                args["workdir"],
                args["workload"], 
                args["insecure"],
                args["debug"],
                args["dryrun"],
                args["interval"],
                args["viyacli"]
               )
end


function wait_for_completion(bin::ViyaCLI, jobids::Vector; interval=90)
    res = Dict{String, Any}(i=>"" for i in jobids)
    total_jobs = length(keys(res))

    running_jobs = collect( filter(x->res[x]=="", keys(res)) )

    # configure progress bar
    glyphs = BarGlyphs("[=> ]") 
    p = Progress(total_jobs, barglyphs=glyphs, barlen=50)

    retry_count = 0
    max_retry = 3
    while length(running_jobs) > 0
        sleep(interval)
    
        try
            global jstatus = cli_jobstatus.(Ref(bin), running_jobs)
        catch e
            @warn "Error getting job status - Waiting (60s) & Retrying ($retry_count / $max_retry)"
            sleep(60)
            retry_count = retry_count + 1
            if retry_count <= max_retry
                continue # try again
            else
                @warn "Cannot query job status"
                throw(e)
            end
        end

        for js in jstatus
            res[js.id] = isfinished(js) ? js : ""
        end
        running_jobs = collect( filter(x->res[x]=="", keys(res)) )
        
        # println("Waiting on $(length(running_jobs)) / $(total_jobs) jobs to finish")
        numfinished = total_jobs - length(running_jobs)
        ProgressMeter.update!(p, numfinished; showvalues = [(:finished,numfinished), (:total,total_jobs)])
    end
    res
end



function main(args)
    # parse conf file 
    @time "parsing $(args.workload)" tml = TOML.parsefile(args.workload)
    w = Workload(tml) # instantiate the workload struct

    bin = ViyaCLI(args.viyacli, args.insecure, :fulljson, "Default")
    @debug "using sas-viya cli" bin


    # Create directories to store output
    tsstr = replace(Dates.now() |> string, ":"=>"", "."=>"") # timestamp based string "2023-03-09T231910698"
    dirprefix = (basename(args.workload) |> splitext)[1] # sampel.toml generates "sample"
    outdir = joinpath(args.workdir, "$(dirprefix)-$(tsstr)")
    @info "Outputs from this execution stored in $(outdir)"
    mkdir(outdir)
    

    # Make a copy of workload (toml) to outdir
    outfile = joinpath(outdir, "workload.toml")
    @info "Copying workload configuration to $outfile"
    cp(args.workload, outfile, force=true)


    plan = execution_plan(w) # Build an Execution Plan
    printstyled("\nExecution Plan:\n", bold=true, color=:green, underline=true, reverse=true)
    println(Tree(plan; print_node_function=print_node))


    # If --dryrun is specified just print the CLI equivalent commands
    # and quit
    if args.dryrun == true
        for stage in keys(plan)
            @info "$(now()): CLI commands for stage => $(stage)"
            job_definitions = jobdefinition.(Ref(w), plan[stage]) # get JodBefinitions from jobnames
            cmds = cmd_submitpgm.(Ref(bin), job_definitions) # get the cmd object for each job_definition
            for c in cmds
                println(string(c))
            end
        end
        println("Done printing submit commands")
        exit(0)
    end

    # Batch Submit Jobs one Stage at a time
    # `joboutput` aggregates the `JobStatus` from 
    # all completed jobs
    for stage in keys(plan)
        @info "$(now()): submitting jobs for stage $(stage)"

        job_definitions = jobdefinition.(Ref(w), plan[stage]) # get JodBefinitions from jobnames
        res = batch_submit(bin, job_definitions) # res =  vector of NamedTuple{(:fileset, :jobid, :wlmid, :jobname, :stage)
        @info "$(now()): finished submitting jobs $(stage)"

        jobids = getindex.(res, :jobid)
        jstats = wait_for_completion(bin, jobids)
        # Fetch JobStatus and write them as individual json file
        @info "$(now()) - writing individual json results"
        for (jobid, js) in jstats
            status_file = joinpath(outdir, "$(js.fileSetId)-$(js.name).json")
            open(status_file, "w") do f
                JSON3.pretty(f, JSON3.write(todict(js)))
            end
        end
        @info "$(now()): Fetching Results"
        cli_getresults.(Ref(bin), jobids, outdir=outdir)
        @info "$(now()): finished fetching results"
    end


    @info "$(now()) - generating summary"
    # Compile Results to a Table (Arrow)
    tblfile = joinpath(outdir, "metrics.arrow")
    @info "Writing metrics to $(tblfile)"
    wlmDF = build_resultsDF(w, outdir)
    Arrow.write(tblfile, wlmDF)

    # Compile Results from FULLSTIMER SAS Log, Hydrated with SASWLM Metrics
    stimer_file = joinpath(outdir, "fullstimer.csv")
    @info "Writing combined metrics to $(stimer_file)"
    try
        global fullstimerDF = build_sastimerDF(w, outdir)
    catch e
        @warn "Unable to create fullstimer output due to errors. Skipping"
    end
    CSV.write(stimer_file, fullstimerDF)

    wdf = @chain wlmDF begin
        @mutate( 
            wlmruntime          = Second(DateTime(endedTimeStamp) - DateTime(startedTimeStamp)), 
            wlmwaittime         = Second(DateTime(startedTimeStamp) - DateTime(submittedTimeStamp)),      
        )
        @mutate( 
            wlmruntime  = getfield(wlmruntime, :value),
            wlmwaittime = getfield(wlmwaittime, :value)
        )
        @select( 
            JobName      = name, 
            Stage        = stage, 
            RC           = returnCode,
            State        = state, 
            Runtime      = wlmruntime, 
            Waittime     = wlmwaittime,
            fileSetId,
            processId            
        )
        @arrange(Stage, JobName)
    end
    pretty_table(wdf)

    # print WLM Summary
    summaryDF = @chain wlmDF begin
        @select(stage, startedTimeStamp, endedTimeStamp, totalRunTime, totalWaitTime)
        @group_by(stage)
        @summarize(
            WallClockTime = Second(maximum(endedTimeStamp) - minimum(startedTimeStamp)),
            WLMTotalRunTime = sum(totalRunTime),
            WLMTotalWaitTime = sum(totalWaitTime)
        )
    end 
    pretty_table(summaryDF)


    printstyled("\nJobs with Warnings & Error:\n", bold=true, color=:green, underline=true, reverse=true)
    df = summarize_results_from_dir(outdir)
    df = @chain df begin
        @filter(status=="failed")
    end
    pretty_table(df)

end




## Main Entrypoint
@time "Processing Args" args = parse_commandline()
    
# Enable debug if enabled
ENV["JULIA_DEBUG"] = (args.debug == true) ? "all" : ""
@debug "arguments passed" args

main(args)


