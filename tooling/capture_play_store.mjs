import { spawn } from 'node:child_process';
import { mkdir, writeFile } from 'node:fs/promises';

const chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const outputDir = 'screenshots/play-store';
const chromePort = 19223;
const appPort = 43117;
const profileDir = `/tmp/super-cajon-play-store-chrome-${Date.now()}`;

await mkdir(outputDir, { recursive: true });

const server = spawn('python3', ['-m', 'http.server', String(appPort), '--directory', 'build/web'], { stdio: 'ignore' });
const chrome = spawn(chromePath, [
  '--headless=new',
  '--hide-scrollbars',
  '--mute-audio',
  '--no-first-run',
  '--disable-default-apps',
  `--remote-debugging-port=${chromePort}`,
  '--disable-application-cache',
  `--user-data-dir=${profileDir}`,
], { stdio: 'ignore' });

const sleep = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

async function waitForChrome() {
  for (let attempt = 0; attempt < 60; attempt++) {
    try {
      const response = await fetch(`http://127.0.0.1:${chromePort}/json/version`);
      if (response.ok) return;
    } catch (_) {}
    await sleep(250);
  }
  throw new Error('Chrome não iniciou a tempo.');
}

await waitForChrome();
const target = await fetch(`http://127.0.0.1:${chromePort}/json/new?about:blank`, { method: 'PUT' }).then(response => response.json());
const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener('open', resolve, { once: true });
  socket.addEventListener('error', reject, { once: true });
});

let commandId = 0;
const pending = new Map();
socket.addEventListener('message', event => {
  const message = JSON.parse(event.data);
  if (!message.id || !pending.has(message.id)) return;
  const { resolve, reject } = pending.get(message.id);
  pending.delete(message.id);
  message.error ? reject(new Error(message.error.message)) : resolve(message.result);
});

function command(method, params = {}) {
  const id = ++commandId;
  socket.send(JSON.stringify({ id, method, params }));
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
}

await command('Page.enable');
await command('Emulation.setDeviceMetricsOverride', {
  width: 432,
  height: 768,
  deviceScaleFactor: 2.5,
  mobile: true,
  screenWidth: 432,
  screenHeight: 768,
});
await command('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });

async function navigate(wait = 5200) {
  await command('Page.navigate', {
    url: `http://127.0.0.1:${appPort}/?shot=${Date.now()}`,
  });
  await sleep(wait);
}

async function screenshot(filename) {
  const result = await command('Page.captureScreenshot', { format: 'png', fromSurface: true });
  await writeFile(`${outputDir}/${filename}`, Buffer.from(result.data, 'base64'));
}

try {
  await navigate(2400);
  await screenshot('01-splash.png');

  if (process.env.ONLY_SPLASH !== '1') {
    await navigate();
    await screenshot('02-player.png');

  await command('Input.dispatchMouseEvent', {
    type: 'mouseWheel',
    x: 216,
    y: 650,
    deltaX: 0,
    deltaY: 560,
  });
  await sleep(900);
  await screenshot('03-biblioteca.png');

    await navigate();
    await command('Input.dispatchMouseEvent', {
    type: 'mousePressed',
    x: 330,
    y: 710,
    button: 'left',
    clickCount: 1,
  });
  await command('Input.dispatchMouseEvent', {
    type: 'mouseReleased',
    x: 330,
    y: 710,
    button: 'left',
    clickCount: 1,
  });
  await sleep(1500);
  await screenshot('04-paywall.png');

  await navigate();
  await command('Input.dispatchMouseEvent', {
    type: 'mousePressed',
    x: 389,
    y: 43,
    button: 'left',
    clickCount: 1,
  });
  await command('Input.dispatchMouseEvent', {
    type: 'mouseReleased',
    x: 389,
    y: 43,
    button: 'left',
    clickCount: 1,
  });
  await sleep(1200);
    await screenshot('05-ajustes.png');
  }
} finally {
  socket.close();
  chrome.kill('SIGTERM');
  server.kill('SIGTERM');
}
