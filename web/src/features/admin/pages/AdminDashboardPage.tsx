import { useState, useEffect } from 'react';
import { Card, CardContent } from '@shared/components/ui';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, getDocs, query, where, orderBy, limit } from 'firebase/firestore';

export function AdminDashboardPage() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalListings: 0,
    activeListings: 0,
    pendingReports: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const db = getFirebaseDb();
      
      const [usersSnap, listingsSnap, activeSnap, reportsSnap] = await Promise.all([
        getDocs(collection(db, 'users')),
        getDocs(collection(db, 'products')),
        getDocs(query(collection(db, 'products'), where('status', '==', 'ACTIVE'))),
        getDocs(query(collection(db, 'reports'), where('status', '==', 'pending'))),
      ]);

      setStats({
        totalUsers: usersSnap.size,
        totalListings: listingsSnap.size,
        activeListings: activeSnap.size,
        pendingReports: reportsSnap.size,
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    { label: 'Total Users', value: stats.totalUsers, icon: '👥' },
    { label: 'Total Listings', value: stats.totalListings, icon: '📦' },
    { label: 'Active Listings', value: stats.activeListings, icon: '✅' },
    { label: 'Pending Reports', value: stats.pendingReports, icon: '⚠️' },
  ];

  return (
    <div>
      <h1 className="text-h2 mb-24" style={{ color: 'var(--color-charcoal)' }}>Dashboard</h1>
      
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-16 mb-24">
        {statCards.map((stat, index) => (
          <Card key={index} padding="lg">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-body-sm text-[var(--color-secondary-text)]">{stat.label}</p>
                <p className="text-h2 mt-4" style={{ color: 'var(--color-charcoal)' }}>{stat.value}</p>
              </div>
              <span className="text-4xl">{stat.icon}</span>
            </div>
          </Card>
        ))}
      </div>

      <div className="grid lg:grid-cols-2 gap-16">
        <Card padding="lg">
          <h2 className="text-h4 mb-16" style={{ color: 'var(--color-charcoal)' }}>Quick Actions</h2>
          <div className="space-y-12">
            <a href="/admin/listings" className="btn btn-outline w-full justify-start">Manage Listings</a>
            <a href="/admin/users" className="btn btn-outline w-full justify-start">Manage Users</a>
            <a href="/admin/reports" className="btn btn-outline w-full justify-start">Review Reports</a>
          </div>
        </Card>

        <Card padding="lg">
          <h2 className="text-h4 mb-16" style={{ color: 'var(--color-charcoal)' }}>System Status</h2>
          <div className="space-y-12">
            <div className="flex items-center justify-between">
              <span className="text-body" style={{ color: 'var(--color-primary-text)' }}>Firebase Connection</span>
              <span className="text-body-sm font-medium" style={{ color: 'var(--color-success)' }}>Connected</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-body" style={{ color: 'var(--color-primary-text)' }}>Authentication</span>
              <span className="text-body-sm font-medium" style={{ color: 'var(--color-success)' }}>Active</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-body" style={{ color: 'var(--color-primary-text)' }}>Storage</span>
              <span className="text-body-sm font-medium" style={{ color: 'var(--color-success)' }}>Available</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-body" style={{ color: 'var(--color-primary-text)' }}>Messaging</span>
              <span className="text-body-sm font-medium" style={{ color: 'var(--color-success)' }}>Active</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}