push!(LOAD_PATH,"../src/")
using Documenter, GENeSYS_MOD

#makedocs(sitename="GENeSYS-MOD")

# Copy the NEWS.md file
news = "src/manual/NEWS.md"
if isfile(news)
    rm(news)
end
cp(joinpath(@__DIR__,"..","NEWS.md"), joinpath(@__DIR__,"src/manual/NEWS.md"), force=true)

makedocs(
    sitename = "GENeSYS_MOD.jl",
    modules = [GENeSYS_MOD],
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start" => "manual/quick-start.md",
            "Example" => "manual/simple-example.md",
            "Release notes" => "manual/NEWS.md",
        ],
        "Library" => Any[
            "Public" => "library/public.md",
            "Internals" => "library/internals.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/dqpinel/GENeSYS_MOD.jl.git",
)