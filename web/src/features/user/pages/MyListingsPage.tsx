import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Card, CardContent, Badge } from '@shared/components/ui';
import { Product, ListingStatus, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, getDocs, updateDoc, doc, limit, startAfter, DocumentSnapshot } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function MyListingsPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentSnapshot | null>(null);
  const [activeTab, setActiveTab] = useState<ListingStatus>('ACTIVE');

  useEffect(() => {
    if (user) {
      fetchProducts(true);
    } else {
      setProducts([]);
      setLoading(false);
    }
  }, [user, activeTab]);

  const fetchProducts = async (reset = false) => {
    if (!user) return;
    if (reset) {
      setLoading(true);
      setLastDoc(null);
      setProducts([]);
      setHasMore(true);
    } else {
      setLoadingMore(true);
    }

    try {
      const db = getFirebaseDb();
      let q = query(
        collection(db, 'products'),
        where('sellerId', '==', user.uid),
        where('status', '==', activeTab),
        orderBy('createdAt', 'desc'),
        limit(20)
      );

      if (lastDoc) {
        q = query(q, startAfter(lastDoc));
      }

      const snapshot = await getDocs(q);
      const newProducts = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Product));
      
      if (reset) {
        setProducts(newProducts);
      } else {
        setProducts(prev => [...prev, ...newProducts]);
      }
      
      setLastDoc(snapshot.docs[snapshot.docs.length - 1] || null);
      setHasMore(newProducts.length === 20);
    } catch (error) {
      console.error('Error fetching products:', error);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  const handleStatusChange = async (productId: string, newStatus: ListingStatus) => {
    try {
      const db = getFirebaseDb();
      await updateDoc(doc(db, 'products', productId), { status: newStatus, updatedAt: new Date() });
      setProducts(prev => prev.map(p => p.id === productId ? { ...p, status: newStatus } : p));
    } catch (error) {
      console.error('Error updating status:', error);
    }
  };

  const handleDelete = async (productId: string) => {
    if (!confirm('Delete this listing permanently?')) return;
    try {
      const db = getFirebaseDb();
      await updateDoc(doc(db, 'products', productId), { status: 'REMOVED', updatedAt: new Date() });
      setProducts(prev => prev.filter(p => p.id !== productId));
    } catch (error) {
      console.error('Error deleting:', error);
    }
  };

  const statusTabs: ListingStatus[] = ['ACTIVE', 'RESERVED', 'SOLD', 'REMOVED'];

  if (loading) {
    return (
      <div className="container py-16">
        <div className="max-w-4xl mx-auto">
          <div className="space-y-12">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="card p-16 animate-pulse">
                <div className="flex gap-12">
                  <div className="w-20 h-20 rounded-lg bg-[var(--color-border)]" />
                  <div className="flex-1">
                    <div className="h-6 bg-[var(--color-border)] rounded w-1/2 mb-8" />
                    <div className="h-4 bg-[var(--color-border)] rounded w-1/3 mb-8" />
                    <div className="h-4 bg-[var(--color-border)] rounded w-1/4" />
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
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center justify-between mb-24">
            <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>My Listings</h1>
            <Button onClick={() => navigate('/sell')}>Create Listing</Button>
          </div>

          <div className="flex gap-8 mb-24 border-b border-[var(--color-border)]" role="tablist">
            {statusTabs.map(status => (
              <button
                key={status}
                role="tab"
                aria-selected={activeTab === status}
                onClick={() => setActiveTab(status)}
                className={`px-16 py-8 text-body-sm font-medium border-b-2 transition-colors ${
                  activeTab === status
                    ? 'border-[var(--color-ochre)] text-[var(--color-ochre)]'
                    : 'border-transparent text-[var(--color-secondary-text)] hover:text-[var(--color-primary-text)]'
                }`}
              >
                {status} ({products.filter(p => p.status === status).length})
              </button>
            ))}
          </div>

          {products.length === 0 ? (
            <div className="text-center py-32">
              <div className="text-6xl mb-12">📦</div>
              <h3 className="text-h3 mb-8" style={{ color: 'var(--color-charcoal)' }}>No listings yet</h3>
              <p className="text-body text-[var(--color-secondary-text)] mb-24">
                {activeTab === 'ACTIVE' 
                  ? 'Create your first listing to start selling'
                  : `No ${activeTab.toLowerCase()} listings`}
              </p>
              {activeTab === 'ACTIVE' && (
                <Button onClick={() => navigate('/sell')}>Create Listing</Button>
              )}
            </div>
          ) : (
            <>
              <div className="space-y-12">
                {products.map(product => (
                  <div key={product.id} className="card p-16">
                    <div className="flex gap-16">
                      <div className="relative w-20 h-20 rounded-lg overflow-hidden bg-[var(--color-border)] flex-shrink-0">
                        {product.images.length > 0 ? (
                          <img src={product.images[0]} alt={product.title} className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-2xl">📦</div>
                        )}
                        <div className="absolute top-2 right-2">
                          <Badge type={product.listingType} />
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-12 mb-4">
                          <h3 className="text-body font-medium truncate" style={{ color: 'var(--color-charcoal)' }}>
                            {product.title}
                          </h3>
                          <Badge type={product.status} />
                        </div>
                        <p className="text-body-sm text-[var(--color-secondary-text)] truncate mb-4">
                          {product.description}
                        </p>
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-16">
                            {product.listingType === 'FREE' ? (
                              <span className="text-h4" style={{ color: 'var(--color-ochre)' }}>FREE</span>
                            ) : (
                              <span className="text-h4" style={{ color: 'var(--color-charcoal)' }}>
                                ₹{product.price.toLocaleString()}
                              </span>
                            )}
                            <span className="text-caption text-[var(--color-secondary-text)]">
                              {formatDistanceToNow(toDate(product.createdAt), { addSuffix: true })}
                            </span>
                          </div>
                          <div className="flex items-center gap-8">
                            <Button variant="ghost" size="sm" onClick={() => navigate(`/listings/${product.id}/edit`)}>
                              Edit
                            </Button>
                            {product.status === 'ACTIVE' && (
                              <>
                                <Button variant="ghost" size="sm" onClick={() => handleStatusChange(product.id, 'RESERVED')}>
                                  Reserve
                                </Button>
                                <Button variant="ghost" size="sm" onClick={() => handleStatusChange(product.id, 'SOLD')}>
                                  Mark Sold
                                </Button>
                              </>
                            )}
                            {product.status !== 'REMOVED' && (
                              <Button variant="ghost" size="sm" onClick={() => handleDelete(product.id)} style={{ color: 'var(--color-error)' }}>
                                Delete
                              </Button>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {hasMore && (
                <div className="text-center mt-24">
                  <Button variant="outline" onClick={() => fetchProducts(false)} loading={loadingMore} className="w-full sm:w-auto">
                    Load More
                  </Button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}