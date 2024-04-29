abstract type AbstractBatchCode end

struct SASCode{T <: AbstractString, U <: Any} <: AbstractBatchCode
    source::T
    name::T
    tags::Dict{T, U}
    sasoption::Vector{T}
end


"""
    SASCode(source, name, tags, jobfiles, sasoption)
"""
function SASCode(source::AbstractString)
    name = basename(source) # extract name from filename
    tags = Dict()
    sasoption = AbstractString[]
    return SASCode(source, name, tags, sasoption)
end

    