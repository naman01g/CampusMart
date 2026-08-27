import { useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Card, CardContent } from '@shared/components/ui';
import { Chat, User, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, onSnapshot, getDocs, limit, or } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function ChatListPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [chats, setChats] = useState<Chat[]>([]);
  const [loading, setLoading] = useState(true);
  const unsubscribeRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    if (!user) {
      setChats([]);
      setLoading(false);
      return;
    }

    const db = getFirebaseDb();
    const chatsRef = collection(db, 'chats');
    
    // Use Firestore OR query to fetch chats where user is buyer OR seller
    const q = query(
      chatsRef,
      or(
        where('buyerId', '==', user.uid),
        where('sellerId', '==', user.uid)
      ),
      orderBy('lastMessageAt', 'desc'),
      limit(50)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const allChats = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Chat));
      
      // Deduplicate by chatId (in case of any edge cases)
      const uniqueChats = Array.from(
        new Map(allChats.map(chat => [chat.id, chat])).values()
      );
      
      uniqueChats.sort((a, b) => toDate(b.lastMessageAt).getTime() - toDate(a.lastMessageAt).getTime());
      setChats(uniqueChats);
      setLoading(false);
    }, (error) => {
      console.error('Error fetching chats:', error);
      setLoading(false);
    });

    unsubscribeRef.current = unsubscribe;

    return () => {
      if (unsubscribeRef.current) {
        unsubscribeRef.current();
      }
    };
  }, [user]);

  const getOtherUser = (chat: Chat): User | undefined => {
    if (!user) return undefined;
    return chat.buyerId === user.uid ? chat.seller : chat.buyer;
  };

  const getProductTitle = (chat: Chat): string => {
    return chat.product?.title || 'Unknown product';
  };

  const getRoleLabel = (chat: Chat): 'Buyer' | 'Seller' => {
    if (!user) return 'Buyer';
    return chat.buyerId === user.uid ? 'Seller' : 'Buyer';
  };

  if (loading) {
    return (
      <div className="container py-16">
        <div className="max-w-2xl mx-auto">
          <div className="space-y-12">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="card p-16 animate-pulse">
                <div className="flex gap-12">
                  <div className="w-12 h-12 rounded-full bg-[var(--color-border)]" />
                  <div className="flex-1">
                    <div className="h-6 bg-[var(--color-border)] rounded w-1/2 mb-8" />
                    <div className="h-4 bg-[var(--color-border)] rounded w-1/3" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1">
      <div className="container py-16">
        <div className="max-w-2xl mx-auto">
          <div className="flex items-center justify-between mb-24">
            <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Messages</h1>
          </div>

          {chats.length === 0 ? (
            <div className="text-center py-32">
              <div className="text-6xl mb-12">💬</div>
              <h3 className="text-h3 mb-8" style={{ color: 'var(--color-charcoal)' }}>No messages yet</h3>
              <p className="text-body text-[var(--color-secondary-text)] mb-24">
                Start a conversation by contacting a seller from a listing
              </p>
              <Link to="/listings">
                <Button>Browse Listings</Button>
              </Link>
            </div>
          ) : (
            <div className="space-y-12">
              {chats.map(chat => {
                const otherUser = getOtherUser(chat);
                const productTitle = getProductTitle(chat);
                const lastMessageTime = toDate(chat.lastMessageAt);
                const roleLabel = getRoleLabel(chat);
                
                return (
                  <Link
                    key={chat.id}
                    to={`/chat/${chat.id}`}
                    className="card p-16 group hover:shadow-md transition-shadow"
                  >
                    <div className="flex gap-12">
                      <img
                        src={otherUser?.profileImage || `https://ui-avatars.com/api/?name=${encodeURIComponent(otherUser?.name || 'User')}&background=E38F2D&color=fff`}
                        alt={otherUser?.name || 'User'}
                        className="w-12 h-12 rounded-full"
                      />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-12 mb-4">
                          <div className="flex items-center gap-8">
                            <h3 className="text-body font-medium truncate" style={{ color: 'var(--color-charcoal)' }}>
                              {otherUser?.name || 'Unknown'}
                            </h3>
                            <span className="badge badge-sell text-xs px-2 py-1">{roleLabel}</span>
                          </div>
                          <span className="text-caption text-[var(--color-secondary-text)] whitespace-nowrap">
                            {formatDistanceToNow(lastMessageTime, { addSuffix: true })}
                          </span>
                        </div>
                        <p className="text-body-sm text-[var(--color-secondary-text)] truncate">
                          {productTitle}
                        </p>
                        <p className="text-body-sm text-[var(--color-secondary-text)] truncate mt-4">
                          {chat.lastMessage}
                        </p>
                      </div>
                    </div>
                  </Link>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}