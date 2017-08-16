using DataStructures


module ImportSandbox

    export include_test_files!
    export TESTCASE_ACCUM_ID

    const TESTCASE_ACCUM_ID = :__JUTE_TESTCASES__

    function include_test_files!(test_files, add_load_path=nothing)
        if !(add_load_path === nothing)
            push!(LOAD_PATH, add_load_path)
        end

        eval(quote
            using Jute
            task_local_storage(TESTCASE_ACCUM_ID, Any[])
            $((:(include($test_file)) for test_file in test_files)...)
        end)

        task_local_storage(TESTCASE_ACCUM_ID)
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


struct GroupPath
    path :: Array{String, 1}
end


struct TestcasePath
    group :: GroupPath
    name :: String
    creation_order :: Int
    tags :: Set{Symbol}
end


GroupPath() = GroupPath([])


Base.show(io::IO, gpath::GroupPath) = print(io, join(map(string, gpath.path), "/"))
function Base.show(io::IO, tcpath::TestcasePath)
    if !isroot(tcpath.group)
        show(io, tcpath.group)
        print(io, "/")
    end
    print(io, tcpath.name)
end


join_group_path(gpath::GroupPath, name::String) = GroupPath([gpath.path; name])


isroot(gpath::GroupPath) = isempty(gpath.path)


function Base.isless(gpath1::GroupPath, gpath2::GroupPath)
    p1 = gpath1.path
    p2 = gpath2.path
    if length(p1) != length(p2)
        isless(length(p1), length(p2))
    else
        isless(tuple(p1...), tuple(p2...))
    end
end
function Base.isless(tcpath1::TestcasePath, tcpath2::TestcasePath)
    if tcpath1.group != tcpath2.group
        isless(tcpath1.group, tcpath2.group)
    else
        isless(tcpath1.creation_order, tcpath2.creation_order)
    end
end


group_path(tcpath::TestcasePath) = tcpath.group


function _get_testcases(obj_dict, parent_path=GroupPath())
    testcases = []

    for obj in obj_dict
        if isa(obj, TestGroup)
            group_testcases = _get_testcases(
                get_testcases(obj),
                join_group_path(parent_path, obj.name))
            append!(testcases, group_testcases)
        elseif isa(obj, Testcase)
            path = TestcasePath(parent_path, obj.name, obj.order, obj.tags)
            push!(testcases, path => obj)
        end
    end

    testcases
end


function get_testcases(obj_dict)
    _get_testcases(obj_dict)
end
