const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const INSTALL = path.join(__dirname, '../install.sh');

const run = (cmd, args, opts = {}) => {
    const result = spawnSync(cmd, args, { encoding: 'utf8', ...opts });
    return { code: result.status, output: result.stdout + result.stderr };
};
// Fixture and installer git both ignore the developer's git config.
const gitEnv = { GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_NOSYSTEM: '1' };
const git = (cwd, ...args) => {
    const result = run('git', args, { cwd, env: { ...process.env, ...gitEnv, GIT_AUTHOR_NAME: 't',
        GIT_AUTHOR_EMAIL: 't@t', GIT_COMMITTER_NAME: 't', GIT_COMMITTER_EMAIL: 't@t' } });
    assert.equal(result.code, 0, result.output);
    return result.output.trim();
};

// A temporary upstream repo, config home, and PATH holding only the tools the installer may use.
function sandbox(tools) {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bilskirnir-install-'));
    const upstream = path.join(root, 'upstream');
    fs.mkdirSync(upstream);
    git(upstream, 'init', '-q', '-b', 'main');
    fs.writeFileSync(path.join(upstream, 'shell.qml'), 'v1\n');
    git(upstream, 'add', '.');
    git(upstream, 'commit', '-qm', 'v1');

    const bin = path.join(root, 'bin');
    fs.mkdirSync(bin);
    for (const name of ['git', 'sh', 'grep', 'mkdir', 'dirname']) {
        const found = run('sh', ['-c', `command -v ${name}`]).output.trim();
        fs.symlinkSync(found, path.join(bin, name));
    }
    for (const [name, body] of Object.entries(tools)) {
        fs.writeFileSync(path.join(bin, name), `#!/bin/sh\n${body}\n`, { mode: 0o755 });
    }
    // GitHub origins resolve to the local upstream, so upgrades never reach the network.
    const github = ['git@github.com:drucedev/bilskirnir.git', 'https://github.com/drucedev/bilskirnir'];
    const env = { ...gitEnv, PATH: bin, HOME: root, XDG_CONFIG_HOME: path.join(root, 'config'),
        BILSKIRNIR_REPO: upstream, GIT_CONFIG_COUNT: String(github.length) };
    github.forEach((url, i) => {
        env[`GIT_CONFIG_KEY_${i}`] = `url.${upstream}.insteadOf`;
        env[`GIT_CONFIG_VALUE_${i}`] = url;
    });
    const target = path.join(env.XDG_CONFIG_HOME, 'quickshell/bilskirnir');
    const install = () => run(path.join(bin, 'sh'), [INSTALL], { env, cwd: root });
    return { root, upstream, target, install, cleanup: () => fs.rmSync(root, { recursive: true, force: true }) };
}

function rejects(box, pattern) {
    const result = box.install();
    assert.notEqual(result.code, 0, result.output);
    assert.match(result.output, pattern);
}

const allTools = {
    qs: 'true', nmcli: 'true', ghostty: 'true', btop: 'true',
    'fc-list': 'echo "JetBrainsMono Nerd Font"',
};

test('fresh install clones into the Quickshell config dir and re-running pulls', () => {
    const box = sandbox(allTools);
    try {
        const first = box.install();
        assert.equal(first.code, 0, first.output);
        assert.equal(fs.readFileSync(path.join(box.target, 'shell.qml'), 'utf8'), 'v1\n');
        assert.doesNotMatch(first.output, /missing/i);
        assert.match(first.output, /qs --no-duplicate -c bilskirnir/);

        fs.writeFileSync(path.join(box.upstream, 'shell.qml'), 'v2\n');
        git(box.upstream, 'commit', '-qam', 'v2');
        const second = box.install();
        assert.equal(second.code, 0, second.output);
        assert.equal(fs.readFileSync(path.join(box.target, 'shell.qml'), 'utf8'), 'v2\n');
    } finally {
        box.cleanup();
    }
});

test('an existing directory that is not a bilskirnir checkout is left untouched', () => {
    const box = sandbox(allTools);
    try {
        fs.mkdirSync(box.target, { recursive: true });
        fs.writeFileSync(path.join(box.target, 'shell.qml'), 'mine\n');
        const result = box.install();
        assert.notEqual(result.code, 0);
        assert.match(result.output, /not a bilskirnir checkout/);
        assert.equal(fs.readFileSync(path.join(box.target, 'shell.qml'), 'utf8'), 'mine\n');
    } finally {
        box.cleanup();
    }
});

test('a directory nested in a bilskirnir checkout, or a clone from another host, is not ours', () => {
    const box = sandbox(allTools);
    try {
        const outer = path.dirname(box.target);
        fs.mkdirSync(box.target, { recursive: true });
        git(outer, 'init', '-q');
        git(outer, 'remote', 'add', 'origin', box.upstream);
        rejects(box, /not a bilskirnir checkout/);
        fs.rmSync(path.join(outer, '.git'), { recursive: true });
        fs.rmdirSync(box.target);

        git(outer, 'clone', '-q', box.upstream, box.target);
        git(box.target, 'remote', 'set-url', 'origin', 'https://gitlab.com/drucedev/bilskirnir.git');
        rejects(box, /not a bilskirnir checkout/);
        for (const url of ['git@github.com:drucedev/bilskirnir.git', 'https://github.com/drucedev/bilskirnir']) {
            git(box.target, 'remote', 'set-url', 'origin', url);
            const result = box.install();
            assert.equal(result.code, 0, result.output);
            assert.match(result.output, /Updated/);
        }
    } finally {
        box.cleanup();
    }
});

test('upgrades only fast-forward main', () => {
    const box = sandbox(allTools);
    try {
        assert.equal(box.install().code, 0);
        git(box.target, 'switch', '-q', '-c', 'feature');
        rejects(box, /not on main/);
    } finally {
        box.cleanup();
    }
});

test('missing dependencies are reported without failing the install', () => {
    const { btop, 'fc-list': _, ...tools } = allTools;
    // Only a suffixed sibling family is installed, which common/Style.qml does not request.
    const box = sandbox({ ...tools, 'fc-list': 'echo "JetBrainsMono Nerd Font Mono,JetBrainsMono NFM"' });
    try {
        const result = box.install();
        assert.equal(result.code, 0, result.output);
        assert.match(result.output, /missing: btop/i);
        assert.match(result.output, /missing: JetBrainsMono Nerd Font/i);
        assert.doesNotMatch(result.output, /missing: (qs|nmcli|ghostty)\b/);
    } finally {
        box.cleanup();
    }
});
