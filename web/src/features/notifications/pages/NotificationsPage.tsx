import { useState, useEffect, useRef } from 'react';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Badge } from '@shared/components/ui';
import { Notification, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, onSnapshot, limit, doc, updateDoc, getDocs, writeBatch } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function NotificationsPage() {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const unsubscribeRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    if (!user) {
      setNotifications([]);
      setLoading(false);
      return;
    }

    const db = getFirebaseDb();
    const notificationsRef = collection(db, 'notifications');
    const q = query(
      notificationsRef,
      where('recipientId', '==', user.uid),
      orderBy('createdAt', 'desc'),
      limit(50)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const notifs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Notification));
      
      // Deduplicate by notification document ID
      const uniqueNotifs = Array.from(
        new Map(notifs.map(n => [n.id, n])).values()
      );
      
      setNotifications(uniqueNotifs);
      setLoading(false);
    }, (err) => {
      console.error('Error fetching notifications:', err);
      setError('Failed to load notifications');
      setLoading(false);
    });

    unsubscribeRef.current = unsubscribe;

    return () => {
      if (unsubscribeRef.current) {
        unsubscribeRef.current();
      }
    };
  }, [user]);

  const handleMarkRead = async (notificationId: string) => {
    try {
      const db = getFirebaseDb();
      await updateDoc(doc(db, 'notifications', notificationId), { isRead: true });
    } catch (err) {
      console.error('Error marking notification as read:', err);
    }
  };

  const handleMarkAllRead = async () => {
    const unreadNotifications = notifications.filter(n => !n.isRead);
    if (unreadNotifications.length === 0) return;

    try {
      const db = getFirebaseDb();
      const batch = writeBatch(db);
      unreadNotifications.forEach(n => {
        batch.update(doc(db, 'notifications', n.id), { isRead: true });
      });
      await batch.commit();
    } catch (err) {
      console.error('Error marking all as read:', err);
    }
  };

  const getRoleFromNotification = (notification: Notification): 'Buyer' | 'Seller' | '' => {
    if (notification.type === 'chat_message' && notification.data) {
      const senderRole = notification.data.senderRole as string;
      if (senderRole === 'buyer') return 'Buyer';
      if (senderRole === 'seller') return 'Seller';
    }
    return '';
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'chat_message': return 'chat';
      case 'new_listing': return 'inventory_2';
      case 'price_drop': return 'trending_down';
      case 'favorite': return 'favorite';
      case 'report': return 'flag';
      default: return 'notifications';
    }
  };

  if (loading) {
    return (
      <div className="container py-lg">
        <div className="max-w-2xl mx-auto">
          <h1 className="font-headline-md text-headline-md text-primary mb-lg">Notifications</h1>
          <div className="space-y-md">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="card-surface p-md animate-pulse">
                <div className="flex gap-md">
                  <div className="w-12 h-12 rounded-full bg-surface-container-highest" />
                  <div className="flex-1">
                    <div className="h-6 bg-surface-container-highest rounded w-1/2 mb-xs" />
                    <div className="h-4 bg-surface-container-highest rounded w-1/3" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container py-lg text-center">
        <span className="material-symbols-outlined text-6xl text-error">error_outline</span>
        <h2 className="font-title-lg text-title-lg text-primary mt-md mb-sm">Failed to load notifications</h2>
        <p className="font-body-md text-body-md text-on-surface-variant mb-lg">{error}</p>
        <Button variant="outline" onClick={() => window.location.reload()}>Retry</Button>
      </div>
    );
  }

  const unreadCount = notifications.filter(n => !n.isRead).length;

  return (
    <div className="flex-1">
      <main className="container py-lg max-w-2xl mx-auto">
        <header className="flex items-center justify-between mb-lg">
          <h1 className="font-headline-md text-headline-md text-primary">Notifications</h1>
          {unreadCount > 0 && (
            <Button variant="ghost" size="sm" onClick={handleMarkAllRead}>
              Mark all as read
            </Button>
          )}
        </header>

        {notifications.length === 0 ? (
          <div className="text-center py-xl">
            <span className="material-symbols-outlined text-6xl text-on-surface-variant">notifications_none</span>
            <h3 className="font-title-lg text-title-lg text-primary mt-md mb-sm">No notifications yet</h3>
            <p className="font-body-md text-body-md text-on-surface-variant mb-md">
              You&apos;ll see updates here when you get new messages or activity on your listings
            </p>
          </div>
        ) : (
          <div className="space-y-md">
            {notifications.map(notification => {
              const notifTime = toDate(notification.createdAt);
              const roleLabel = getRoleFromNotification(notification);
              const iconName = getNotificationIcon(notification.type);

              return (
                <div
                  key={notification.id}
                  className={`card-surface p-md flex gap-md ${!notification.isRead ? 'bg-primary-container/20 border-primary-container' : 'border-outline-variant'}`}
                  onClick={() => !notification.isRead && handleMarkRead(notification.id)}
                >
                  <div className="w-10 h-10 rounded-full bg-surface-container-lowest flex items-center justify-center flex-shrink-0">
                    <span className="material-symbols-outlined text-on-surface-variant" data-icon={iconName}>
                      {iconName}
                    </span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-sm">
                      <h3 className="font-body-md text-body-md text-on-surface truncate">
                        {notification.title}
                      </h3>
                      <span className="font-label-sm text-label-sm text-on-surface-variant whitespace-nowrap">
                        {formatDistanceToNow(notifTime, { addSuffix: true })}
                      </span>
                    </div>
                    <p className="font-body-md text-body-md text-on-surface-variant mt-xs truncate">
                      {notification.body}
                    </p>
                    {roleLabel && (
                      <span className="badge badge-sell mt-xs text-xs">
                        {roleLabel}
                      </span>
                    )}
                  </div>
                  {!notification.isRead && (
                    <div className="w-2 h-2 rounded-full bg-primary mt-2 flex-shrink-0" />
                  )}
                </div>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}