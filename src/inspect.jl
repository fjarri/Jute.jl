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


struct GroupPath
    path :: Array{Symbol, 1}
end


struct TestcasePath
    group :: GroupPath
    name :: Symbol
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


join_group_path(gpath::GroupPath, name::Symbol) = GroupPath([gpath.path; name])


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


function _get_testcases(
        obj_dict, test_module_prefix, this_module=nothing, parent_path=GroupPath())

    prefix_len = length(test_module_prefix)
    testcases = []
    for (name, obj) in obj_dict
        if isa(obj, Module) && obj != this_module
            if startswith(string(name), test_module_prefix)
                # Drop the common test module prefix
                test_module_name = Symbol(string(name)[prefix_len+1:end])

                module_testcases = _get_testcases(
                    get_module_contents(obj),
                    test_module_prefix,
                    obj,
                    join_group_path(parent_path, test_module_name))
                append!(testcases, module_testcases)
            end
        elseif isa(obj, Testcase)
            path = TestcasePath(parent_path, name, obj.order, obj.tags)
            push!(testcases, path => obj)
        end
    end
    testcases
end


function get_testcases(obj_dict, test_module_prefix)
    _get_testcases(obj_dict, test_module_prefix)
end
