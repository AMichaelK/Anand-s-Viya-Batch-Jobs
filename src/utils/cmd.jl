
"""
    execute_cmd(cmd)

Execute Cmd object and return a NamedTuple containing (return, stderr, stdout).
"""
function execute_cmd(cmd::Cmd)
    outfd = IOBuffer()
    errfd = IOBuffer()

    @debug "Executing $(cmd)"
    r = run(pipeline(ignorestatus(cmd), stdout=outfd, stderr=errfd))
    @debug "Processing Output"
    out = read(seekstart(outfd), String)
    err = read(seekstart(errfd), String)

    if r.exitcode == 64
        @warn cmd "return code: $(r.exitcode)"
        @info "Check if 'batch' plugin is installed"
        # sas-viya plugins install --repo SAS batch
        throw(ErrorException(chomp(out * err)))
    
    elseif r.exitcode == 1
        @warn cmd "return code: $(r.exitcode)"
        throw(ErrorException(chomp(out * err)))

    elseif r.exitcode == 0
        return (ret=r, out=out, err=err)

    else
	    throw(ErrorException("Unknown Error $r"))
    end
end


function cmd_submitpgm(bin::ViyaCLI, jobdef::WLMJobDefinition)
    cmd = [bin.executable]
    (bin.insecure == true) && push!(cmd, "-k")
    append!(cmd, ["--verbose"])
    append!(cmd, ["--output", string(bin.output)])
    append!(cmd, ["--profile", bin.profile])
    append!(cmd, ["batch", "jobs"])

    
    append!(cmd, ["submit-pgm"])

    # if jobdef.context == "" then use "default"
    context = jobdef.context == "" ? "default" : jobdef.context
    append!(cmd, ["--context", context])
    
    append!(cmd, ["--job-name", jobdef.name])

    # if jobdef.queue == "" then use "default"
    queue = jobdef.queue == "" ? "default" : jobdef.queue
    append!(cmd, ["--queue-name", queue])

    append!(cmd, ["--pgm-path", jobdef.code.source])
    
    # sasoption = join(jobdef.code.sasoption, " ")
    # append!(cmd, ["--sas-option", "\'$sasoption\'"])
    for f in jobdef.code.sasoption
        append!(cmd, ["--sas-option", f])
    end

    for f in jobdef.jobfile
        append!(cmd, ["--job-file", f])
    end

    return Cmd(cmd)
end



""" Generate CLI command for WLM (submit-pgm) """
function cmd_jobstatus(bin::ViyaCLI, jobid::AbstractString)
    cmd = [bin.executable]
    (bin.insecure == true) && push!(cmd, "-k")
    append!(cmd, ["--output", string(bin.output)])
    append!(cmd, ["--profile", bin.profile])
    append!(cmd, ["batch", "jobs", "list"])    
    
    append!(cmd, ["--id", jobid])
 
    return Cmd(cmd)
end



"""Generate command line for WLM (sas-viya batch jobs --get-results)"""
function cmd_getresults(bin::ViyaCLI, jobid::AbstractString; outdir=".")
    cmd = [bin.executable]
    (bin.insecure == true) && push!(cmd, "-k")
    append!(cmd, ["--output", string(bin.output)])
    append!(cmd, ["--profile", bin.profile])
    append!(cmd, ["batch", "jobs", "get-results"]) 

    append!(cmd, ["--job-id", jobid])
    append!(cmd, ["--results-dir", outdir])

    return Cmd(cmd)
end
