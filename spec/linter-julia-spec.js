'use babel';

import * as path from 'path';
import {
  // eslint-disable-next-line no-unused-vars
  it, fit, wait, beforeEach, afterEach,
} from 'jasmine-fix';

const { lint } = require('../lib/index.js').provideLinter();

const badFile = path.join(__dirname, 'fixtures', 'bad.jl');
const goodFile = path.join(__dirname, 'fixtures', 'good.jl');

describe('The Julia Lint.jl provider for Linter', () => {
  beforeEach(async () => {
    atom.workspace.destroyActivePaneItem();
    await atom.packages.activatePackage('linter-julia');
  });

  it('checks a file with syntax error and reports the correct message', async () => {
    const excerpt = 'question: use of undeclared symbol';
    const editor = await atom.workspace.open(badFile);
    const messages = await lint(editor);

    expect(messages.length).toBe(1);
    expect(messages[0].severity).toBe('error');
    expect(messages[0].excerpt).toBe(excerpt);
    expect(messages[0].location.file).toBe(badFile);
    // NOTE: This is invalid! Bug in Lint.jl
    expect(messages[0].location.position).toEqual([[1, 0], [1, 80]]);
  });

  it('finds nothing wrong with a valid file', async () => {
    const editor = await atom.workspace.open(goodFile);
    const messages = await lint(editor);
    expect(messages.length).toBe(0);
  });
});
