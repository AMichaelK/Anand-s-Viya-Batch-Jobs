
"""
    SASTimer()

Struct to hold timing information from SAS Log files.
```
NOTE: PROCEDURE DATASETS used (Total process time):
      real time           0.00 seconds
      user cpu time       0.00 seconds
      system cpu time     0.00 seconds
      memory              304.57k
      OS Memory           16756.00k
      Timestamp           02/11/2023 01:35:19 AM
      Step Count                        957  Switch Count  0
      Page Faults                       0
      Page Reclaims                     7
      Page Swaps                        0
      Voluntary Context Switches        1
      Involuntary Context Switches      0
      Block Input Operations            0
      Block Output Operations           16
```

"""
struct SASTimer
    desc::Union{Nothing,AbstractString}
    memory::Union{Nothing, Number}
    block_output_operations::Union{Nothing, Int}
    page_faults::Union{Nothing, Int}
    involuntary_context_switches::Union{Nothing, Int}
    system_cpu_time::Union{Nothing, Number} 
    real_time::Union{Nothing, Number} 
    os_memory::Union{Nothing, Number}
    step_count::Union{Nothing, AbstractString}
    page_reclaims::Union{Nothing, Int}
    user_cpu_time::Union{Nothing, Number}
    page_swaps::Union{Nothing, Int}
    voluntary_context_switches::Union{Nothing, Int}
    block_input_operations::Union{Nothing, Int}
    timestamp::Union{Nothing,DateTime}
end

"""process string in the form of 1234.4k to numeric (* 2^10)"""
function _process_memory(str::AbstractString)
    unit = str[end]
    if unit == 'k'
        r = parse(Float64, str[1:end-1]) * 1024
    else
        try
            r = parse(Float64, str)
        catch e # If unable to parse print warning and return 0
            @warn "_process_memory(str): unexpected string for memory encountered $(str)"
            return 0
        end 
    end
    return r
end



"""process elapsed time string and return time in milliseconds"""
function _process_elapsed_time(str::AbstractString)
    #rx_min_sec =  r"^(?<min>.*):(?<sec>.*\..*)$"  # Match 1:46.74
    #rx_hr_min_sec = r"^(?<hr>.*):(?<min>.*):(?<sec>.*\..*)$" # Match 1:1:46.74

    rx_min_sec =  r"^(?<min>[0-9]+):(?<sec>[0-9]+\..*)$"
    rx_hr_min_sec = r"^(?<hr>[0-9]+):(?<min>[0-9]+):(?<sec>.*\..*)$" # Match 1:1:46.74
    rx_sec = r"^(?<sec>.*) seconds$"
    
    if occursin(rx_min_sec, str)
        m = match(rx_min_sec, str)
        min = parse(Float64, m[:min])
        msec = parse(Float64, m[:sec])*1000
        res = (min*60*1000)+msec
        return round(Int64, res)
        
    elseif occursin(rx_hr_min_sec, str)
        m = match(rx_hr_min_sec, str)
        hr = parse(Float64, m[:hr])
        min = parse(Float64, m[:min])
        msec = parse(Float64, m[:sec])*1000
        res = (hr*60*60*1000)+(min*60*1000)+msec
        return round(Int64, res)
        
    elseif occursin(rx_sec, str)
        m = match(rx_sec, str)
        msec = parse(Float64, m[:sec])*1000
        res = msec
        return round(Int64, res)
    else 
        return nothing
    end
end

function _sastimer2nt(o::SASTimer)
    k = fieldnames(SASTimer)
    v = getproperty.(Ref(o), k)
    zip(k,v) |> NamedTuple
end


