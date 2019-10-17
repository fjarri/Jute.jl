using Documenter
using Jute


makedocs(
    modules = [Jute],
    format = Documenter.HTML(prettyurls=false),
    sitename = "Jute.jl",
    authors = "Bogdan Opanchuk",
    pages = [
        "Home" => "index.md",
        "Manual" => "manual.md",
        "Public API" => "public.md",
        "Internals" => "internals.md",
        "Version history" => "history.md",
    ],
)

deploydocs(
    repo = "github.com/fjarri/Jute.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
