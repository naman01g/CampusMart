import { useState, useEffect } from 'react';
import { Card, CardContent, Badge, Button } from '@shared/components/ui';
import { Product, ListingStatus, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, getDocs, updateDoc, doc, limit, startAfter, DocumentSnapshot } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function AdminListingsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentSnapshot | null>(null);
  const [statusFilter, setStatusFilter] = useState<ListingStatus | 'ALL'>('ALL');

  useEffect(() => {
    fetchProducts(true);
  }, [statusFilter]);

  const fetchProducts = async (reset = false) => {
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
        orderBy('createdAt', 'desc'),
        limit(20)
      );

      if (statusFilter !== 'ALL') {
        q = query(q, where('status', '==', statusFilter));
      }

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

  const statusOptions = ['ALL', 'ACTIVE', 'RESERVED', 'SOLD', 'REMOVED'] as const;

  if (loading) {
    return (
      <div>
        <h1 className="text-h2 mb-24" style={{ color: 'var(--color-charcoal)' }}>Manage Listings</h1>
        <div className="space-y-12">
          {[...Array(4)].map((_, i) => (
            <Card key={i} padding="md">
              <div className="flex gap-12 animate-pulse">
                <div className="w-16 h-16 rounded-lg bg-[var(--color-border)]" />
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
        <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Manage Listings</h1>
        <div className="flex gap-8">
          {statusOptions.map(status => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className={`px-12 py-8 text-body-sm font-medium rounded-lg transition-colors ${
                statusFilter === status
                  ? 'bg-[var(--color-ochre)] text-white'
                  : 'bg-[var(--color-surface)] border border-[var(--color-border)] hover:border-[var(--color-ochre)]'
              }`}
            >
              {status}
            </button>
          ))}
        </div>
      </div>

      {products.length === 0 ? (
        <Card padding="lg" className="text-center py-24">
          <div className="text-6xl mb-12">📦</div>
          <h3 className="text-h3 mb-8" style={{ color: 'var(--color-charcoal)' }}>No listings found</h3>
          <p className="text-body text-[var(--color-secondary-text)]">
            {statusFilter !== 'ALL' ? `No ${statusFilter.toLowerCase()} listings` : 'No listings in the system'}
          </p>
        </Card>
      ) : (
        <>
          <div className="space-y-12">
            {products.map(product => (
              <Card key={product.id} padding="md">
                <div className="flex gap-16">
                  <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-[var(--color-border)] flex-shrink-0">
                    {product.images.length > 0 ? (
                      <img src={product.images[0]} alt={product.title} className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-2xl">📦</div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-12 mb-4">
                      <h3 className="text-body font-medium truncate" style={{ color: 'var(--color-charcoal)' }}>
                        {product.title}
                      </h3>
                      <div className="flex items-center gap-8">
                        <Badge type={product.listingType} />
                        <Badge type={product.status} />
                      </div>
                    </div>
                    <p className="text-body-sm text-[var(--color-secondary-text)] truncate mb-4">
                      {product.description}
                    </p>
                    <div className="flex items-center justify-between flex-wrap gap-8">
                      <div className="flex items-center gap-16 text-body-sm text-[var(--color-secondary-text)]">
                        <span>Seller: {product.sellerId.substring(0, 8)}...</span>
                        <span>{product.category}</span>
                        <span>₹{product.price.toLocaleString()}</span>
                        <span>{formatDistanceToNow(toDate(product.createdAt), { addSuffix: true })}</span>
                      </div>
                      <div className="flex items-center gap-8">
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
                            Remove
                          </Button>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </div>

          {hasMore && (
            <div className="text-center mt-24">
              <Button variant="outline" onClick={() => fetchProducts(false)} loading={loadingMore}>
                Load More
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}