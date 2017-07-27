using Documenter
using Jute


makedocs(
    modules = [Jute],
    clean = false,
    format = :html,
    sitename = "Jute.jl",
    authors = "Bogdan Opanchuk",
    pages = [
        "Home" => "index.md",
    ],
)

deploydocs(
    repo = "github.com/fjarri/Jute.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
