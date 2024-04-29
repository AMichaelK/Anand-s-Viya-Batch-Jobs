
struct JobResult
    jobid::String
    jobname::String
    fileset_id::String
    datetime_submit::DateTime
    datetime_start::DateTime
    datetime_end::DateTime
    execution_host::String
    return_code::Int
end


function JobResult(f::AbstractString)
  lines = readlines(open(f))

  rex_jobid = r"^Job ID:\s+(\w.*)"
  rex_jobname = r"^Job name:\s+(\w.*)"
  rex_fileset_id = r"^File set ID:\s+(\w.*)"
  rex_datetime_submit = r"^Time job submitted:\s+(\w.+) (\+\w.+)"
  rex_datetime_start = r"^Time job started:\s+(\w.*) (\+\w.+)"
  rex_datetime_end = r"^Time job ended:\s+(\w.*) (\+\w.+)"
  rex_execution_host = r"^Name of execution host:\s+(\w.*)"
  rex_return_code = r"^Return code:\s+(\w.*)"

  params = Dict()
  for l in lines
      if ! (match(rex_jobid, l) === nothing)
          jobid = match(rex_jobid, l)[1]
          params["jobid"] = jobid

      elseif ! (match(rex_jobname, l) === nothing)
          jobname = match(rex_jobname, l)[1]
          params["jobname"] = jobname
      
      elseif ! (match(rex_fileset_id, l) === nothing)
          fileset_id = match(rex_fileset_id, l)[1]
          params["fileset_id"] = fileset_id

      elseif ! (match(rex_datetime_submit, l) === nothing)
          datetime_submit = match(rex_datetime_submit, l)[1]
          datetime_submit = DateTime(datetime_submit, dateformat"y-m-d H:M:S")
          params["datetime_submit"] = datetime_submit
      
      elseif ! (match(rex_datetime_start, l) === nothing)
          datetime_start = match(rex_datetime_start, l)[1]
          datetime_start = DateTime(datetime_start, dateformat"y-m-d H:M:S")
          params["datetime_start"] = datetime_start

      elseif ! (match(rex_datetime_end, l) === nothing)
          datetime_end = match(rex_datetime_end, l)[1]
          datetime_end = DateTime(datetime_end, dateformat"y-m-d H:M:S")
          params["datetime_end"] = datetime_end

      elseif ! (match(rex_execution_host, l) === nothing)
          execution_host = match(rex_execution_host, l)[1]
          params["execution_host"] = execution_host

      elseif ! (match(rex_return_code, l) === nothing)
          return_code = match(rex_return_code, l)[1]
          params["return_code"] = parse(Int, return_code)
      end
  end

  JobResult(  params["jobid"], 
              params["jobname"], 
              params["fileset_id"],
              params["datetime_submit"],
              params["datetime_start"],
              params["datetime_end"],
              params["execution_host"],
              params["return_code"],
            )
end


_exitcode(j::JobResult) = j.return_code
_runtime(j::JobResult) = (j.datetime_end - j.datetime_start)
_starttime(j::JobResult) = j.datetime_start
_endtime(j::JobResult) = j.datetime_end