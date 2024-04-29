"""
    JobStatus(executionHost, endedTimeStamp, submittedTimeStamp, processId, fileSetId, state, workloadJobId, 
              name, returnCode, id, modifiedTimeStamp, modifiedBy, createdBy, startedTimeStamp, creationTimeStamp,
              contextId)

`JobStatus` is used to hold the state information for an active or completed job in SAS Viya WLM.
"""
struct JobStatus
    executionHost::Union{Nothing, AbstractString}
    endedTimeStamp::Union{Nothing, DateTime}
    submittedTimeStamp::Union{Nothing, DateTime}
    processId::Union{Nothing, AbstractString}
    fileSetId::Union{Nothing, AbstractString}
    state::Union{Nothing, AbstractString}
    workloadJobId::Union{Nothing, AbstractString}
    name::Union{Nothing, AbstractString}
    returnCode::Union{Nothing, Int}
    id::Union{Nothing, AbstractString}
    modifiedTimeStamp::Union{Nothing, DateTime}
    modifiedBy::Union{Nothing, AbstractString}
    createdBy::Union{Nothing, AbstractString}
    startedTimeStamp::Union{Nothing, DateTime}
    creationTimeStamp::Union{Nothing, DateTime}
    contextId::Union{Nothing, AbstractString}
end



function parse_jobstatus(d::Dict)
    executionHost       = get(d, :executionHost, "")

    endedTimeStamp      = get(d, :endedTimeStamp, nothing)
    (endedTimeStamp !== nothing) && (endedTimeStamp = parse_timestamp(endedTimeStamp))

    submittedTimeStamp  = get(d, :submittedTimeStamp, "")
    (submittedTimeStamp !== nothing) && (submittedTimeStamp = parse_timestamp(submittedTimeStamp))

    processId           = get(d, :processId, nothing)
    fileSetId           = get(d, :fileSetId, "")
    state               = get(d, :state, "")
    workloadJobId       = get(d, :workloadJobId, "")
    name                = get(d, :name, "")
    returnCode          = get(d, :returnCode, nothing)
    id                  = get(d, :id, "")

    modifiedTimeStamp   = get(d, :modifiedTimeStamp, nothing)
    modifiedTimeStamp = (modifiedTimeStamp !== nothing) ? parse_timestamp(modifiedTimeStamp) : modifiedTimeStamp

    modifiedBy          = get(d, :modifiedBy, "")
    createdBy           = get(d, :createdBy, "")

    startedTimeStamp    = get(d, :startedTimeStamp, nothing)
    startedTimeStamp = (startedTimeStamp !== nothing) ? parse_timestamp(startedTimeStamp) : startedTimeStamp

    creationTimeStamp   = get(d, :creationTimeStamp, "")
    creationTimeStamp = (creationTimeStamp !== nothing) ? parse_timestamp(creationTimeStamp) : creationTimeStamp

    contextId           = get(d, :contextId, "")

    JobStatus(  executionHost, 
                endedTimeStamp,
                submittedTimeStamp,
                processId,
                fileSetId,
                state,
                workloadJobId,
                name,
                returnCode,
                id,
                modifiedTimeStamp,
                modifiedBy,
                createdBy,
                startedTimeStamp,
                creationTimeStamp,
                contextId )

end


"""Return the returnCode from a WLM Job"""
exitcode(j::JobStatus) = j.returnCode

"""Returns total runtime of a job in seconds"""
runtime(j::JobStatus) = (j.endedTimeStamp - j.startedTimeStamp)
starttime(j::JobStatus) = j.startedTimeStamp
endtime(j::JobStatus) = j.endedTimeStamp
waitingtime(j::JobStatus) = (j.startedTimeStamp - j.submittedTimeStamp)


"""Check if a job is finished executing by checking for presence of endedTimeStamp"""
function isfinished(j::JobStatus)
    if !(j.endedTimeStamp === nothing)
        return true
    else
        return false
    end
end