function SASTimer(o::Dict) 
    desc                         = get(o, "desc", "")
    memory                       = _process_memory(get(o, "memory", "0"))
    block_output_operations      = parse(Int64, get(o, "Block Output Operations", "0"))
    page_faults                  = parse(Int64, get(o, "Page Faults", "0"))
    involuntary_context_switches = parse(Int64, get(o, "Involuntary Context Switches", "0"))

    # FIXME: Messy code... There are two cases that breaks this 
    # code which forced this messy fix. In some cases
    # SAS stops execution prematurely and that resulted in 
    # partial FULLSTIMER information in the log.

    system_cpu_time              = get(o, "system cpu time", "")
    if system_cpu_time == ""
        @warn "Encountered 'empty_string' for system_cpu_time in $o"
        system_cpu_time = 0
    else
        system_cpu_time = _process_elapsed_time(system_cpu_time)
    end

    real_time                    = get(o, "real time", "" )
    if real_time == ""
        @warn "Encountered 'empty_string' for real_time in $o"
        real_time = 0
    else
        real_time = _process_elapsed_time(real_time)
        if real_time === nothing
            @warn "Received Nothing while processing SASTimer for $o"
            real_time = 0
        end
    end
    
    os_memory                    = _process_memory(get(o, "OS Memory", "0"))
    step_count                   = get(o, "Step Count", "0")

    page_reclaims                = parse(Int64, get(o, "Page Reclaims", "0"))
    
    user_cpu_time                = get(o, "user cpu time", "" )
    if user_cpu_time == ""
        @warn "Encountered 'empty_string' for user_cpu_time for $desc (SASTimer)"
        user_cpu_time = 0
    else
        user_cpu_time = _process_elapsed_time(user_cpu_time)
    end
    
    page_swaps                   = parse(Int64, get(o, "Page Swaps", "0"))
    voluntary_context_switches   = parse(Int64, get(o, "Voluntary Context Switches", "0"))
    block_input_operations       = parse(Int64, get(o, "Block Input Operations", "0"))
    
    dfmt = dateformat"m/d/y HH:MM:SS p"
    
    try
        global timestamp         = DateTime(get(o, "Timestamp", "1/1/1980 2:2:2 AM") , dfmt)
    catch e
        @warn "unable to parse timestamp $o"
        throw(e)
    end

    
    SASTimer(   desc,
                memory, 
                block_output_operations,
                page_faults,
                involuntary_context_switches,
                system_cpu_time,
                real_time,
                os_memory,
                step_count,
                page_reclaims,
                user_cpu_time,
                page_swaps,
                voluntary_context_switches,
                block_input_operations,
                timestamp
        )
end


"""
    parse_saslog(logfile)

Parse log file produced by SAS runtime and extract runtime information generated
if the code is launched with -FULLSTIMER option.  

Returns a Vector{NamedTuple} of 
"""
function parse_saslog(logfile::AbstractString)
    # Regular Expressions
    rx_start    = r"NOTE: (?<procname>.+) used \(Total process time\)"
    rx_start2   = r"NOTE: (?<procname>The SAS System) used:"
    rx_start3   = r"NOTE: (?<procname>SAS initialization) used:"

    rx_formfeed = r".*The SAS System.*"
    rx_recline  = r"^\s{6}(?<key>.*\b)[ ]{5,}(?<val>.*.+)"
    rx_blank    = r"^\s*$"

    result = [] # Store all the records here

    procname = ""
    onrecord = false # this toggles on once the timing block is encountered
    dct = Dict()
    for (ix, l) in enumerate(readlines(logfile))
        if occursin(rx_start, l) 
            onrecord = true  # Inside the timing record block
            m = match(rx_start, l)
            procname = m[:procname]
            dct = Dict(procname=>Dict("desc"=>m.match))

        elseif occursin(rx_start2, l)
            onrecord = true  # Inside the timing record block
            m = match(rx_start2, l)
            procname = m[:procname]
            dct = Dict(procname=>Dict("desc"=>m.match))
        
        elseif occursin(rx_start3, l)
            onrecord = true  # Inside the timing record block
            m = match(rx_start3, l)
            procname = m[:procname]
            dct = Dict(procname=>Dict("desc"=>m.match))

        # skip if formfeed is encountered (noop)
        elseif occursin(rx_formfeed, l)
            nothing
        
        # skip blank line is encountered
        elseif occursin(rx_blank, l)
            #print("Blank: ($ix) ")
            nothing
        
        # if the line conforms to the record regex
        elseif occursin(rx_recline, l)
            #print("3($ix)")
            # somehow we encountered a record string without
            # being inside record processing
            if onrecord == false 
                # filter out some spurious matches by performing 
                # simple tests
                if length(l) > 68
                    nothing
                else
                    @info "skipping possibly spurious regex matched while parsing for FULLSTIMER block in ($logfile) \n$l"
                end
            else
                m = match(rx_recline, l)
                key = m[:key]
                val = m[:val]
                dct[procname][key] = val
            end
        else
            #print("4($ix)")
            if onrecord == true
                push!(result, dct)
                onrecord = false
            else
                nothing
            end
        end
    end
    # FIXME: Messy workaround
    # Push the last dictionary into results
    push!(result, dct)


    # convert Vector of Dict to Vector of SASTimer
    res = []
    for r in result
        key = (keys(r) |> collect)[1]
        obj = r[key]
        try
            push!(res, SASTimer(obj))
        catch e
            @warn "unable to process a block in $logfile - skipping"
        end
    end
    return res
end
