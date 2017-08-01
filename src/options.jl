using ArgParse


# Avoiding an addition of a method for a function we don't own for types we don't own.
# Hence, we need a wrapper type.
struct MaybeRegex
    regex :: Nullable{Regex}
end


Base.convert(::Type{Nullable{Regex}}, x::MaybeRegex) = x.regex


function ArgParse.parse_item(::Type{MaybeRegex}, x::AbstractString)
    if length(x) == 0
        MaybeRegex(Nullable{Regex}())
    else
        MaybeRegex(Nullable{Regex}(Regex(x)))
    end
end


function parse_commandline(args)
    s = ArgParseSettings(; autofix_names=true)

    @add_arg_table s begin
        "--include-only", "-i"
            help = "include only tests (by path/name)"
            metavar = "REGEX"
            arg_type = MaybeRegex
        "--exclude", "-e"
            help = "exclude tests (by path/name)"
            metavar = "REGEX"
            arg_type = MaybeRegex
        "--include-only-tags", "-t"
            help = "include only tests (by tag)"
            metavar = "TAGS"
            arg_type = Symbol
            nargs = '+'
        "--exclude-tags", "-n"
            help = "exclude tests (by tag)"
            metavar = "TAGS"
            arg_type = Symbol
            nargs = '+'
        "--verbosity", "-v"
            help = "the output verbosity (0-2)"
            arg_type = Int
            default = 1
    end

    parse_args(args, s; as_symbols=true)
end


function parse_inifile()
    # TODO: in future these will be set through an ini file
    return Dict(
        :dont_add_runtests_path => false,
        :test_file_postfix => ".test.jl",
        :test_module_prefix => "",
        )
end


"A set of options for running the test suite."
struct RunOptions
    "If `true`, do not push the test root path into `LOAD_PATH` before including test files."
    dont_add_runtests_path :: Bool
    "The prefix of modules containing testcases; used during the test discovery stage."
    test_module_prefix :: String
    "The postfix of files containing testcases; used during the test discovery stage."
    test_file_postfix :: String
    "The regexp specifying the testcases to include (applied to the full tag)."
    include_only :: Nullable{Regex}
    "The regexp specifying the testcases to exclude (applied to the full tag)."
    exclude :: Nullable{Regex}
    "Only testcases with any of these tags will be included."
    include_only_tags :: Array{Symbol, 1}
    "Testcases with any of these tags will be excluded."
    exclude_tags :: Array{Symbol, 1}
    "The reporting verbosity."
    verbosity :: Int
end


function RunOptions(vals_dict)
    args = [vals_dict[fname] for fname in fieldnames(RunOptions)]
    RunOptions(args...)
end


function build_run_options(args)
    inifile_opts = parse_inifile()
    cmdline_opts = parse_commandline(args)
    RunOptions(merge(inifile_opts, cmdline_opts))
end
