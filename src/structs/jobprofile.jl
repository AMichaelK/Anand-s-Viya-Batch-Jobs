struct JobProfile{T <: AbstractString}
    name::T
    description::T
    jobfile::Vector{T}
    sasoption::Vector{T}
    queue::T
    context::T
end

"""
    JobProfile(name, description, jobfile, sasoption, queue, context)
    JobProfile(dict, name)

JobProfile contains the global settings that could be applied to any JobDefinition. In 
the event same setting exists in the JobDefinition also then the settings from JobDefinition
would prevail. The structure of JobProfile is described below.

```julia
struct JobProfile{T <: AbstractString}
    name::T
    description::T
    jobfile::Vector{T}
    sasoption::Vector{T}
    queue::T
end
```
"""
function JobProfile(o::Dict, name::T) where {T <: AbstractString}
    name = name
    description = get(o, "description", "")

    jobfile     = get(o, "jobfile", T[])
    # handle scenario where empty array is specified in the toml
    # which is parsed as Vector{Union{}} cast these empty arrays to conforming types
    jobfile = (typeof(jobfile) <: Vector{Union{}}) ? T[] : jobfile
    ( (typeof(jobfile) <: Vector{T}) ) || 
        error("while parsing profile '$(name)': jobfile should be a vector found $(typeof(jobfile))")
    
    sasoption   = get(o, "sasoption", T[])
    # handle scenario where empty array is specified in the toml
    # which is parsed as Vector{Union{}} cast these empty arrays to conforming types
    sasoption = (typeof(sasoption) <: Vector{Union{}}) ? T[] : sasoption
    ( (typeof(sasoption) <: Vector{T}) ) || 
        error("while parsing profile '$(name)': sasoption should be a vector")

    queue   = get(o, "queue", "")
    context = get(o, "context", "")

    JobProfile(name, 
                description,
                jobfile,
                sasoption,
                queue,
		context
                )
end



"""
    apply_jobprofile(jd, jp)

Override values in `jd::JobDefinition` by using the values defined in `jp::JobProfile`.
Returns `JobDefinition`. 

Profile section contains three parameters `jobfile`, `queue` and `sasoptions`. 
When there is a collision i.e. an option that exists in both `[job]` section and `[profile]` 
section then the settings from `[profile]` takes precedence with certain nuances. 

* `queue`: The queue name specified in the `profile` section overrides the queue 
  name defined in `job` section.

*  `jobfile`: Only the file names in the vector where there is a collision are overridden 
  in the `[job]` section. The files that are unique to both `[profile]` and `[job]` are 
  appended to the resulting `jobfile` section. In the example below the effective `jobfile` 
  after processing the configuration would result in `["workload/sample/iris.csv", 
  "workload/sample/autoexec.sas", "workload/sample/petals.csv"]` which would drop 
  `"workload/autoexec.sas"` because `autoexec.sas` file is the one that causes collision.

```toml
[profile]
[profile.highmem]
jobfile = ["workload/sample/iris.csv", "workload/sample/autoexec.sas"]

[job]
[job.job1]
sourcecode = "workload/sample/model.sas"
profile = "highmem"
jobtype = "sascode"
jobfile = ["workload/sample/petals.csv", "workload/autoexec.sas"]
```

* `sasoption`: The options provided in profile are used and then all the option defined in 
  the job are iterated over. For all the option where there is no collision the options are
  appended.  
"""
function apply_jobprofile(jd::WLMJobDefinition, jp::JobProfile; inject_fullstimer=true)
    newjob = deepcopy(jd)

    # override queue if defined
    if jp.queue != ""
        newjob = @set newjob.queue = jp.queue
    end

    # override context if defined
    if jp.context != ""
	newjob = @set newjob.context = jp.context
    end

    # override sasoption if defined
    if length(jp.sasoption) > 0
        newjob = @set newjob.code.sasoption = jp.sasoption
    end

    # inject "-FULLSTIMER" option to sasoption if it does not exists
    if inject_fullstimer == true
        if ! any(occursin.(uppercase.(newjob.code.sasoption), "-FULLSTIMER"))
            opts = newjob.code.sasoption
            push!(opts, "-FULLSTIMER")
            newjob = @set newjob.code.sasoption = opts
        end
    end


    # use jobfile from profile and append any file where
    # filename does not exist in JobProfile (overwriting only the conflicts with JobProfile)
    if length(jp.jobfile) > 0
        newjobfile = deepcopy(jp.jobfile)
        for filename in jd.jobfile # notice 'jd' vs 'jp' different (wrong choice of variable)
            if !(basename(filename) in basename.(newjobfile))
                push!(newjobfile, filename)
            end
        end
        newjob = @set newjob.jobfile = newjobfile
    end


    # user "sasoption" from "profile" as the base and then append all from 
    # job section which are not already present in profile. Effectively
    # overriding all collision with the ones in profile. 
    newsasoption = deepcopy(jp.sasoption)
    opt_tokens   = getindex.(split.(newsasoption, " "), 1)

    for option in jd.code.sasoption
        opt = split(option, " ")[1]
        (opt in opt_tokens) || push!(newsasoption, option)
    end
    newjob = @set newjob.code.sasoption = newsasoption
   
    newjob
end
