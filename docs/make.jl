#push!(LOAD_PATH,"../src/")
using Documenter, GENeSYS_MOD

#makedocs(sitename="GENeSYS-MOD")

# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
if isfile(news)
    rm(news)
end
cp("NEWS.md", news)
#cp(joinpath(@__DIR__,"..","NEWS.md"), joinpath(@__DIR__,"src/manual/NEWS.md"), force=true)

DocMeta.setdocmeta!(GENeSYS_MOD, :DocTestSetup, :(using GENeSYS_MOD); recursive=true)

makedocs(
    sitename = "GENeSYS_MOD.jl",
    format = Documenter.HTML(;
    prettyurls=get(ENV, "CI", "false") == "true",
    edit_link="main",
    assets=String[],
    ),
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
    repo = "github.com/GENeSYS-MOD/GENeSYS_MOD.jl.git",
)