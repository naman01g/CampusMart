import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Input, Card, CardContent } from '@shared/components/ui';
import { Chat, Message, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { doc, onSnapshot, addDoc, updateDoc, serverTimestamp, query, orderBy, collection, writeBatch } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function ChatPage() {
  const { chatId } = useParams<{ chatId: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [chat, setChat] = useState<Chat | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const getRoleLabel = (chat: Chat): 'Buyer' | 'Seller' => {
    if (!user) return 'Buyer';
    return chat.buyerId === user.uid ? 'Seller' : 'Buyer';
  };

  const getOtherRoleLabel = (chat: Chat): 'Buyer' | 'Seller' => {
    if (!user) return 'Buyer';
    return chat.buyerId === user.uid ? 'Buyer' : 'Seller';
  };

  useEffect(() => {
    if (!chatId || !user) {
      navigate('/chat');
      return;
    }

    const db = getFirebaseDb();
    
    const chatRef = doc(db, 'chats', chatId);
    const unsubscribeChat = onSnapshot(chatRef, (docSnap) => {
      if (docSnap.exists()) {
        const data = { id: docSnap.id, ...docSnap.data() } as Chat;
        setChat(data);
      } else {
        navigate('/chat');
      }
    });

    const messagesRef = collection(db, 'chats', chatId, 'messages');
    const messagesQuery = query(messagesRef, orderBy('createdAt', 'asc'));
    const unsubscribeMessages = onSnapshot(messagesQuery, (snapshot) => {
      const msgs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Message));
      setMessages(msgs);
      setLoading(false);
      
      // Mark messages as read
      const unreadMessages = msgs.filter(m => m.senderId !== user.uid && !m.isRead);
      if (unreadMessages.length > 0) {
        const batch = writeBatch(db);
        unreadMessages.forEach(msg => {
          batch.update(doc(db, 'chats', chatId, 'messages', msg.id), { isRead: true });
        });
        batch.commit();
      }
    });

    return () => {
      unsubscribeChat();
      unsubscribeMessages();
    };
  }, [chatId, user, navigate]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !user || !chatId) return;

    const messageText = newMessage.trim();
    setNewMessage('');
    setSending(true);

    try {
      const db = getFirebaseDb();
      await addDoc(collection(db, 'chats', chatId, 'messages'), {
        senderId: user.uid,
        message: messageText,
        createdAt: serverTimestamp(),
        isRead: false,
      });

      await updateDoc(doc(db, 'chats', chatId), {
        lastMessage: messageText,
        lastMessageAt: serverTimestamp(),
      });
    } catch (error) {
      console.error('Error sending message:', error);
      setNewMessage(messageText);
    } finally {
      setSending(false);
    }
  };

  if (loading) {
    return (
      <div className="flex-1 flex flex-col">
        <div className="container py-16">
          <div className="max-w-3xl mx-auto">
            <div className="card animate-pulse">
              <div className="h-[60vh] bg-[var(--color-border)]" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!chat) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-h3" style={{ color: 'var(--color-charcoal)' }}>Chat not found</h2>
          <Button variant="outline" onClick={() => navigate('/chat')} className="mt-16">
            Back to Messages
          </Button>
        </div>
      </div>
    );
  }

  const roleLabel = getRoleLabel(chat);
  const otherRoleLabel = getOtherRoleLabel(chat);
  const productTitle = chat.product?.title || 'Unknown product';

  return (
    <div className="flex-1 flex flex-col">
      <header className="border-b border-[var(--color-border)] bg-[var(--color-surface)]">
        <div className="container">
          <div className="flex items-center gap-12 h-16">
            <button onClick={() => navigate('/chat')} className="md:hidden p-2" aria-label="Back">
              ←
            </button>
            <div className="w-10 h-10 rounded-full bg-primary-container flex items-center justify-center flex-shrink-0">
              <span className="material-symbols-outlined text-on-primary" data-icon="person">person</span>
            </div>
            <div className="flex-1 min-w-0">
              <h2 className="text-body font-medium truncate" style={{ color: 'var(--color-charcoal)' }}>
                {otherRoleLabel}
              </h2>
              <p className="text-caption text-[var(--color-secondary-text)] truncate">
                {productTitle}
              </p>
            </div>
            <span className="badge badge-sell text-xs px-2 py-1">{roleLabel}</span>
          </div>
        </div>
      </header>

      <main className="flex-1 overflow-y-auto p-16" style={{ backgroundColor: 'var(--color-warm-cream)' }}>
        <div className="max-w-3xl mx-auto space-y-16">
          {messages.map(message => {
            const isOwn = message.senderId === user?.uid;
            const messageTime = toDate(message.createdAt);
            
            return (
              <div
                key={message.id}
                className={`flex ${isOwn ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[70%] px-12 py-8 rounded-2xl ${
                    isOwn
                      ? 'rounded-tr-sm bg-[var(--color-ochre)] text-white'
                      : 'rounded-tl-sm bg-[var(--color-surface)] border border-[var(--color-border)]'
                  }`}
                >
                  <p className="text-body whitespace-pre-wrap">{message.message}</p>
                  <div className={`flex items-center gap-8 mt-4 text-caption ${isOwn ? 'justify-end' : 'justify-start'}`}>
                    <span style={{ color: isOwn ? 'rgba(255,255,255,0.7)' : 'var(--color-secondary-text)' }}>
                      {formatDistanceToNow(messageTime, { addSuffix: true })}
                    </span>
                    {isOwn && message.isRead && (
                      <span style={{ color: 'rgba(255,255,255,0.7)' }}>✓✓</span>
                    )}
                    {isOwn && !message.isRead && (
                      <span style={{ color: 'rgba(255,255,255,0.7)' }}>✓</span>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
          <div ref={messagesEndRef} />
        </div>
      </main>

      <form onSubmit={handleSendMessage} className="border-t border-[var(--color-border)] bg-[var(--color-surface)] p-16">
        <div className="max-w-3xl mx-auto flex gap-12">
          <Input
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder="Type a message..."
            className="flex-1"
            disabled={sending}
            onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSendMessage(e)}
          />
          <Button type="submit" loading={sending} disabled={!newMessage.trim()}>
            Send
          </Button>
        </div>
      </form>
    </div>
  );
}