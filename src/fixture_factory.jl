struct FixtureFactory
    channel_func
    delayed_teardown
    returns_iterable
end


struct RunningFixtureFactory
    task
    channel
    delayed_teardown
end


struct LabeledValue
    value :: Any
    label :: String
end


labeled_value(value, label=nothing) =
    LabeledValue(value, label === nothing ? string(value) : label)


function fixture_factory(producer_func; delayed_teardown=false, returns_iterable=false)
    channel_func = function(c)
        produce = function(value, label=nothing)
            if returns_iterable
                if label === nothing
                    ret = map(labeled_value, value)
                else
                    ret = map(labeled_value, value, label)
                end
            else
                ret = labeled_value(value, label)
            end

            put!(c, ret)

            if delayed_teardown
                # block until the caller's signal
                take!(c)
            end
        end
        args = take!(c)
        producer_func(produce, args...)
    end
    FixtureFactory(channel_func, delayed_teardown, returns_iterable)
end


function setup(ff::FixtureFactory, args)
    # Currently we cannot `wait()` on a channel that gets closed during waiting,
    # because an exception gets thrown.
    # We do not want to do the dirty hack from base/channels.jl
    # where they wrap `wait()` in a try/catch and check the resulting exception.
    # So we create a task explicitly. A `Task` object can be waited on safely.
    channel = Channel(0) # an unbuffered channel
    task = Task(() -> ff.channel_func(channel))
    schedule(task)
    put!(channel, args)
    ret = take!(channel)
    rff = RunningFixtureFactory(task, channel, ff.delayed_teardown)
    ret, rff
end


function teardown(rff::RunningFixtureFactory)
    if rff.delayed_teardown
        put!(rff.channel, nothing)
    end
    if !istaskdone(rff.task)
        wait(rff.task)
    end
end
