struct Workload
    viyacli_path::AbstractString
    viyacli_insecure::Bool # use insecure connection -k
    viyacli_profile::AbstractString # default profile is "Default"
    stages::Vector{AbstractString}
    profile::Vector{JobProfile}
    job::Vector{AbstractJobDefinition}
end


"""Parse configuration dict and materialize struct `Workload`"""
function Workload(cfg::Dict)
    # Check if mandatory entries exists in general
    if !haskey(cfg, "general") || !haskey(cfg["general"], "stages")
        @error "mandatory section 'general:stages' missing"
    end

    obj = cfg["general"]
    viyacli_path = get(obj, "viyacli_path", "")
    viyacli_insecure = get(obj, "viyacli_insecure", false)
    viyacli_profile = get(obj, "viyacli_profile", "Default")

    stages = get(obj, "stages", [])
    @assert typeof(stages) <: Vector # stages section should be a vector


    profile = JobProfile[]
    if haskey(cfg, "profile")
        obj = cfg["profile"]
        for (name, dct) in obj
            jprof = JobProfile(dct, name)
            push!(profile, jprof)
        end
    end


    job = AbstractJobDefinition[]
    if haskey(cfg, "job")
        obj = cfg["job"]
        for (name, dct) in obj
            jdef = process_jobdefinition(dct, name)
            push!(job, jdef)
        end
    end

    Workload(viyacli_path, viyacli_insecure, viyacli_profile, stages, profile, job)
end



