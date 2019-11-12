module StaticLintAtom

using LanguageServer
using SymbolServer


export server

# named_pipe = ARGS[1] # julia.exe path
named_pipe = "C:\\Users\\yahyaaba\\.julia\\environments\\v1.3"

server = LanguageServerInstance(stdin, stdout, true, named_pipe, "", Dict())
run(server)


end
