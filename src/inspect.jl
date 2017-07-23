using DataStructures


module ImportSandbox

    using Jute: RunOptions

    export load_test_files, get_module_contents

    function get_module_contents(module_obj)
        Dict(name => getfield(module_obj, name) for name in names(module_obj, true))
    end

    function load_test_files(run_options::RunOptions)
        runtests_path = abspath(PROGRAM_FILE)
        runtests_dir, _ = splitdir(runtests_path)

        if !run_options.dont_add_runtests_path
            push!(LOAD_PATH, runtests_dir)
        end

        for (root, dirs, files) in walkdir(runtests_dir)
            for file in files
                if endswith(file, run_options.test_file_postfix)
                    fname_full = joinpath(root, file)
                    @eval include($fname_full)
                end
            end
        end

        # FIXME: is it possible to avoid repeating the name of ImportSandbox?
        get_module_contents(ImportSandbox)
    end

end

using .ImportSandbox


function _get_testcases(run_options::RunOptions, obj_dict, this_module, parent_name_tuple=[])
    testcases = []
    for (name, obj) in obj_dict
        if isa(obj, Module) && obj != this_module
            if startswith(string(name), run_options.test_module_prefix)
                # Drop the common test module prefix
                prefix_len = length(run_options.test_module_prefix)
                test_module_name = Symbol(string(name)[prefix_len+1:end])

                module_testcases = _get_testcases(
                    run_options,
                    get_module_contents(obj),
                    obj,
                    [parent_name_tuple..., test_module_name])
                append!(testcases, module_testcases)
            end
        elseif isa(obj, Testcase)
            name_tuple = [parent_name_tuple..., name]
            push!(testcases, (name_tuple, obj))
        end
    end
    testcases
end


function get_testcases(run_options::RunOptions, obj_dict)
    # FIXME: get rid of explicit specification of ImportSandbox
    _get_testcases(run_options, obj_dict, ImportSandbox)
end
