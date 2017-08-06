using ArgParse


"""
For every option, the corresponding command-line argument names are given in parentheses.
If supplied via the `options` keyword argument of [`runtests()`](@ref Jute.runtests),
their type must be as given or `convert()`-able to it.

**`:include_only`**`:: Nullable{Regex}` (`--include-only`, `-i`):
takes a regular expression; tests with full names that do not match it will not be executed.

**`:exclude`**`:: Nullable{Regex}` (`--exclude`, `-e`):
takes a regular expression; tests with full names that match it will not be executed.

**`:verbosuty`**`:: Int` (`--verbosity`, `-v`):
`0`, `1` or `2`, defines the amount of output that will be shown. `1` is the default.

**`:include_only_tags`**`:: Array{Symbol, 1}` (`--include-only-tags`, `-t`):
include only tests with any of the specified tags.
You can pass several tags to this option, separated by spaces.

**`:exclude_tags`**`:: Array{Symbol, 1}` (`--exclude-tags`, `-t`):
exclude tests with any of the specified tags.
You can pass several tags to this option, separated by spaces.

**`:max_fails`**`:: Int` (`--max-fails`):
stop after the given amount of failed testcases
(a testcase is considered failed, if at least one test in it failed,
or an unhandeld exception was thrown).

**`:capture_output`**`:: Bool` (`--capture-output`):
capture all the output from testcases
and only show the output of the failed ones in the end of the test run.

**`:dont_add_runtests_path`**:`:: Bool` (`--dont-add-runtests-path):
capture testcase output and display only the output from failed testcases
after all the testcases are finished.

**`:test_file_postifx`**`:: String` (`--test-file-postfix`):
postfix of the files which will be picked up by the automatic testcase discovery.

**`:test_module_prefix`**`:: String` (`--test-module-prefix`):
prefix of the modules which will be searched for testcases during automatic testcase discovery.
"""
function build_parser()
    s = ArgParseSettings(; autofix_names=true)

    @add_arg_table s begin
        "--include-only", "-i"
            help = "include only tests (by path/name)"
            metavar = "REGEX"
        "--exclude", "-e"
            help = "exclude tests (by path/name)"
            metavar = "REGEX"
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
        "--max-fails"
            help = "stop after a certain amount of failed testcases"
            metavar = "NUM"
            arg_type = Int
            default = 0
        "--capture-output"
            help = ("capture testcase output and display only the output from failed testcases " *
                "after all the testcases are finished")
            nargs = 0
        "--verbosity", "-v"
            help = "the output verbosity (0-2)"
            arg_type = Int
            default = 1
        "--dont-add-runtests-path"
            help = "do not push the test root path into `LOAD_PATH` before including test files."
            nargs = 0
        "--test-file-postfix"
            help = ("postfix of the files which will be picked up " *
                "by the automatic testcase discovery.")
            metavar = "STR"
            arg_type = String
            default = ".test.jl"
        "--test-module-prefix"
            help = ("prefix of the modules which will be searched for testcases " *
                "during automatic testcase discovery.")
            metavar = "STR"
            arg_type = String
            default = ""
    end

    s
end


function normalize_options(run_options)

    run_options = deepcopy(run_options)

    maybe_regex(s) = s === nothing ? Nullable{Regex}() : Nullable{Regex}(Regex(s))

    run_options[:include_only] = maybe_regex(run_options[:include_only])
    run_options[:exclude] = maybe_regex(run_options[:exclude])

    run_options
end


function build_run_options_from_commandline(args)
    s = build_parser()
    normalize_options(parse_args(args, s; as_symbols=true))
end


function build_run_options_from_userdict(options)
    s = build_parser()
    run_options = parse_args([], s; as_symbols=true)
    run_options = normalize_options(run_options)
    for (key, val) in options
        if !haskey(run_options, key)
            error("Unknown option: $key")
        end
        run_options[key] = convert(typeof(run_options[key]), val)
    end
    run_options
end


function build_run_options(; args=nothing, options=nothing)
    if options === nothing && args === nothing
        build_run_options_from_commandline([])
    elseif options === nothing
        build_run_options_from_commandline(args)
    else
        build_run_options_from_userdict(options)
    end
end
