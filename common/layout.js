/* ===================================
   GrowFit - Layout JavaScript
   Header, Sidebar 동작 제어
   =================================== */

// ========== 전역 상태 관리 ==========
const LayoutState = {
  sidebarOpen: true,
  currentPage: '',
  notifications: [],
};

// ========== 초기화 ==========
document.addEventListener('DOMContentLoaded', function() {
  initLayout();
  initSidebar();
  initHeader();
  initResponsive();
  setActivePage();
});

// ========== 레이아웃 초기화 ==========
function initLayout() {
  const path = window.location.pathname;
  const page = path.split('/').pop().replace('.html', '');
  LayoutState.currentPage = page || 'dashboard';
  
  console.log('GrowFit Layout Initialized - Page:', LayoutState.currentPage);
}

// ========== 사이드바 초기화 ==========
function initSidebar() {
  const sidebar = document.querySelector('.sidebar');
  if (!sidebar) return;
  
  // 모바일에서 초기 상태
  if (window.innerWidth <= 768) {
    LayoutState.sidebarOpen = false;
    sidebar.classList.remove('sidebar--open');
  }
  
  // 메뉴 클릭 이벤트
  const menuLinks = document.querySelectorAll('.sidebar__menu-link');
  menuLinks.forEach(link => {
    link.addEventListener('click', function(e) {
      if (window.innerWidth <= 768) {
        toggleSidebar();
      }
    });
  });
}

// ========== 헤더 초기화 ==========
function initHeader() {
  const menuToggle = document.getElementById('menuToggle');
  if (menuToggle) {
    menuToggle.addEventListener('click', toggleSidebar);
  }
  
  const notificationBtn = document.getElementById('notificationBtn');
  if (notificationBtn) {
    notificationBtn.addEventListener('click', toggleNotifications);
  }
  
  const profileBtn = document.getElementById('profileBtn');
  if (profileBtn) {
    profileBtn.addEventListener('click', toggleProfileMenu);
  }
  
  document.addEventListener('click', function(e) {
    if (!e.target.closest('.header__icon-button') && 
        !e.target.closest('.header__profile')) {
      closeAllDropdowns();
    }
  });
}

// ========== 반응형 처리 ==========
function initResponsive() {
  let resizeTimer;
  
  window.addEventListener('resize', function() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function() {
      const sidebar = document.querySelector('.sidebar');
      
      if (window.innerWidth > 768) {
        LayoutState.sidebarOpen = true;
        sidebar?.classList.add('sidebar--open');
      } else {
        LayoutState.sidebarOpen = false;
        sidebar?.classList.remove('sidebar--open');
      }
    }, 250);
  });
}

// ========== 활성 페이지 표시 ==========
function setActivePage() {
  const currentPage = LayoutState.currentPage;
  const menuLinks = document.querySelectorAll('.sidebar__menu-link');
  
  menuLinks.forEach(link => {
    const href = link.getAttribute('href');
    if (href && href.includes(currentPage)) {
      link.classList.add('sidebar__menu-link--active');
    } else {
      link.classList.remove('sidebar__menu-link--active');
    }
  });
}

// ========== 사이드바 토글 ==========
function toggleSidebar() {
  const sidebar = document.querySelector('.sidebar');
  if (!sidebar) return;
  
  LayoutState.sidebarOpen = !LayoutState.sidebarOpen;
  
  if (LayoutState.sidebarOpen) {
    sidebar.classList.add('sidebar--open');
  } else {
    sidebar.classList.remove('sidebar--open');
  }
}

// ========== 알림 토글 ==========
function toggleNotifications() {
  const notificationBtn = document.getElementById('notificationBtn');
  const dropdown = document.getElementById('notificationDropdown');
  
  if (!dropdown) {
    createNotificationDropdown();
    return;
  }
  
  const isActive = notificationBtn.classList.contains('header__icon-button--active');
  closeAllDropdowns();
  
  if (!isActive) {
    notificationBtn.classList.add('header__icon-button--active');
    dropdown.classList.add('dropdown--open');
  }
}

// ========== 프로필 메뉴 토글 ==========
function toggleProfileMenu() {
  const profileBtn = document.getElementById('profileBtn');
  const dropdown = document.getElementById('profileDropdown');
  
  if (!dropdown) {
    createProfileDropdown();
    return;
  }
  
  const isActive = profileBtn.classList.contains('header__profile--active');
  closeAllDropdowns();
  
  if (!isActive) {
    profileBtn.classList.add('header__profile--active');
    dropdown.classList.add('dropdown--open');
  }
}

