racket:
    cd racket && racket weather.rkt

ocaml:
    cd ocaml && dune exec ./main.exe

fsharp:
    cd fsharp && dotnet fsi weather.fsx

all: racket ocaml fsharp
