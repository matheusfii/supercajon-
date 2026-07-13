const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

// Proteção Máxima contra Crash no Apple Silicon
app.disableHardwareAcceleration();
app.commandLine.appendSwitch('no-sandbox');
app.commandLine.appendSwitch('disable-gpu-sandbox');

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    titleBarStyle: 'hiddenInset',
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      webSecurity: false // Impede que o Mac bloqueie a leitura de áudios locais
    }
  });

  win.loadFile('index.html');
}

app.whenReady().then(createWindow);

ipcMain.on('fechar-janela', () => app.quit());
ipcMain.on('minimizar-janela', () => BrowserWindow.getFocusedWindow().minimize());
ipcMain.on('maximizar-janela', () => {
  const win = BrowserWindow.getFocusedWindow();
  if (win.isMaximized()) win.unmaximize();
  else win.maximize();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});