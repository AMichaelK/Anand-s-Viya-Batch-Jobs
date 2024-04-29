
struct ViyaCLI{T <: AbstractString}
    executable::T
    insecure::Bool
    output::Symbol
    profile::T
end

function ViyaCLI(executable::AbstractString; 
            insecure=false, 
            output=:fulljson,
            profile="Default"
            )
    ViyaCLI(executable, insecure, output, profile)
end
