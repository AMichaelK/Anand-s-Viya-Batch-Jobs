


"""construct `ViyaCLI` object using inputs from `Workload` object"""
ViyaCLI(w::Workload) = ViyaCLI(w.viyacli_path, w.viyacli_insecure, :fulljson, w.viyacli_profile)




"""Return a vector of all job names defined in Workload"""
jobnames(w::Workload) = getfield.(w.job, :name)

"""Returns all jobdefinition names for a particular stage"""
function jobnames(w::Workload, stagename::AbstractString)
    res = []
    for j in jobnames(w)
        jdef = jobdefinition(w, j)
        if jdef.stage == stagename
            push!(res, jdef.name)
        end
    end
    res 
end





"""
    jobdefinition(w, name, [apply_profile])

Return JobDefinition: 'name' from Workload. If apply_profile is false
then the settings from the profile is not applied to the jobdefinition.
"""
function jobdefinition(w::Workload, name::AbstractString; apply_profile::Bool=true, inject_fullstimer::Bool=true)
    # find the index in vector `job` that contains jobdef:name
    jidx = findfirst(x -> name == x, jobnames(w))
    if jidx === nothing
        @error "jobdefinition(w, $(name)): job with name $(name) not found. defined => $(jobnames(w))"
    end

    jdef = w.job[jidx]
    if apply_profile == true
        profile_name = jdef.profile
        jp = jobprofile(w, profile_name)
        jdef=apply_jobprofile(jdef, jp)
    end

    # inject "-FULLSTIMER" option to sasoption if it does not exists
    if inject_fullstimer == true
        if ! any(occursin.(uppercase.(jdef.code.sasoption), "-FULLSTIMER"))
            opts = jdef.code.sasoption
            push!(opts, "-FULLSTIMER")
            jdef = @set jdef.code.sasoption = opts
        end
    end

    return jdef
end


profilenames(w::Workload) = getfield.(w.profile, :name)

function jobprofile(w::Workload, name::AbstractString)
    # find the index in vector `profile` that contains profile:name
    pidx = findfirst(x -> name == x, profilenames(w))
    if pidx === nothing
        @error "jobprofile(w, $(name)): profile with name $(name) not found. defined => $(profilenames(w))"
    end
    return w.profile[pidx]
end


stagenames(w) = w.stages






"""
    searchpath(prog::AbstractString)

Search system path for executable `prog::AbstractString`. Return nothing if not found.
"""
function searchpath(prog::AbstractString)
    syspath = get(ENV, "PATH", nothing)
    (syspath === nothing) && return nothing

    # tokenize path on `:`
    pathlist = split(syspath, ":")

    for p in pathlist
        progpath = joinpath(p, prog)
        if isfile(progpath) && (uperm(progpath) & 0x01 > 0)
            return progpath
        end
    end
    return ""
end





