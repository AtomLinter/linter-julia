net = require 'net'
{spawn} = require 'child_process'
tmp = require('tmp')
fs = require('fs')

lintfromserver = (socket, str, fname) ->
  # This plus one probably because Julia starts index from 1
  siz = Buffer.byteLength(str, 'utf8') + 1
  socket.write "#{fname}\n"
  socket.write "#{siz}\n"
  socket.write str + "\n"

doSomeMagic = (data,textEditor) ->
  filePath = textEditor.getPath()
  inptext = textEditor.getText()
  column = parseInt(atom.config.get('linter-julia.column'),10)
  linteroutput = [ ]

  lines = data.split("\n")
  for line in lines
    try
      splittedline = line.split(":")
      numbers = splittedline[1].split(" ")
      row_number = parseInt(numbers[0],10) - 1
      severity = (numbers[1])[0]
      if severity.match("I")
        type = "Info"
      else if severity.match("W")
        type = "Warning"
      else
        type = "Error"
      text = numbers[1] + ":" + splittedline[2]
      range = [[row_number, 0], [row_number, column]]
      fullmsg = {
        type
        text
        range
        filePath
      }
      linteroutput.push(fullmsg)

    catch e
      if e.message != "Cannot read property 'split' of undefined"
        console.log e

  linteroutput


module.exports =
  config:
    column:
      title: 'Error message column end, the column start is 0'
      type: 'string'
      default: '80'
      description: "Lint.jl doesn't return the error column, thus the whole line
                    is used, meaning column end is 80. To get back to the
                    previous behavior change the column end to 1"
      order: 1
    julia:
      title: 'Julia executable location, by default this comes from Juno'
      type: 'string'
      default: 'get_from_Juno'
      description: "Insert here the path to the julia.exe, which one you want
        to use. For example:\n In Windows:
        C:\\Users\\Julia\\AppData\\Local\\Julia-0.5.0\\bin\\julia.exe\n
        In Linux: /usr/bin/julia"
      order: 2

  activate: ->
    if atom.config.get('linter-julia.julia') != 'get_from_Juno'
      julia = atom.config.get('linter-julia.julia')
    else
      julia = atom.config.get('julia-client.juliaPath')

    tempfil = tmp.tmpNameSync({ prefix:'lintserver',postfix: 'sock'})
    if process.platform == 'win32'
      global.named_pipe = '\\\\.\\pipe\\' + tempfil.split("\\").pop()
      pipetospawn = named_pipe.replace(/\\/g,"\\\\")
      jcode = "using Lint; lintserver(\"#{pipetospawn}\")"
    else
      global.named_pipe = tempfil
      jcode = "using Lint; lintserver(\"#{named_pipe}\")"

    jserver = spawn julia, ['-e', jcode]
    jserver.stdout.on 'data', (data) -> console.log data.toString().trim()
    jserver.stderr.on 'data', (data) -> console.log data.toString().trim()

  deactivate: ->
    # Removes the socket when shutting down
    if process.platform != 'win32'
      fs.unlinkSync(named_pipe)

  provideLinter: ->
    provider =
      name: 'linter-julia'
      grammarScopes: ['source.julia']
      scope: 'file'
      lintOnFly: true
      lint: (textEditor)->
        connection = net.createConnection(named_pipe)

        return new Promise (resolve, reject) ->
          data = []
          connection.on 'connect', () ->
            inptext = textEditor.getText()
            filePath = textEditor.getPath()
            lintfromserver(connection, inptext, filePath)
            connection.end()
          connection.on('error',reject)
          connection.on 'data', (chunk) ->
            data.push(chunk)
          connection.on 'close', () ->
            allOfData = data.join('')
            resolve(doSomeMagic(allOfData,textEditor))
