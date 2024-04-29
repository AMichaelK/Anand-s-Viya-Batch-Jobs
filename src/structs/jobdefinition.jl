
abstract type AbstractJobDefinition end

struct WLMJobDefinition{T <: AbstractString, U <: Any} <: AbstractJobDefinition
    name::T
    description::T
    tags::Dict{T, U}
    code::AbstractBatchCode
    queue::T
    context::T
    joboption::Vector{T}
    jobfile::Vector{T}
    stage::T
    profile::T
    disable::Bool
end

function WLMJobDefinition(sc::SASCode)
    name = sc.name
    description = ""
    tags = sc.tags
    code = sc
    queue = "default"
    context = "default"
    joboption = String[]
    jobfile = AbstractString[]
    stage = ""
    profile = ""
    disable = false
    WLMJobDefinition(name, description, tags, code, queue, context, joboption, jobfile, stage, profile, disable)
end



function process_jobdefinition(dct::Dict, name::T) where {T <: AbstractString}
    haskey(dct, "sourcecode") || error("jobdefinition[$(name)]: missing sourcode")
    
    sourcecode = get(dct, "sourcecode", "")
    description = get(dct, "description", "")
    tags = get(dct, "tags", Dict{T,Any}())
    queue = get(dct, "queue", "")
    context = get(dct, "context", "")
    joboption = get(dct, "joboption", T[])
    jobfile = get(dct, "jobfile", T[])
    profile = get(dct, "profile", "")
    stage = get(dct, "stage", "")
    disable = get(dct, "disable", false)

    sasoption = get(dct, "sasoption", T[])
    code = SASCode(sourcecode, basename(sourcecode), tags, sasoption)
    WLMJobDefinition(name, description, tags, code, queue, context, joboption, jobfile, stage, profile, disable)
end


# TODO: Where is this used? see if this is obsoleted
function get_jobdefinitions(cfg::Dict)
    jobdicts = get(cfg, "job", [])
    jobdefs = []
    if jobdicts == []
        @warn "no jobs found in the configuration"
    else
        for (name, dct) in jobdicts
            println("$(name) = $(dct)")
            jd = process_jobdefinition(dct, name)
            push!(jobdefs, jd)
        end
    end
    return jobdefs
end