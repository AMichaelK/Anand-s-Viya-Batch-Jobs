

function cli_submitpgm(bin::ViyaCLI, jobdef::WLMJobDefinition)
    cmd = cmd_submitpgm(bin, jobdef)
    r = execute_cmd(cmd)

    if length(r.err) != 0
        @warn "cli_submitpgm: unexpected output in stderr" r.err
    end

    out = parse_submitpgm(r.out)
    job_name = (jobname=jobdef.name, stage=jobdef.stage)

    res = merge(out, job_name)
    res
end




"""Returns `JobStatus` of a running WLM Job"""
function cli_jobstatus(bin::ViyaCLI, jobid::AbstractString; maxretry=3)
    cmd = cmd_jobstatus(bin, jobid)
    @debug "cli_jobstatus: executing $(cmd)"
    r = execute_cmd(cmd)
    @debug "cli_jobstatus:\n OUT: $(r.out)\n ERR:$(r.err)"

    if length(r.err) != 0
        @warn "cli_jobstatus: unexpected output in stderr" r.err
    end

    payload = JSON3.read(r.out)["items"] 
    @debug "cli_jobstatus: processed $(payload)"
    payload

    # Make sure there is only one entry in the response
    if length(payload) == 0
        @warn "jobstatus(workload, $(jobid)) - returned with zero entries"
        return nothing
    else
        jstat = parse_jobstatus(Dict(payload[1]))
        return jstat
    end
end




""" getresults(w, jobid; outdir) """
function cli_getresults(bin::ViyaCLI, jobid::AbstractString; outdir=".")
    cmd = cmd_getresults(bin, jobid, outdir=outdir)
    r = execute_cmd(cmd)

    @debug "getresults: $(r.out), $(r.err)"
    if r.ret.exitcode !== 0
        return ErrorException("unable to download results for job: $(jobid) (rc:$(rc))")
    else
        return nothing
    end
end