// Using atom-languageclient
const cp = require('child_process');
const path = require('path');
const { AutoLanguageClient } = require('atom-languageclient');

class JuliaLanguageClient extends AutoLanguageClient {
  getGrammarScopes() {
    return ['source.julia'];
  }

  getLanguageName() {
    return 'Julia';
  }

  getServerName() {
    return 'Juno';
  }

  startServerProcess() {
    return cp.spawn(executablePath, [path.resolve(__dirname, '..', 'script', 'StaticLint-juia-server.jl')]);
  }
}

JLC = new JuliaLanguageClient();
JLC.config = {
  jlpath: {
    type: 'string',
    default: 'julia',
    name: 'Path',
    description: 'The location of the Julia binary.',
    order: 1,
  },
};
module.exports = JLC;
