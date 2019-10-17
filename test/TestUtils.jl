module TestUtils

using Jute

export nested_run
export nested_run_with_output
export test_match_text


strip_colors(s) = replace(s, r"\e\[\d+m" => "")


function _nested_run(tcs, options, output_pass_through)
    exitcode, output = Jute.with_output_capture(output_pass_through) do
        Jute.runtests(tcs; options=options, ignore_commandline=true)
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
    replace(s, r"([\.\[\]\(\)\\\*\+\?\^\$])" => s"\\\1")
end


function normalize_template(s)
    m = match(r"^(\s*)", s)
    s = replace(s, Regex("^$(m[1])", "m") => "")
    strip(s)
end


function test_match_text(template, text)
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
            @test_fail "Exhausted the text"
            return
        elseif template_i > length(template_lines)
            if skipping_multiline
                break
            end
            @test_fail "Exhausted the template"
            return
        end

        text_line = text_lines[text_i]
        template_line = template_lines[template_i]

        if occursin(r_multiline, template_line)
            skipping_multiline = true
            template_i += 1
        else
            s = "^" * escape_for_regex(template_line) * "\$"
            s = replace(s, r_variable => s"(?<\1>.*)")
            if !occursin(Regex(s), text_line)
                if !skipping_multiline
                    @test_fail (
                        "Failed to match the text line $text_i\n  $text_line\n" *
                        "with the template line $template_i\n  $template_line")
                    return
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
end


end
