using StaticLintAtom
using Documenter

makedocs(;
    modules=[StaticLintAtom],
    authors="Amin Yahyaabadi",
    repo="https://github.com/aminya/StaticLintAtom.jl/blob/{commit}{path}#L{line}",
    sitename="StaticLintAtom.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aminya.github.io/StaticLintAtom.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/aminya/StaticLintAtom.jl",
)
