const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const fixtures = 'test/quickshell/';

function run(command, args, cwd, capture = false) {
    const result = spawnSync(command, args, {
        cwd, stdio: ['ignore', capture ? 'pipe' : 'inherit', 'inherit'],
    });
    if (result.error) throw result.error;
    if (result.signal) throw new Error(`${command} terminated by ${result.signal}`);
    if (capture) {
        if (result.status !== 0) throw new Error(`${command} exited with status ${result.status}`);
        return result.stdout;
    }
    if (result.status !== 0) process.exitCode = 1;
}

function gitPaths(args) {
    return [...new Set(run('git', [...args, '-z'], root, true).toString().split('\0').filter(Boolean))];
}

function scratch(callback) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'bilskirnir-quality-'));
    try {
        callback(dir);
    } finally {
        fs.rmSync(dir, { recursive: true, force: true });
    }
}

function lintQml(dir, files, imports) {
    if (files.length === 0) return;
    // Qt 6.12 misreads -i qmldir when run from the directory containing it.
    const parent = path.dirname(dir);
    const relative = file => path.join(path.basename(dir), file);
    run('qmllint', ['-W', '0', ...imports, '-i', relative('qmldir'), ...files.map(relative)], parent);
}

function lint(dir, qml, shell) {
    if (qml.length) {
        const searchPath = process.env.BILSKIRNIR_QML_IMPORT_PATH;
        if (!searchPath) throw new Error('Set BILSKIRNIR_QML_IMPORT_PATH or enter the Nix dev shell.');
        const imports = searchPath.split(path.delimiter).filter(Boolean).flatMap(p => ['-I', path.resolve(p)]);
        const tests = qml.filter(file => file.startsWith(fixtures));
        lintQml(dir, qml.filter(file => !file.startsWith(fixtures)), imports);
        if (tests.length) scratch(copy => {
            // Match the test runner: fixtures import production components through ".".
            for (const file of fs.readdirSync(dir)) {
                if (/\.(qml|js)$|^(qmldir|\.qmllint\.ini)$/.test(file)) {
                    fs.copyFileSync(path.join(dir, file), path.join(copy, file));
                }
            }
            for (const file of tests) fs.copyFileSync(path.join(dir, file), path.join(copy, path.basename(file)));
            lintQml(copy, tests.map(file => path.basename(file)), imports);
        });
    }
    if (shell.length) run('shellcheck', ['--', ...shell], dir);
}

function format(dir, qml, shell, fix) {
    for (const file of qml) {
        const args = ['--settings', '.qmlformat.ini', `./${file}`];
        if (fix) {
            run('qmlformat', ['--inplace', ...args], dir);
        } else if (!run('qmlformat', args, dir, true).equals(fs.readFileSync(path.join(dir, file)))) {
            console.error(`${file}: needs qmlformat`);
            process.exitCode = 1;
        }
    }
    if (shell.length) run('shfmt', [fix ? '-w' : '-d', '--', ...shell], dir);
}

const isQml = file => file.endsWith('.qml');
const isShell = file => file.endsWith('.sh') || file === '.githooks/pre-commit';

function check(mode, dir, files) {
    const qml = files.filter(isQml);
    const shell = files.filter(isShell);
    if (mode !== 'lint') format(dir, qml, shell, mode === 'fmt');
    if (mode === 'lint' || mode === 'check') lint(dir, qml, shell);
}

try {
    const mode = process.argv[2];
    if (mode === 'staged') {
        // Deletions and rename sources count: removing a component can break its consumers.
        const changed = gitPaths(['diff', '--cached', '--name-only', '--no-renames']);
        const relevant = file => /\.(qml|sh|js)$|^qmldir$|^\.qml(format|lint)\.ini$/.test(file)
            || file === '.githooks/pre-commit';
        if (changed.some(relevant)) {
            // Check staged content, unconverted, even when the working tree has other edits.
            scratch(dir => {
                run('git', ['-c', 'core.autocrlf=false', 'checkout-index', '--all', `--prefix=${dir}/`], root, true);
                const staged = gitPaths(['ls-files', '--cached']);
                const formatAll = changed.includes('.qmlformat.ini');
                const toFormat = staged.filter(file => formatAll || changed.includes(file));
                // Lint is cross-file, so lint every staged QML and shell file.
                format(dir, toFormat.filter(isQml), toFormat.filter(isShell), false);
                lint(dir, staged.filter(isQml), staged.filter(isShell));
            });
        }
    } else if (['check', 'fmt-check', 'fmt', 'lint'].includes(mode)) {
        const files = gitPaths(['ls-files', '--cached', '--others', '--exclude-standard']);
        check(mode, root, files.filter(file => fs.existsSync(path.join(root, file))));
    } else {
        throw new Error('Usage: node scripts/quality.cjs {check|fmt-check|fmt|lint|staged}');
    }
} catch (error) {
    console.error(error.message);
    process.exitCode = 1;
}
