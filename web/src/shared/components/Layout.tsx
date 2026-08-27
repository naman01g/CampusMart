import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { useState } from 'react';

export function Layout() {
  const { user, logout, loading } = useAuth();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const navLinks = [
    { path: '/', label: 'Home' },
    { path: '/listings', label: 'Browse' },
    { path: '/chat', label: 'Messages', protected: true },
    { path: '/notifications', label: 'Notifications', protected: true },
    { path: '/profile', label: 'Profile', protected: true },
  ];

  const isActive = (path: string) => location.pathname === path || (path !== '/' && location.pathname.startsWith(path));

  return (
    <div className="flex flex-col min-h-screen">
      <header className="border-b border-[var(--color-border)] bg-[var(--color-surface)] sticky top-0 z-50">
        <div className="container">
          <div className="flex items-center justify-between h-16">
            <NavLink to="/" className="text-h4" style={{ color: 'var(--color-charcoal)' }}>
              CampusMart
            </NavLink>

            <nav className="flex items-center gap-8 hidden md:flex">
              {navLinks.map((link) => (
                <NavLink
                  key={link.path}
                  to={link.path}
                  className={`text-body-sm font-medium transition-colors ${
                    isActive(link.path)
                      ? 'text-[var(--color-ochre)]'
                      : 'text-[var(--color-secondary-text)] hover:text-[var(--color-primary-text)]'
                  }`}
                >
                  {link.label}
                </NavLink>
              ))}
            </nav>

            <div className="flex items-center gap-16 md:gap-24">
              {loading ? (
                <div className="w-8 h-8 rounded-full border-2 border-[var(--color-border)] border-t-[var(--color-ochre)] animate-spin" />
              ) : user ? (
                <>
                  <NavLink
                    to="/notifications"
                    className="relative text-body-sm font-medium text-[var(--color-secondary-text)] hover:text-[var(--color-primary-text)]"
                  >
                    <span className="material-symbols-outlined" data-icon="notifications">notifications</span>
                  </NavLink>
                  <NavLink
                    to="/chat"
                    className="relative text-body-sm font-medium text-[var(--color-secondary-text)] hover:text-[var(--color-primary-text)]"
                  >
                    <span className="material-symbols-outlined" data-icon="chat">chat</span>
                  </NavLink>
                  <div className="flex items-center gap-12">
                    <img
                      src={user.profileImage || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=E38F2D&color=fff`}
                      alt={user.name}
                      className="w-8 h-8 rounded-full"
                    />
                    <button
                      onClick={() => logout()}
                      className="btn btn-ghost btn-sm text-body-sm"
                    >
                      Logout
                    </button>
                  </div>
                </>
              ) : (
                <div className="flex items-center gap-12">
                  <NavLink to="/login" className="btn btn-ghost btn-sm">
                    Login
                  </NavLink>
                  <NavLink to="/register" className="btn btn-primary btn-sm">
                    Sign Up
                  </NavLink>
                </div>
              )}
            </div>

            <button
              className="md:hidden p-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Toggle menu"
            >
              ☰
            </button>
          </div>

          {mobileMenuOpen && (
            <div className="md:hidden py-16 border-t border-[var(--color-border)]">
              <div className="flex flex-col gap-16">
                {navLinks.map((link) => (
                  <NavLink
                    key={link.path}
                    to={link.path}
                    className={`text-body font-medium ${
                      isActive(link.path)
                        ? 'text-[var(--color-ochre)]'
                        : 'text-[var(--color-secondary-text)]'
                    }`}
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    {link.label}
                  </NavLink>
                ))}
                {user ? (
                  <button onClick={() => logout()} className="btn btn-secondary w-full mt-8">
                    Logout
                  </button>
                ) : (
                  <div className="flex flex-col gap-12 mt-8">
                    <NavLink to="/login" onClick={() => setMobileMenuOpen(false)} className="btn btn-outline w-full">
                      Login
                    </NavLink>
                    <NavLink to="/register" onClick={() => setMobileMenuOpen(false)} className="btn btn-primary w-full">
                      Sign Up
                    </NavLink>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </header>

      <main className="flex-1">
        <Outlet />
      </main>

      <footer className="border-t border-[var(--color-border)] bg-[var(--color-surface)] py-24">
        <div className="container">
          <div className="flex flex-col md:flex-row items-center justify-between gap-16 text-body-sm text-[var(--color-secondary-text)]">
            <p>© 2025 CampusMart. Built for students.</p>
            <div className="flex gap-24">
              <a href="#" className="hover:text-[var(--color-primary-text)]">Privacy</a>
              <a href="#" className="hover:text-[var(--color-primary-text)]">Terms</a>
              <a href="#" className="hover:text-[var(--color-primary-text)]">Support</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}