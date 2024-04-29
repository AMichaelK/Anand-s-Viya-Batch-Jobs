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
                args["interval"],
                args["viyacli"]
               )
end




function main(args)
    # parse conf file 
    @time "parsing $(args.workload)" tml = TOML.parsefile(args.workload)
    w = Workload(tml) # instantiate the workload struct

    bin = ViyaCLI(args.viyacli, args.insecure, :fulljson, "Default")
    @debug "using sas-viya cli" bin

    plan = execution_plan(w) # Build an Execution Plan
    printstyled("\nExecution Plan:\n", bold=true, color=:green, underline=true, reverse=true)
    println(Tree(plan; print_node_function=print_node))


    # Batch Submit Jobs one Stage at a time
    # `joboutput` aggregates the `JobStatus` from 
    # all completed jobs
    for stage in keys(plan)
        @info "$(now()): submitting jobs for stage $(stage)"

        job_definitions = jobdefinition.(Ref(w), plan[stage]) # get JodBefinitions from jobnames
        cmds = cmd_submitpgm.(Ref(bin), job_definitions)
        for c in cmds
            println(string(c))
        end
    end
end



## Main Entrypoint
@time "Processing Args" args = parse_commandline()
    
# Enable debug if enabled
ENV["JULIA_DEBUG"] = (args.debug == true) ? "all" : ""
@debug "arguments passed" args

main(args)

