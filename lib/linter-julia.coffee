net = require 'net'

lintfromserver = (socket, str, fname) ->
  # This plus one probably because Julia starts index from 1
  siz = Buffer.byteLength(str, 'utf8') + 1
  socket.write "#{fname}\n"
  socket.write "#{siz}\n"
  socket.write str + "\n"

module.exports =
  config:
    linterjuliaport:
      title: 'Julia Lint Server Port'
      type: 'string'
      default: '2223'
      description: "julia -e \"using Lint; lintserver(2223)\""
      order: 1
    linterjuliadomain:
      title: 'Julia Lint Server Domain'
      type: 'string'
      default: 'localhost'
      description: "julia -e \"using Lint; lintserver(2223)\""
      order: 2
  activate: ->
    #lintserver = spawn 'julia', ['-e \"using Lint; lintserver(2223)\"']
    #require('atom-package-deps').install('linter-julia')

  provideLinter: ->
    provider =
      name: 'linter-julia'
      grammarScopes: ['source.julia']
      scope: 'file'
      lintsOnChange: true
      lint: (textEditor)->
        filePath = textEditor.getPath()
        inptext = textEditor.getText()

        console.log("I am alive")
        port = parseInt(atom.config.get('linter-julia.linterjuliaport'),10)
        domain = atom.config.get('linter-julia.linterjuliadomain')
        connection = net.createConnection(port, domain)

        connection.on 'connect', () ->
          console.log "Opened connection to #{domain}:#{port}."
          lintfromserver(connection, inptext, filePath)
          connection.end()

        linteroutput = [ ]

        connection.on 'data', (data) ->
          textChunk = data.toString('utf8')
          lines = textChunk.split("\n")

          for line in lines
            try
              splittedline = line.split(":")
              numbers = splittedline[1].split(" ")
              row_number = parseInt(numbers[0],10)
              severity = (numbers[1])[0]
              if severity.match("I")
                type = "Info"
              else if severity.match("W")
                type = "Warning"
              else
                type = "Error"
              text = splittedline[1] + ":" + splittedline[2]
              range = [[row_number - 1, 0], [row_number - 1,1]]
              fullmsg = {
                type
                text
                range
                filePath
              }
              linteroutput.push(fullmsg)

            catch TypeError
          rout = []
          linteroutput.forEach (rr) ->
            rout.push rr
          console.log rout
          connection.end()
          rout