"""
    parse_submitpgm(instr::AbstractString)

Scans the output from the `sas-cli batch submit job...` command and 
extracts `fileset`, `jobid` and `wlmid`. Returns a `NamedTuple`

## Example:

```julia

instr = \"\"\"
>>> The file set "JOB_20230121_201001_960_1" was created.
>>>   Uploading "iris_cluster.sas".
>>> The job was submitted. ID: "a6bac006-cbe0-4d20-a2bd-789366f79794"  Workload Orchestrator job ID: "4500"
\"\"\"

parse_wlm_submit(instr)

## Output
(JOB_20230121_201001_960_1, a6bac006-cbe0-4d20-a2bd-789366f79794, 4500)
```

Update Note:

- 02-2023 While testing code against different Viya environment we encountered
another possible output from `sas-viya batch job submit-pgm` wihout Workload Orchestrator job ID

```
>>> The file set "JOB_20230212_073216_060_1" was created.
>>>   Uploading "rank1.sas".
>>>   Uploading "autoexec.sas".
>>> The job "8741d613-3e54-4fc7-a6d9-35b557f4fdbf" was submitted.
```

"""
function parse_submitpgm(instr)
    
    rex_cliout = r"^>>>.*" # Lines starting with >>> are the output from batch submit
    
    # >>> The file set "JOB_20230121_201001_960_1" was created.
    rex_fileset = r"^>>> The file set \"(\w+)\".* "
    
    # >>> The job was submitted. ID: "a6bac006-cbe0-4d20-a2bd-789366f79794"  Workload Orchestrator job ID: "4500"
    rex_wlmid = r"^>+ The job was submitted\. ID: \"([^\"]*)\"  Workload Orchestrator job ID: \"([0-9]+)\"$"
    rex_wlmid2 = r"""^>>> The job "([^"]*)" was submitted\.$"""

    var_fileset = nothing
    var_jobid = nothing
    var_wlmid = nothing
    
    for l in readlines(IOBuffer(instr)) # for each output line
        
        if occursin(rex_cliout, l) # analyze if line starts with >>>
            
            if occursin(rex_fileset, l)
                m = match(rex_fileset, l)
                var_fileset = m[1]
            end
            
            if occursin(rex_wlmid, l)
                m = match(rex_wlmid, l)
                var_jobid = m[1]
                var_wlmid = m[2]
            end

            # to handle scenario explained in notes above
            # TODO: Make this fix cleaner
            if occursin(rex_wlmid2, l)
                m = match(rex_wlmid2, l)
                var_jobid = m[1]
                var_wlmid = 0 # Since no ID is provided fill it with 0
            end 

        end
    end
    
    if (var_fileset === nothing) || (var_jobid === nothing) || (var_wlmid === nothing)
        error("parse_wlm_submit: can't parse sas-viya output for input\n $(instr)")
    end

    (fileset=var_fileset, jobid=var_jobid, wlmid=var_wlmid)
end





"""
    parse_timestamp(str)

Parse string timestamp to DateTime object. The function tries to 
match regular expression to identify the following formats

- `2023-01-23T17:43:32.356196Z`
- `2023-01-23T17:43:28Z`

For the format with nanoseconds (six digits after the seconds) the last
three digits are discarded and the DateTime object is at Millisecond
resolution. 

If the input is not one of the listed formats the function falls back
to Julia's `tryparse()` function which would either return a DateTime
object if successful or nothing in the event of failure
"""
function parse_timestamp(str::AbstractString)

    # rex for 6 digit nanosecond timestamp "2023-01-23T17:43:32.356196Z"
    nsrex = r"^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3})[0-9]{3}Z$"
    m = match(nsrex, str)
    if m !== nothing
        return tryparse(DateTime, m[1])
    end

    # Rex for DateTime with seconds "2023-01-23T17:43:28Z"
    dt1rex = r"^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}).*Z$"
    m = match(dt1rex, str)
    if m !== nothing
        return tryparse(DateTime, m[1])
    end

    @warn "parse_timestamp('$(str)'): No regex matches; falling back to tryparse"
    return tryparse(DateTime, str)
end





"""
    execution_plan(w, [sorted, filter_disabled])

Returns an OrderedDict {stage_name, [job_names]} containing the order 
in which the jobs are intended to be executed. Jobs are by default sorted
by name and stage_names are in order as specified in the `Workload` 
"""
function execution_plan(w::Workload; sorted=true, filter_disabled=true)
    plan = OrderedDict()
    stages = stagenames(w)
    @assert length(stages) > 0 "no stges defined"
        
    for s in stages # Walk through stages
        job_names = sorted == true ? sort(jobnames(w, s)) : jobnames(w, s)
        job_defs = []

        for j in job_names
            jdef = jobdefinition(w, j)
            if filter_disabled == true
                if jdef.disable == false
                    push!(job_defs, jdef.name)
                end
            else
                push!(job_defs, jdef.name)
            end
        end

        # Skip adding the stage to execution plan if it's empty
        if length(job_defs) > 0
            plan[s] = job_defs
        end
    end
    plan
end



"""Convert JobStatus to a Dictionary"""
function todict(o::JobStatus)
    objfields = fieldnames(typeof(o))
    Dict(i=>getproperty(o, i) for i in objfields)
end


