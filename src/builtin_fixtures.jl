run_options = fixture() do produce
    produce([build_run_options()])
end


temporary_dir = local_fixture() do produce
    dir = mktempdir()
    produce(dir)
    rm(dir, recursive=true)
end
