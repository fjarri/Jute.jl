using DataStructures


module ImportSandbox

    export include_test_files!, get_module_contents

    function get_module_contents(module_obj)
        Dict(name => getfield(module_obj, name) for name in names(module_obj, true))
    end

    function include_test_files!(test_files, add_load_path=nothing)
        if !(add_load_path === nothing)
            push!(LOAD_PATH, add_load_path)
        end

        eval(quote
            $((:(include($test_file)) for test_file in test_files)...)
        end)

        # FIXME: is it possible to avoid repeating the name of ImportSandbox?
        obj_dict = get_module_contents(ImportSandbox)

        # Remove the reference of the root module to itself
        delete!(obj_dict, :ImportSandbox)

        obj_dict
    end

end

using .ImportSandbox


function find_test_files(dir, test_file_postfix)
    fnames = String[]
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, test_file_postfix)
                push!(fnames, joinpath(root, file))
            end
        end
    end
    fnames
end


function get_runtests_dir()
    runtests_path = abspath(PROGRAM_FILE)
    runtests_dir, _ = splitdir(runtests_path)
    runtests_dir
end


function _get_testcases(obj_dict, test_module_prefix, this_module=nothing, parent_name_tuple=[])
    testcases = []
    for (name, obj) in obj_dict
        if isa(obj, Module) && obj != this_module
            if startswith(string(name), test_module_prefix)
                # Drop the common test module prefix
                prefix_len = length(test_module_prefix)
                test_module_name = Symbol(string(name)[prefix_len+1:end])

                module_testcases = _get_testcases(
                    get_module_contents(obj),
                    test_module_prefix,
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
    _get_testcases(obj_dict, run_options.test_module_prefix)
end
