(function () {
  'use strict';

  const $ = (id) => document.getElementById(id);

  const settings = {
    url: localStorage.getItem('dsh_url') || '',
    user: localStorage.getItem('dsh_user') || '',
    pass: localStorage.getItem('dsh_pass') || ''
  };

  const els = {
    connectView: $('connectView'),
    frameView: $('frameView'),
    dshFrame: $('dshFrame'),
    connectBtn: $('connectBtn'),
    settingsBtn: $('settingsBtn'),
    settingsModal: $('settingsModal'),
    serverUrl: $('serverUrl'),
    serverUser: $('serverUser'),
    serverPass: $('serverPass'),
    cancelBtn: $('cancelBtn'),
    saveBtn: $('saveBtn'),
    status: $('status')
  };

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
      if (pass) localStorage.setItem('dsh_pass', settings.pass);
    }

    hideSettings();
    connect();
  }

  function connect() {
    if (!settings.url) {
      els.status.textContent = '请先配置服务器地址';
      showSettings();
      return;
    }

    // 先通过弹窗完成一次 Basic Auth，让浏览器缓存该域名的登录凭证
    const authWindow = window.open(settings.url, '_blank');
    if (authWindow) {
      els.status.textContent = '请在弹窗中完成登录，然后回到这里';
      setTimeout(() => {
        authWindow.close();
        loadFrame();
      }, 3000);
    } else {
      // 弹窗被拦截时，直接在当前页尝试 iframe（可能要求手动登录）
      loadFrame();
    }
  }

  function loadFrame() {
    els.connectView.classList.add('hidden');
    els.frameView.classList.remove('hidden');
    els.dshFrame.src = settings.url;
    els.status.textContent = '';
  }

  els.connectBtn.addEventListener('click', connect);
  els.settingsBtn.addEventListener('click', showSettings);
  els.cancelBtn.addEventListener('click', hideSettings);
  els.saveBtn.addEventListener('click', saveSettings);

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./sw.js').catch(function () {});
  }

  if (settings.url) {
    els.status.textContent = '已配置：' + settings.url;
  }
})();
