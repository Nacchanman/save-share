import { cp, mkdir, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const dist = path.join(root, 'dist');

await rm(dist, { recursive: true, force: true });
await mkdir(path.join(dist, 'src'), { recursive: true });

await cp(path.join(root, 'index.html'), path.join(dist, 'index.html'));
await cp(path.join(root, 'src', 'main.js'), path.join(dist, 'src', 'main.js'));
await cp(path.join(root, 'src', 'styles.css'), path.join(dist, 'src', 'styles.css'));

if (existsSync(path.join(root, 'assets'))) {
  await cp(path.join(root, 'assets'), path.join(dist, 'assets'), { recursive: true });
}

console.log('Built iOS web bundle into dist/');
