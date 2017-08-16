module TestUtils

using Jute

export nested_run
export nested_run_with_output
export match_text


strip_colors(s) = replace(s, r"\e\[\d+m", "")


function _nested_run(tcs, options, output_pass_through)
    run_options = build_run_options(options=options)
    exitcode, output = with_output_capture(output_pass_through) do
        Jute.runtests_internal(run_options, tcs)
    end
    exitcode, strip_colors(output)
end


function nested_run(tcs, options=nothing)
    if options === nothing
        options = Dict{Symbol, Any}()
    else
        options = Dict{Symbol, Any}(options)
    end
    options[:verbosity] = 0
    exitcode, output = _nested_run(tcs, options, true)
    exitcode
end


function nested_run_with_output(tcs, options=nothing)
    _nested_run(tcs, options, false)
end


function escape_for_regex(s)
    replace(s, r"([\.\[\]\(\)\\\*\+\?\^\$])", s"\\\1")
end


function normalize_template(s)
    m = match(r"^(\s*)", s)
    s = replace(s, Regex("^$(m[1])", "m"), "")
    strip(s)
end


# FIXME: when the "fail description" functionality is available,
# we need to use it here, so that the match fails are reported as fails and not errors.
function match_text(template, text)
    text_lines = split(strip(text), "\n")
    template_lines = split(normalize_template(template), "\n")

    text_i = 1
    template_i = 1

    r_multiline = r"^<<<MULTILINE>>>$"
    r_variable = r"<<<([\w\d_]+)>>>"

    skipping_multiline = false
    while true
        if text_i > length(text_lines) && template_i > length(template_lines)
            break
        elseif text_i > length(text_lines)
            error("Exhausted text")
        elseif template_i > length(template_lines)
            if skipping_multiline
                break
            end
            error("Exhausted template")
        end

        text_line = text_lines[text_i]
        template_line = template_lines[template_i]

        if ismatch(r_multiline, template_line)
            skipping_multiline = true
            template_i += 1
        else
            s = "^" * escape_for_regex(template_line) * "\$"
            s = replace(s, r_variable, s"(?<\1>.*)")
            if !ismatch(Regex(s), text_line)
                if !skipping_multiline
                    error("Failed to match line\n$text_line\nwith\n$s")
                else
                    text_i += 1
                end
            else
                skipping_multiline = false
                text_i += 1
                template_i += 1
            end
        end
    end

    true
end


end
