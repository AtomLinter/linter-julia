net = require 'net'
{spawn} = require 'child_process'
tmp = require('tmp')
fs = require('fs')

module.exports =
  config:
    julia:
      title: 'Julia executable location, by default this comes from Juno'
      type: 'string'
      default: 'get_from_Juno'
      description: "Insert here the path to the julia.exe, which one you want
        to use. For example:\n In Windows:
        C:\\Users\\Julia\\AppData\\Local\\Julia-0.5.0\\bin\\julia.exe\n
        In Linux: /usr/bin/julia"
      order: 1
    ignore:
      title: 'List of ignored Lint codes'
      type: 'string'
      default: ''
      description: "Some times you want to ignore some of the lint messages.
                    Give here the ignored error codes in a format:
                    E321 W361 I171"
      order: 2
    ignorewarning:
      title: "Don't show warnings"
      type: 'boolean'
      default: false
      order: 3
    ignoreinfo:
      title: "Don't show infos"
      type: 'boolean'
      default: false
      order: 4
    showErrorcode:
      title: "Show the Error codes i.e. E321 in the message"
      type: 'boolean'
      default: true
      order: 5

  activate: ->
    require('atom-package-deps').install('linter-julia', true)
    if atom.config.get('linter-julia.julia') != 'get_from_Juno'
      julia = atom.config.get('linter-julia.julia')
    else
      julia = atom.config.get('julia-client.juliaPath')

    tempfil = tmp.tmpNameSync({ prefix:'lintserver', postfix: 'sock'})
    if process.platform == 'win32'
      global.named_pipe = '\\\\.\\pipe\\' + tempfil.split("\\").pop()
      pipetospawn = named_pipe.replace(/\\/g,"\\\\")
      jcode = "using Lint;lintserver(\"#{pipetospawn}\",\"standard-linter-v1\")"
    else
      global.named_pipe = tempfil
      jcode = "using Lint; lintserver(\"#{named_pipe}\",\"standard-linter-v1\")"

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
            ignore = atom.config.get('linter-julia.ignore').split(/\s+/)
            json_input = {
              'file': textEditor.getPath(),
              'code_str': textEditor.getText(),
              'ignore_codes': ignore,
              'ignore_warnings': atom.config.get('linter-julia.ignorewarning'),
              'ignore_info': atom.config.get('linter-julia.ignoreinfo'),
              'show_code': atom.config.get('linter-julia.showErrorcode')
            }
            connection.write JSON.stringify(json_input)
          connection.on('error',reject)
          connection.on 'data', (chunk) ->
            data.push(chunk)
          connection.on 'close', () ->
            resolve(JSON.parse(data.join("")))
