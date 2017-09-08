"""
A local fixture that creates a temporary directory and returns its name;
the directory and all its contents is removed during the teardown.
"""
const temporary_dir = @local_fixture begin
    dir = mktempdir()
    @produce dir
    rm(dir, recursive=true)
end


"""
A global fixture that returns the dictionary with the current run options
(see [`Run options`](@ref run_options_manual) in the manual for the full list.
"""
const run_options = run_options_fixture()