// ========== 모든 드롭다운 닫기 ==========
function closeAllDropdowns() {
  const notificationBtn = document.getElementById('notificationBtn');
  const notificationDropdown = document.getElementById('notificationDropdown');
  
  if (notificationBtn) {
    notificationBtn.classList.remove('header__icon-button--active');
  }
  if (notificationDropdown) {
    notificationDropdown.classList.remove('dropdown--open');
  }
  
  const profileBtn = document.getElementById('profileBtn');
  const profileDropdown = document.getElementById('profileDropdown');
  
  if (profileBtn) {
    profileBtn.classList.remove('header__profile--active');
  }
  if (profileDropdown) {
    profileDropdown.classList.remove('dropdown--open');
  }
}

// ========== 알림 드롭다운 생성 ==========
function createNotificationDropdown() {
  const notificationBtn = document.getElementById('notificationBtn');
  if (!notificationBtn) return;
  
  const dropdown = document.createElement('div');
  dropdown.id = 'notificationDropdown';
  dropdown.className = 'dropdown dropdown--notifications';
  dropdown.innerHTML = `
    <div class="dropdown__header">
      <h3>알림</h3>
      <button class="btn btn--sm btn--outline">모두 읽음</button>
    </div>
    <div class="dropdown__body">
      <div class="notification-item">
        <div class="notification-item__icon notification-item__icon--warning">⚠️</div>
        <div class="notification-item__content">
          <p class="notification-item__title">과제 제출 마감 임박</p>
          <p class="notification-item__time">2시간 전</p>
        </div>
      </div>
    </div>
    <div class="dropdown__footer">
      <a href="#" class="dropdown__link">모든 알림 보기</a>
    </div>
  `;
  
  notificationBtn.parentElement.style.position = 'relative';
  notificationBtn.parentElement.appendChild(dropdown);
  
  setTimeout(() => {
    notificationBtn.classList.add('header__icon-button--active');
    dropdown.classList.add('dropdown--open');
  }, 10);
}

// ========== 프로필 드롭다운 생성 ==========
function createProfileDropdown() {
  const profileBtn = document.getElementById('profileBtn');
  if (!profileBtn) return;
  
  const dropdown = document.createElement('div');
  dropdown.id = 'profileDropdown';
  dropdown.className = 'dropdown dropdown--profile';
  dropdown.innerHTML = `
    <div class="dropdown__body">
      <a href="#" class="dropdown__item">
        <span class="dropdown__item-icon">👤</span>
        <span>내 프로필</span>
      </a>
      <a href="settings.html" class="dropdown__item">
        <span class="dropdown__item-icon">⚙️</span>
        <span>설정</span>
      </a>
      <div class="divider"></div>
      <a href="#" class="dropdown__item dropdown__item--danger" onclick="handleLogout(event)">
        <span class="dropdown__item-icon">🚪</span>
        <span>로그아웃</span>
      </a>
    </div>
  `;
  
  profileBtn.parentElement.style.position = 'relative';
  profileBtn.parentElement.appendChild(dropdown);
  
  setTimeout(() => {
    profileBtn.classList.add('header__profile--active');
    dropdown.classList.add('dropdown--open');
  }, 10);
}

// ========== 로그아웃 처리 ==========
function handleLogout(event) {
  event.preventDefault();
  if (confirm('로그아웃 하시겠습니까?')) {
    console.log('Logging out...');
    localStorage.clear();
    window.location.href = '/login.html';
  }
}

// ========== 드롭다운 스타일 ==========
if (!document.getElementById('dropdown-styles')) {
  const style = document.createElement('style');
  style.id = 'dropdown-styles';
  style.textContent = `
    .dropdown {
      position: absolute;
      top: calc(100% + 8px);
      right: 0;
      min-width: 280px;
      background: var(--background);
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      box-shadow: var(--shadow-xl);
      opacity: 0;
      visibility: hidden;
      transform: translateY(-10px);
      transition: all 0.2s;
      z-index: var(--z-dropdown);
    }
    .dropdown--open {
      opacity: 1;
      visibility: visible;
      transform: translateY(0);
    }
    .dropdown__header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 1rem;
      border-bottom: 1px solid var(--border);
    }
    .dropdown__body {
      max-height: 320px;
      overflow-y: auto;
    }
    .dropdown__item {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      color: var(--text-primary);
      text-decoration: none;
      transition: background 0.2s;
    }
    .dropdown__item:hover {
      background: var(--gray-50);
    }
    .dropdown__item--danger {
      color: var(--error);
    }
    .notification-item {
      display: flex;
      gap: 0.75rem;
      padding: 1rem;
      border-bottom: 1px solid var(--border);
    }
    .notification-item__icon {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .notification-item__icon--warning { background: #fef3c7; }
  `;
  document.head.appendChild(style);
}