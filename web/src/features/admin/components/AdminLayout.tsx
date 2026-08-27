import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button } from '@shared/components/ui';

export function AdminLayout() {
  const { user, logout } = useAuth();
  const location = useLocation();

  const navItems = [
    { path: '/admin/dashboard', label: 'Dashboard' },
    { path: '/admin/listings', label: 'Listings' },
    { path: '/admin/users', label: 'Users' },
    { path: '/admin/reports', label: 'Reports' },
  ];

  const isActive = (path: string) => location.pathname === path;

  return (
    <div className="flex min-h-screen bg-[var(--color-warm-cream)]">
      <aside className="w-64 bg-[var(--color-charcoal)] text-white flex flex-col">
        <div className="p-24 border-b border-white/10">
          <h1 className="text-h4">CampusMart Admin</h1>
        </div>
        <nav className="flex-1 p-16">
          <ul className="space-y-4">
            {navItems.map(item => (
              <li key={item.path}>
                <NavLink
                  to={item.path}
                  className={`px-12 py-8 rounded-lg text-body-sm font-medium transition-colors ${
                    isActive(item.path)
                      ? 'bg-[var(--color-ochre)]'
                      : 'text-white/70 hover:bg-white/10'
                  }`}
                >
                  {item.label}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
        <div className="p-16 border-t border-white/10">
          <div className="flex items-center gap-12 mb-12">
            <img
              src={user?.profileImage || `https://ui-avatars.com/api/?name=${encodeURIComponent(user?.name || 'Admin')}&background=E38F2D&color=fff`}
              alt={user?.name || 'Admin'}
              className="w-8 h-8 rounded-full"
            />
            <div className="flex-1 min-w-0">
              <p className="text-body-sm font-medium truncate">{user?.name}</p>
              <p className="text-caption text-white/50 truncate">{user?.email}</p>
            </div>
          </div>
          <Button variant="ghost" onClick={() => logout()} className="w-full justify-start text-white/70 hover:text-white">
            Logout
          </Button>
        </div>
      </aside>

      <main className="flex-1 p-24 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}