using DataStructures


module ImportSandbox

    export include_test_files!

    function include_test_files!(test_files, add_load_path=nothing)
        if !(add_load_path === nothing)
            push!(LOAD_PATH, add_load_path)
        end

        eval(quote
            using Jute
            $((:(include($test_file)) for test_file in test_files)...)
        end)
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


struct TestcaseInfo
    path :: Array{String, 1}
    name :: String
    tags :: Set{Symbol}
end


path_pair(tcinfo::TestcaseInfo) = tcinfo.path, tcinfo.name


path_string(tcinfo::TestcaseInfo) = join([tcinfo.path; tcinfo.name], "/")


function tag_string(tcinfo::TestcaseInfo, labels; full::Bool=false)
    fixtures_tag = isempty(labels) ? "" : join(labels, ",")
    tc_tag = full ? path_string(tcinfo) : tcinfo.name
    if length(labels) > 0
        tc_tag * " [" * fixtures_tag * "]"
    else
        tc_tag
    end
end


function _get_testcases(obj_dict, parent_path=String[])
    testcases = []

    for obj in obj_dict
        if isa(obj, TestGroup)
            group_testcases = _get_testcases(get_testcases(obj), [parent_path; obj.name])
            append!(testcases, group_testcases)
        elseif isa(obj, Testcase)
            tcinfo = TestcaseInfo(parent_path, obj.name, obj.tags)
            push!(testcases, tcinfo => obj)
        end
    end

    testcases
end


function get_testcases(obj_dict)
    _get_testcases(obj_dict)
end
