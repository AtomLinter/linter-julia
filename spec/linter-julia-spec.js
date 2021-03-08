'use babel';

import * as path from 'path';
import {
  // eslint-disable-next-line no-unused-vars
  it, fit, wait, beforeEach, afterEach,
} from 'jasmine-fix';

const { lint } = require('../lib/index.js').provideLinter();

const badFile = path.join(__dirname, 'fixtures', 'bad.jl');
const goodFile = path.join(__dirname, 'fixtures', 'good.jl');

// Julia is _slow_ to bring in StaticLint.jl, increase the timeout to 90 seconds
jasmine.getEnv().defaultTimeoutInterval = 180 * 1000;

describe('The Julia StaticLint.jl provider for Linter', () => {
  beforeEach(async () => {
    // try to avoid initial symbol step empty message
    await atom.packages.activatePackage('linter-julia');
    await atom.workspace.open(badFile);
    jasmine.clock.install();
    jasmine.clock.tick(15000);
    jasmine.clock.uninstall();
    atom.workspace.destroyActivePaneItem();
  });

  it('checks a file with syntax error and reports the correct message', async () => {
    const excerpt = 'Missing reference';
    const editor = await atom.workspace.open(badFile);
    const messages = await lint(editor);

    expect(messages.length).toBe(1);
    expect(messages[0].severity).toBe('error');
    expect(messages[0].excerpt).toBe(excerpt);
    expect(messages[0].location.file).toBe(badFile);
    expect(messages[0].location.position).toEqual([[1, 11], [1, 18]]);
  });

  it('finds nothing wrong with a valid file', async () => {
    const editor = await atom.workspace.open(goodFile);
    const messages = await lint(editor);
    expect(messages.length).toBe(0);
  });
});