"""Convert JobDefinition to a Dictionary"""
function todict(o::WLMJobDefinition)
    # get code struct and convert it to dict
    code = fieldnames(typeof(o.code))
    code_dict = Dict(i=>getproperty(o.code, i) for i in code)
    code_dict[:sasoption] = join(code_dict[:sasoption]) # convert vector to string
    code_dict[:code_name] = code_dict[:name] # rename :name for avoiding collision
    delete!(code_dict, :name)

    objfields = fieldnames(typeof(o))
    obj_dict = Dict(i=>getproperty(o, i) for i in objfields)
    obj_dict[:jobdef_name] = obj_dict[:name] # rename :name for avoiding collision
    delete!(obj_dict, :name) 

    obj_dict[:joboption] = join(obj_dict[:joboption]) # convert vector to string
    obj_dict[:jobfile] = join(obj_dict[:jobfile], ",") # convert vector to string
    
    res = merge(obj_dict, code_dict)
    res[:tags] = JSON3.write(res[:tags]) # convert Dict to JSON String
    
    delete!(res, :code) # code has been flattened above
end



"""Function to use for formatting Trees  (Term.jl)"""
function print_node(io, node; kw...)
    if node isa AbstractDict
        print(io, string(typeof(node)))
    elseif node isa AbstractVector
        print(io, string(typeof(node)))
    else
        print(io, node)
    end
end


"""Asynchronously submit vector of JobDefinitions"""
function batch_submit(bin::ViyaCLI, jdefs::Vector)
    if all(_isrunnable.(Ref(bin), jdefs))
        return asyncmap(x->cli_submitpgm(bin, x), jdefs)
    else
        throw(ErrorException("Some jobs in the batch are not runnable"))
    end
end


"""
    build_resultsDF(w, datadir)

Build a DataFrame combining the results from `json` and `JobDefinition`. input
is `Workload` and the directory containing the json files and workload.toml.
"""
function build_resultsDF(w::Workload, datadir::AbstractString)
    # Build a list of json files
    json_files = filter(x->endswith(x, ".json"), readdir(datadir))
    dcts = [] # to hold individual results
    for f in json_files
        fp = joinpath(datadir, f)
        jsn = JSON3.read(open(fp, "r"))
        # get jobdefinition of the jsn
        jd = jobdefinition(w, jsn[:name])
        jd_dct = todict(jd)
        push!(dcts, merge(jsn, jd_dct))
    end
    df = DataFrame(dcts)

    res = @chain df begin
        @mutate(modifiedTimeStamp = DateTime(modifiedTimeStamp))
        @mutate(endedTimeStamp = DateTime(endedTimeStamp))
        @mutate(creationTimeStamp = DateTime(creationTimeStamp))
        @mutate(submittedTimeStamp = DateTime(submittedTimeStamp))
        @mutate(startedTimeStamp = DateTime(startedTimeStamp))
        @mutate(totalRunTime = Second(endedTimeStamp - startedTimeStamp))
        @mutate(totalWaitTime = Second(startedTimeStamp - submittedTimeStamp))        
    end
    res
end




function _find_saslog(dir)
    file_list = readdir(dir)

    # if --verbose option is used with `sas-viya` CLI then 
    # there is a file SASBatchScriptDebug.log which gets generated
    # inside the fileset. Filtering out that file if it exists from the list
    file_list = filter(x->x!="SASBatchScriptDebug.log", file_list)


    logfile_idx = findfirst(x->endswith(x, ".log"), file_list)
    if logfile_idx === nothing
        @debug "log file not found in $dir - skipping"
        return nothing
    end

    logfilename = file_list[logfile_idx]
    sasfilename = replace(logfilename, ".log"=>".sas")
    if !isfile(joinpath(dir, sasfilename))
        @debug "missing: $sasfilename expected in $dir while processing logfile $logfilename"
        logfilename = nothing
    end
    logfilename
end



"""
    _is_saslogfile_valid(f)

Returns true if the sas logfile seems complete with the last 
FULLSTIMER logs. This ensures that the SAS job did not prematurely
terminated.
"""
function _is_saslogfile_valid(f::AbstractString)
    header_match = false
    footer_match = false

    rxheader = r"^NOTE: The SAS System used:"
    rxfooter = r"^\s{6}Block Output Operations.*$"

    rx = rxheader
    fd = open(f, "r")
    lines = readlines(fd)
    for l in lines
        if header_match == false
            header_match = occursin(rxheader, l) ? true : header_match
        elseif header_match == true
            footer_match = occursin(rxfooter, l) ? true : footer_match
        end
    end

    ret = header_match & footer_match == true ? true : false
    return ret
