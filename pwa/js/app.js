(function () {
  'use strict';

  const $ = (id) => document.getElementById(id);

  const settings = {
    url: localStorage.getItem('dsh_url') || '',
    user: localStorage.getItem('dsh_user') || '',
    pass: ''
  };

  const els = {
    connectView: $('connectView'),
    frameView: $('frameView'),
    dshFrame: $('dshFrame'),
    connectBtn: $('connectBtn'),
    settingsBtn: $('settingsBtn'),
    themeBtn: $('themeBtn'),
    settingsModal: $('settingsModal'),
    serverUrl: $('serverUrl'),
    serverUser: $('serverUser'),
    serverPass: $('serverPass'),
    cancelBtn: $('cancelBtn'),
    saveBtn: $('saveBtn'),
    status: $('status')
  };

  function applyTheme(theme) {
    document.documentElement.dataset.theme = theme;
    els.themeBtn.textContent = theme === 'light' ? '深色' : '浅色';
    localStorage.setItem('dsh_theme', theme);
  }

  function toggleTheme() {
    const current = document.documentElement.dataset.theme === 'light' ? 'light' : 'dark';
    applyTheme(current === 'light' ? 'dark' : 'light');
  }

  function initTheme() {
    const saved = localStorage.getItem('dsh_theme');
    const prefersLight = window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches;
    applyTheme(saved || (prefersLight ? 'light' : 'dark'));
  }

  function showSettings() {
    els.serverUrl.value = settings.url;
    els.serverUser.value = settings.user;
    els.serverPass.value = '';
    els.settingsModal.classList.remove('hidden');
  }

  function hideSettings() {
    els.settingsModal.classList.add('hidden');
  }

  function saveSettings() {
    const url = els.serverUrl.value.trim();
    const user = els.serverUser.value.trim();
    const pass = els.serverPass.value;

    if (url) {
      settings.url = url;
      settings.user = user || 'dsh';
      if (pass) settings.pass = pass;
      localStorage.setItem('dsh_url', settings.url);
      localStorage.setItem('dsh_user', settings.user);
    }

    hideSettings();
    connect();
  }

  async function dohResolve(host) {
    const q = encodeURIComponent(host);
    const url = 'https://dns.alidns.com/resolve?name=' + q + '&type=TXT';
    const resp = await fetch(url, { headers: { 'Accept': 'application/dns-json' } });
    if (!resp.ok) return null;
    const data = await resp.json();
    const answers = data.Answer || [];
    for (const a of answers) {
      if ((a.type === 5 || a.type === 16) && a.data && a.data.includes('trycloudflare.com')) {
        return a.data.replace(/\.$/, '').trim();
      }
    }
    return null;
  }

  async function resolveTarget(input) {
    let url = input.trim();
    if (!url) return null;

    // 已经是完整地址
    if (/^https?:\/\//i.test(url)) {
      return url;
    }

    // 裸域名：走 DoH 自动发现当前隧道
    const host = url.replace(/^\/+/, '').replace(/\/+$/, '');
    els.status.textContent = '自动发现中…';
    const tunnel = await dohResolve(host);
    if (tunnel) {
      return 'https://' + tunnel + '/mobile';
    }
    return null;
  }

  async function connect() {
    if (!settings.url) {
      els.status.textContent = '请先配置服务器地址';
      showSettings();
      return;
    }

    const target = await resolveTarget(settings.url);
    if (!target) {
      els.status.textContent = '自动发现失败，请填写完整 https:// 地址';
      return;
    }

    // 先通过弹窗完成一次 Basic Auth，让浏览器缓存该域名的登录凭证
    const authWindow = window.open(target, '_blank');
    if (authWindow) {
      els.status.textContent = '请在弹窗中完成登录，然后回到这里';
      setTimeout(() => {
        try { authWindow.close(); } catch (e) {}
        loadFrame(target);
      }, 3000);
    } else {
      loadFrame(target);
    }
  }

  function loadFrame(target) {
    els.connectView.classList.add('hidden');
    els.frameView.classList.remove('hidden');
    els.dshFrame.src = target;
    els.status.textContent = '';
  }

  els.connectBtn.addEventListener('click', connect);
  els.settingsBtn.addEventListener('click', showSettings);
  els.themeBtn.addEventListener('click', toggleTheme);
  els.cancelBtn.addEventListener('click', hideSettings);
  els.saveBtn.addEventListener('click', saveSettings);

  initTheme();

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./sw.js').catch(function () {});
  }

  if (settings.url) {
    els.status.textContent = '已配置：' + settings.url;
  }
})();
