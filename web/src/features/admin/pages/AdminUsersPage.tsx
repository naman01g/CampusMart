import { useState, useEffect } from 'react';
import { Card, CardContent, Badge, Button } from '@shared/components/ui';
import { User, UserRole, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, getDocs, updateDoc, doc, limit, startAfter, DocumentSnapshot } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function AdminUsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentSnapshot | null>(null);
  const [roleFilter, setRoleFilter] = useState<UserRole | 'ALL'>('ALL');
  const [verifiedFilter, setVerifiedFilter] = useState<'ALL' | 'verified' | 'unverified'>('ALL');

  useEffect(() => {
    fetchUsers(true);
  }, [roleFilter, verifiedFilter]);

  const fetchUsers = async (reset = false) => {
    if (reset) {
      setLoading(true);
      setLastDoc(null);
      setUsers([]);
      setHasMore(true);
    } else {
      setLoadingMore(true);
    }

    try {
      const db = getFirebaseDb();
      let q = query(
        collection(db, 'users'),
        orderBy('createdAt', 'desc'),
        limit(20)
      );

      if (roleFilter !== 'ALL') {
        q = query(q, where('role', '==', roleFilter));
      }

      if (verifiedFilter !== 'ALL') {
        q = query(q, where('isVerified', '==', verifiedFilter === 'verified'));
      }

      if (lastDoc) {
        q = query(q, startAfter(lastDoc));
      }

      const snapshot = await getDocs(q);
      const newUsers = snapshot.docs.map(doc => ({ uid: doc.id, ...doc.data() } as User));
      
      if (reset) {
        setUsers(newUsers);
      } else {
        setUsers(prev => [...prev, ...newUsers]);
      }
      
      setLastDoc(snapshot.docs[snapshot.docs.length - 1] || null);
      setHasMore(newUsers.length === 20);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  const handleRoleChange = async (uid: string, newRole: UserRole) => {
    try {
      const db = getFirebaseDb();
      await updateDoc(doc(db, 'users', uid), { role: newRole, updatedAt: new Date() });
      setUsers(prev => prev.map(u => u.uid === uid ? { ...u, role: newRole } : u));
    } catch (error) {
      console.error('Error updating role:', error);
    }
  };

  const handleVerify = async (uid: string, verified: boolean) => {
    try {
      const db = getFirebaseDb();
      await updateDoc(doc(db, 'users', uid), { isVerified: verified, updatedAt: new Date() });
      setUsers(prev => prev.map(u => u.uid === uid ? { ...u, isVerified: verified } : u));
    } catch (error) {
      console.error('Error updating verification:', error);
    }
  };

  if (loading) {
    return (
      <div>
        <h1 className="text-h2 mb-24" style={{ color: 'var(--color-charcoal)' }}>Manage Users</h1>
        <div className="space-y-12">
          {[...Array(4)].map((_, i) => (
            <Card key={i} padding="md">
              <div className="flex gap-12 animate-pulse">
                <div className="w-12 h-12 rounded-full bg-[var(--color-border)]" />
                <div className="flex-1">
                  <div className="h-6 bg-[var(--color-border)] rounded w-1/2 mb-8" />
                  <div className="h-4 bg-[var(--color-border)] rounded w-1/3" />
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-24">
        <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Manage Users</h1>
        <div className="flex gap-8">
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value as UserRole | 'ALL')}
            className="input w-auto"
          >
            <option value="ALL">All Roles</option>
            <option value="student">Student</option>
            <option value="admin">Admin</option>
          </select>
          <select
            value={verifiedFilter}
            onChange={(e) => setVerifiedFilter(e.target.value as 'ALL' | 'verified' | 'unverified')}
            className="input w-auto"
          >
            <option value="ALL">All</option>
            <option value="verified">Verified</option>
            <option value="unverified">Unverified</option>
          </select>
        </div>
      </div>

      {users.length === 0 ? (
        <Card padding="lg" className="text-center py-24">
          <div className="text-6xl mb-12">👥</div>
          <h3 className="text-h3 mb-8" style={{ color: 'var(--color-charcoal)' }}>No users found</h3>
        </Card>
      ) : (
        <>
          <div className="space-y-12">
            {users.map(user => (
              <Card key={user.uid} padding="md">
                <div className="flex gap-16">
                  <img
                    src={user.profileImage || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=E38F2D&color=fff`}
                    alt={user.name}
                    className="w-12 h-12 rounded-full"
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-12 mb-4">
                      <h3 className="text-body font-medium truncate" style={{ color: 'var(--color-charcoal)' }}>
                        {user.name}
                      </h3>
                      <div className="flex items-center gap-8">
                        <Badge type={user.isVerified ? 'ACTIVE' : 'REMOVED'}>
                          {user.isVerified ? 'Verified' : 'Unverified'}
                        </Badge>
                        <Badge type={user.role === 'admin' ? 'ACTIVE' : 'SELL'}>
                          {user.role}
                        </Badge>
                      </div>
                    </div>
                    <p className="text-body-sm text-[var(--color-secondary-text)] truncate mb-4">
                      {user.email}
                    </p>
                    <div className="flex items-center gap-16 text-body-sm text-[var(--color-secondary-text)] flex-wrap">
                      <span>{user.course} • {user.branch} • Year {user.year}</span>
                      <span>College: {user.collegeId}</span>
                      <span>Joined {formatDistanceToNow(toDate(user.createdAt), { addSuffix: true })}</span>
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-8">
                    <select
                      value={user.role}
                      onChange={(e) => handleRoleChange(user.uid, e.target.value as UserRole)}
                      className="input w-auto text-body-sm"
                    >
                      <option value="student">Student</option>
                      <option value="admin">Admin</option>
                    </select>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleVerify(user.uid, !user.isVerified)}
                      style={{ color: user.isVerified ? 'var(--color-warning)' : 'var(--color-success)' }}
                    >
                      {user.isVerified ? 'Unverify' : 'Verify'}
                    </Button>
                  </div>
                </div>
              </Card>
            ))}
          </div>

          {hasMore && (
            <div className="text-center mt-24">
              <Button variant="outline" onClick={() => fetchUsers(false)} loading={loadingMore}>
                Load More
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}