end



function summarize_results_from_dir(datadir::AbstractString)
    w = Workload(TOML.parsefile(joinpath(datadir, "workload.toml")))
    jsnfiles = filter(x->endswith(x, ".json"), readdir(datadir))
    plan = execution_plan(w)

    # Build a list of all jobnames from workload.toml
    result = Dict()
    for s in keys(plan)
        for jn in plan[s]
            result[jn] = Dict(:validlog => false, :stage => s, :name => jn)
        end
    end

    for j in jsnfiles # Parse json files and populate result
        jsn = JSON3.read(open(joinpath(datadir, j)))

        jobname = jsn[:name]
        filesetid = jsn[:fileSetId]

        logfilename = _find_saslog(joinpath(datadir, filesetid))
        result[jobname][:saslogfile] = logfilename === nothing ? missing : logfilename

        if logfilename !== nothing
            logfile_valid = _is_saslogfile_valid(joinpath(datadir, filesetid, logfilename))
            result[jobname][:validlog] = logfile_valid
        else
            result[jobname][:validlog] = false
        end

        result[jobname][:returnCode] = jsn[:returnCode]
        result[jobname][:fileSetId] = jsn[:fileSetId]
        
        if (result[jobname][:returnCode] == 0) &
                (result[jobname][:saslogfile] !== missing) &
                (result[jobname][:validlog] == true)
            result[jobname][:status] = "success"
        else
            result[jobname][:status] = "failed"
        end

    end
    
    df = [NamedTuple(i[2]) for i in result] |> DataFrame
    @chain df begin
        @select(stage, name, returnCode, validlog, saslogfile, fileSetId, status)
        @arrange(stage, status)
    end
end




function build_sastimerDF(w::Workload, datadir::AbstractString)
    # Build a list of json files
    json_files = filter(x->endswith(x, ".json"), readdir(datadir))
    dcts = [] # to hold individual results
    for f in json_files
        fp = joinpath(datadir, f)
        jsn = JSON3.read(open(fp, "r"))
        # get jobdefinition of the jsn
        jd = jobdefinition(w, jsn[:name])

        # Find & Process LogFile
        job_dir = joinpath(datadir, jsn[:fileSetId])
        logfilename = _find_saslog(job_dir)
        if logfilename === nothing
            @warn "Logfile for job $(jd.name) not found. Skipping"
            continue
        end
        stimer_log = parse_saslog(joinpath(job_dir, logfilename))
        df = DataFrame(stimer_log)
        df[!, :jobname] .= jd.name
        df[!, :jobqueue] .= jd.queue
        df[!, :jobprofile] .= jd.profile
        df[!, :jobstage] .= jd.stage
        df[!, :jobcode] .= jd.code.source
        df[!, :fileSetId] .= jsn[:fileSetId]
        df[!, :WLMendedTimeStamp] .= jsn[:endedTimeStamp]
        df[!, :WLMsubmittedTimeStamp] .= jsn[:submittedTimeStamp]
        df[!, :WLMreturnCode] .= jsn[:returnCode]
        df[!, :WLMmodifiedTimeStamp] .= jsn[:modifiedTimeStamp]
        df[!, :WLMstartedTimeStamp] .= jsn[:startedTimeStamp]
        df[!, :WLMcreationTimeStamp] .= jsn[:creationTimeStamp]
        df[!, :state] .= jsn[:state]
        df[!, :processId] .= jsn[:processId]
        push!(dcts, df)
    end
    return vcat(dcts...)
end





function _isrunnable(bin::ViyaCLI, jobdef::WLMJobDefinition)
    res = true 
    if !isfile(jobdef.code.source)
        @warn "File $(jobdef.code.source) not found"
        res = false
    end
    
    if length(jobdef.jobfile) != 0
	if all(isfile.(jobdef.jobfile)) != true
		@warn "missing jobfile $(jobdef.jobfile)"
		res = false
	end
    end
    return res
end
