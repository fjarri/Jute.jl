using ArgParse


function ArgParse.parse_item(::Type{Nullable{Regex}}, x::AbstractString)
    if length(x) == 0
        Nullable{Regex}()
    else
        Nullable{Regex}(Regex(x))
    end
end


function parse_commandline()
    s = ArgParseSettings(; autofix_names=true)

    @add_arg_table s begin
        "--include-only", "-i"
            help = "include only tests (by tag)"
            metavar = "REGEX"
            arg_type = Nullable{Regex}
        "--exclude", "-e"
            help = "exclude tests (by tag)"
            metavar = "REGEX"
            arg_type = Nullable{Regex}
        "--verbosity", "-v"
            help = "the output verbosity (0-2)"
            arg_type = Int64
            default = 1
    end

    parse_args(s; as_symbols=true)
end


function parse_inifile()
    # TODO: in future these will be set through an ini file
    return Dict(
        :dont_add_runtests_path => false,
        :test_file_postfix => ".test.jl",
        :test_module_prefix => "",
        )
end


struct RunOptions
    dont_add_runtests_path :: Bool
    test_module_prefix :: String
    test_file_postfix :: String
    include_only :: Nullable{Regex}
    exclude :: Nullable{Regex}
    verbosity :: Int64
end


function RunOptions(vals_dict)
    args = [vals_dict[fname] for fname in fieldnames(RunOptions)]
    RunOptions(args...)
end


function build_run_options()
    inifile_opts = parse_inifile()
    cmdline_opts = parse_commandline()
    RunOptions(merge(inifile_opts, cmdline_opts))
end
