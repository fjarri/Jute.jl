using ArgParse


ArgParse.parse_item(::Type{Symbol}, s::AbstractString) = Symbol(s)


const ARG_DEFAULTS = Dict(
    :include_only => nothing,
    :exclude => nothing,
    :include_only_tags => Symbol[],
    :exclude_tags => Symbol[],
    :max_fails => 0,
    :capture_output => false,
    :verbosity => 1,
    :dont_add_runtests_path => false,
    :test_file_postfix => ".test.jl",
    )


function get_default(options, key)
    get(options, key, ARG_DEFAULTS[key])
end


"""
For every option, the corresponding command-line argument names are given in parentheses.
If supplied via the `options` keyword argument of [`runtests()`](@ref),
their type must be as given or `convert()`-able to it.

**`:include_only`**`:: Union{Nothing, Regex}` (`--include-only`, `-i`):
takes a regular expression; tests with full names that do not match it will not be executed.

**`:exclude`**`:: Union{Nothing, Regex}` (`--exclude`, `-e`):
takes a regular expression; tests with full names that match it will not be executed.

!!! note

    The full name refers to the name of the testcase and all its parent groups,
    separated by slashes (`/`).
    For example, the full name of the testcase "foo" in the group "bar", which, in turn,
    is defined in the group "baz", will be "baz/bar/foo".

**`:verbosity`**`:: Int` (`--verbosity`, `-v`):
`0`, `1` or `2`, defines the amount of output that will be shown. `1` is the default.

**`:include_only_tags`**`:: Array{Symbol, 1}` (`--include-only-tags`, `-t`):
include only tests with any of the specified tags.
You can pass several tags to this option, separated by spaces.

**`:exclude_tags`**`:: Array{Symbol, 1}` (`--exclude-tags`, `-n`):
exclude tests with any of the specified tags.
You can pass several tags to this option, separated by spaces.

**`:max_fails`**`:: Int` (`--max-fails`):
stop after the given amount of failed testcases
(a testcase is considered failed if at least one test in it failed,
or an unhandled exception was thrown).

**`:test_file_postifx`**`:: String` (`--test-file-postfix`):
postfix of the files which will be picked up by the automatic testcase discovery.

The flag arguments are processed in a special way if a non-default value is passed via
the `options` keyword argument of [`runtests()`](@ref).
In this case, the command-line option is replaced by its inverse (given second in the parentheses),
with the corresponding change in the default.

**`:capture_output`**`:: Bool` (`--capture-output`/`--dont-capture-output`):
capture all the output from testcases
and only show the output of the failed ones at the end of the test run.

**`:dont_add_runtests_path`**:`:: Bool` (`--dont-add-runtests-path`/`--add-runtests-path`):
do not push the test root path into `LOAD_PATH` before including test files
"""
function build_parser(options)
    s = ArgParseSettings(; autofix_names=true)

    default(key) = get_default(options, key)

    # We have to insert the defaults passed programmatically in the argument table,
    # since there is currently no way in ArgParse to determine whether an argument
    # was actually passed by the user or not (which may change with PR#47).

    add_arg_table(
        s,

        ["--include-only", "-i"],
        Dict(
            :help => "include only tests (by path/name)",
            :metavar => "REGEX",
            :default => default(:include_only)),

        ["--exclude", "-e"],
        Dict(
            :help => "exclude tests (by path/name)",
            :metavar => "REGEX",
            :default => default(:exclude)),

        ["--include-only-tags", "-t"],
        Dict(
            :help => "include only tests (by tag)",
            :metavar => "TAGS",
            :arg_type => Symbol,
            :nargs => '+',
            :default => default(:include_only_tags)),

        ["--exclude-tags", "-n"],
        Dict(
            :help => "exclude tests (by tag)",
            :metavar => "TAGS",
            :arg_type => Symbol,
            :nargs => '+',
            :default => default(:exclude_tags)),

        "--max-fails",
        Dict(
            :help => "stop after a certain amount of failed testcases",
            :metavar => "NUM",
            :arg_type => Int,
            :default => default(:max_fails)),

        ["--verbosity", "-v"],
        Dict(
            :help => "the output verbosity (0-2)",
            :arg_type => Int,
            :default => default(:verbosity)),

        "--test-file-postfix",
        Dict(
            :help =>
                "postfix of the files which will be picked up " *
                "by the automatic testcase discovery.",
            :metavar => "STR",
            :arg_type => String,
            :default => default(:test_file_postfix)),
        )

    # The flag arguments require a special treatment.
    # If a non-default value was made default programmatically,
    # the corresponding flag is useless, and instead we need a flag for the negation of said value.

    if default(:capture_output)
        add_arg_table(
            s,
            "--dont-capture-output",
            Dict(
                :help =>
                    "don't capture testcase output and display it during test run",
                :nargs => 0))
    else
        add_arg_table(
            s,
            "--capture-output",
            Dict(
                :help =>
                    "capture testcase output and display only the output from failed testcases " *
                    "after all the testcases are finished",
                :nargs => 0))
    end


    if default(:dont_add_runtests_path)
        add_arg_table(
            s,
            "--add-runtests-path",
            Dict(
                :help =>
                    "push the test root path into `LOAD_PATH` " *
                    "before including test files.",
                :nargs => 0))
    else
        add_arg_table(
            s,
            "--dont-add-runtests-path",
            Dict(
                :help =>
                    "do not push the test root path into `LOAD_PATH` " *
                    "before including test files.",
                :nargs => 0))
    end

    s
end


maybe_regex(::Nothing) = nothing
maybe_regex(s::String) = Regex(s)


function normalize_options(run_options)

    run_options = deepcopy(run_options)

    run_options[:include_only] = maybe_regex(run_options[:include_only])
    run_options[:exclude] = maybe_regex(run_options[:exclude])

    # Remove the possible negated flags

    if haskey(run_options, :dont_capture_output)
        run_options[:capture_output] = !run_options[:dont_capture_output]
        delete!(run_options, :dont_capture_output)
    end

    if haskey(run_options, :add_runtests_path)
        run_options[:dont_add_runtests_path] = !run_options[:add_runtests_path]
        delete!(run_options, :add_runtests_path)
    end

    run_options
end


function build_run_options_from_commandline(args, options)
    s = build_parser(options)
    normalize_options(parse_args(args, s; as_symbols=true))
end


function build_run_options(; args=nothing, options=nothing)
    if options === nothing
        options = Dict{Symbol, Any}()
    end

    if args === nothing
        args = String[]
    end

    for (key, val) in options
        if !haskey(ARG_DEFAULTS, key)
            error("Unknown option: $key")
        end
        options[key] = convert(typeof(ARG_DEFAULTS[key]), val)
    end

    build_run_options_from_commandline(args, options)
end
