/* ===================================
   GrowFit - Utility Functions
   날짜, 숫자, 문자열 처리
   =================================== */

// ========== 날짜/시간 ==========
function formatDate(date) {
  if (!date) return '';
  const d = new Date(date);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}.${month}.${day}`;
}

function formatTime(date) {
  if (!date) return '';
  const d = new Date(date);
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes}`;
}

function getRelativeTime(date) {
  if (!date) return '';
  const now = new Date();
  const target = new Date(date);
  const diff = now - target;
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  
  if (minutes < 1) return '방금 전';
  if (minutes < 60) return `${minutes}분 전`;
  if (hours < 24) return `${hours}시간 전`;
  if (days < 7) return `${days}일 전`;
  return formatDate(date);
}

function getDaysLeft(targetDate) {
  if (!targetDate) return null;
  const now = new Date();
  const target = new Date(targetDate);
  const days = Math.ceil((target - now) / (1000 * 60 * 60 * 24));
  
  if (days < 0) return '마감';
  if (days === 0) return '오늘';
  return `D-${days}`;
}

// ========== 숫자 ==========
function formatNumber(num) {
  if (num == null) return '0';
  return num.toLocaleString('ko-KR');
}

function formatPercent(value, total) {
  if (!total) return '0%';
  return Math.round((value / total) * 100) + '%';
}

function calculateProgress(current, total) {
  if (!total) return 0;
  return Math.min(Math.max((current / total) * 100, 0), 100);
}

// ========== 문자열 ==========
function truncateText(text, maxLength = 50) {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength) + '...';
}

function getInitials(name) {
  if (!name) return '?';
  if (/[가-힣]/.test(name)) return name.charAt(0);
  const parts = name.trim().split(' ');
  if (parts.length >= 2) return parts[0].charAt(0) + parts[1].charAt(0);
  return name.charAt(0);
}

// ========== 토스트 알림 ==========
function showToast(message, type = 'info', duration = 3000) {
  const toast = document.createElement('div');
  toast.className = `toast toast--${type}`;
  toast.textContent = message;
  
  if (!document.getElementById('toast-styles')) {
    const style = document.createElement('style');
    style.id = 'toast-styles';
    style.textContent = `
      .toast {
        position: fixed;
        bottom: 24px;
        right: 24px;
        padding: 12px 20px;
        border-radius: 8px;
        color: white;
        font-size: 14px;
        box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1);
        z-index: 9999;
        animation: slideIn 0.3s;
      }
      @keyframes slideIn {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
      }
      .toast--info { background: #3b82f6; }
      .toast--success { background: #10b981; }
      .toast--warning { background: #f59e0b; }
      .toast--error { background: #ef4444; }
    `;
    document.head.appendChild(style);
  }
  
  document.body.appendChild(toast);
  setTimeout(() => document.body.removeChild(toast), duration);
}

// ========== 전역 객체 ==========
window.GrowFitUtils = {
  formatDate,
  formatTime,
  getRelativeTime,
  getDaysLeft,
  formatNumber,
  formatPercent,
  calculateProgress,
  truncateText,
  getInitials,
  showToast,
};