"""
A global fixture that contains the current
[`RunOptions`](@ref Jute.RunOptions) object
"""
run_options = fixture() do produce
    produce([build_run_options()])
end


"""
A local fixture that creates a temporary directory and returns its name;
the directory and all its contents is removed during the teardown.
"""
temporary_dir = local_fixture() do produce
    dir = mktempdir()
    produce(dir)
    rm(dir, recursive=true)
end
