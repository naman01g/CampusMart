import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Card, CardContent, Badge, Button } from '@shared/components/ui';
import { Product, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, getDocs, doc, getDoc, limit, startAfter, DocumentSnapshot, deleteDoc, updateDoc, increment } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function FavoritesPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentSnapshot | null>(null);

  useEffect(() => {
    if (user) {
      fetchFavorites(true);
    } else {
      setProducts([]);
      setLoading(false);
    }
  }, [user]);

  const fetchFavorites = async (reset = false) => {
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
        collection(db, 'favorites'),
        where('userId', '==', user.uid),
        orderBy('createdAt', 'desc'),
        limit(20)
      );

      if (lastDoc) {
        q = query(q, startAfter(lastDoc));
      }

      const snapshot = await getDocs(q);
      const favoriteIds = snapshot.docs.map(doc => doc.data().productId);
      
      if (favoriteIds.length === 0) {
        if (reset) setProducts([]);
        setHasMore(false);
        return;
      }

      const productRefs = favoriteIds.map(id => doc(db, 'products', id));
      const productSnaps = await Promise.all(productRefs.map(ref => getDoc(ref)));
      const newProducts = productSnaps
        .filter(snap => snap.exists() && snap.data().status === 'ACTIVE')
        .map(snap => ({ id: snap.id, ...snap.data() } as Product));
      
      if (reset) {
        setProducts(newProducts);
      } else {
        setProducts(prev => [...prev, ...newProducts]);
      }
      
      setLastDoc(snapshot.docs[snapshot.docs.length - 1] || null);
      setHasMore(newProducts.length === 20);
    } catch (error) {
      console.error('Error fetching favorites:', error);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  const handleRemoveFavorite = async (productId: string) => {
    try {
      const db = getFirebaseDb();
      await deleteDoc(doc(db, 'favorites', `${user?.uid}_${productId}`));
      await updateDoc(doc(db, 'products', productId), { favoritesCount: increment(-1) });
      setProducts(prev => prev.filter(p => p.id !== productId));
    } catch (error) {
      console.error('Error removing favorite:', error);
    }
  };

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
          <h1 className="text-h2 mb-24" style={{ color: 'var(--color-charcoal)' }}>Saved Items</h1>

          {products.length === 0 ? (
            <div className="text-center py-32">
              <div className="text-6xl mb-12">☆</div>
              <h3 className="text-h3 mb-8" style={{ color: 'var(--color-charcoal)' }}>No saved items yet</h3>
              <p className="text-body text-[var(--color-secondary-text)] mb-24">
                Save listings you like to find them easily later
              </p>
              <Button onClick={() => navigate('/listings')}>Browse Listings</Button>
            </div>
          ) : (
            <>
              <div className="space-y-12">
                {products.map(product => (
                  <div key={product.id} className="card p-16 group">
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
                          <Button variant="ghost" size="sm" onClick={() => handleRemoveFavorite(product.id)} style={{ color: 'var(--color-error)' }}>
                            Remove
                          </Button>
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
                          <Button variant="outline" size="sm" onClick={() => navigate(`/listings/${product.id}`)}>
                            View
                          </Button>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {hasMore && (
                <div className="text-center mt-24">
                  <Button variant="outline" onClick={() => fetchFavorites(false)} loading={loadingMore} className="w-full sm:w-auto">
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