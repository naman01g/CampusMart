import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Badge } from '@shared/components/ui';
import { Product, CATEGORIES, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, limit, getDocs } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function HomePage() {
  const { user } = useAuth();
  const [featuredProducts, setFeaturedProducts] = useState<Product[]>([]);
  const [feedProducts, setFeedProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const db = getFirebaseDb();
      
      // Fetch featured product (most recent ACTIVE)
      const featuredQuery = query(
        collection(db, 'products'),
        where('status', '==', 'ACTIVE'),
        orderBy('createdAt', 'desc'),
        limit(1)
      );
      
      // Fetch feed products (recent ACTIVE, up to 8)
      const feedQuery = query(
        collection(db, 'products'),
        where('status', '==', 'ACTIVE'),
        orderBy('createdAt', 'desc'),
        limit(8)
      );

      const [featuredSnap, feedSnap] = await Promise.all([
        getDocs(featuredQuery),
        getDocs(feedQuery),
      ]);

      const featured = featuredSnap.docs.map(doc => ({ id: doc.id, ...doc.data() } as Product));
      const feed = feedSnap.docs.map(doc => ({ id: doc.id, ...doc.data() } as Product));

      setFeaturedProducts(featured);
      setFeedProducts(feed);
    } catch (err) {
      console.error('Error fetching products:', err);
      setError('Failed to load listings');
    } finally {
      setLoading(false);
    }
  };

  const getListingTypeBadgeClass = (type: Product['listingType']) => {
    switch (type) {
      case 'SELL': return 'bg-secondary-container text-on-secondary-container';
      case 'FREE': return 'bg-background border border-outline-variant text-primary';
      case 'EXCHANGE': return 'bg-surface-container-highest border border-outline-variant text-primary';
      default: return 'bg-surface-container-highest border border-outline-variant text-primary';
    }
  };

  if (loading) {
    return (
      <div className="flex-1">
        <main className="px-md py-lg space-y-lg max-w-container-max mx-auto">
          <section className="space-y-sm">
            <h2 className="font-title-lg text-title-lg text-primary tracking-tight">Fresh on Campus</h2>
            <div className="lg:max-w-[700px] mx-auto">
              <div className="card-surface overflow-hidden animate-pulse">
                <div className="aspect-video w-full bg-surface-container" />
                <div className="p-md space-y-sm">
                  <div className="h-8 bg-surface-container-highest rounded w-3/4 mb-sm" />
                  <div className="h-4 bg-surface-container-highest rounded w-1/2 mb-sm" />
                  <div className="h-6 bg-surface-container-highest rounded w-1/4" />
                </div>
              </div>
            </div>
          </section>
          <section className="space-y-md">
            <div className="flex justify-between items-end">
              <h2 className="font-title-lg text-title-lg text-primary tracking-tight">Marketplace Feed</h2>
            </div>
            <div className="grid grid-cols-2 gap-sm lg:grid-cols-4">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="card-surface p-sm space-y-2 animate-pulse">
                  <div className="aspect-square w-full bg-surface-container rounded border border-outline-variant" />
                  <div className="h-6 bg-surface-container-highest rounded w-3/4 mb-1" />
                  <div className="h-4 bg-surface-container-highest rounded w-1/2 mb-1" />
                  <div className="h-6 bg-surface-container-highest rounded w-1/4" />
                </div>
              ))}
            </div>
          </section>
        </main>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex-1">
        <main className="px-md py-lg space-y-lg max-w-container-max mx-auto text-center">
          <span className="material-symbols-outlined text-6xl text-error">error_outline</span>
          <h2 className="font-title-lg text-title-lg text-primary mt-md mb-sm">Failed to load listings</h2>
          <p className="font-body-md text-body-md text-on-surface-variant mb-lg">{error}</p>
          <Button variant="outline" onClick={fetchProducts}>Retry</Button>
        </main>
      </div>
    );
  }

  return (
    <div className="flex-1">
      <main className="px-md py-lg space-y-lg max-w-container-max mx-auto">
        {/* Featured Section */}
        <section className="space-y-sm">
          <h2 className="font-title-lg text-title-lg text-primary tracking-tight">Fresh on Campus</h2>
          <div className="lg:max-w-[700px] mx-auto">
            {featuredProducts.length > 0 ? (
              featuredProducts.map(product => (
                <Link
                  key={product.id}
                  to={`/listings/${product.id}`}
                  className="card-surface overflow-hidden group hover:border-primary-container transition-colors cursor-pointer block"
                >
                  <div className="aspect-video w-full bg-surface-container relative overflow-hidden border-b border-outline-variant">
                    {product.images.length > 0 ? (
                      <img
                        alt={product.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                        src={product.images[0]}
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-6xl">📦</div>
                    )}
                    <div className="absolute top-sm right-sm bg-background border border-outline-variant rounded-lg px-2 py-1 flex items-center gap-1">
                      <span className="material-symbols-outlined text-[14px]" data-icon="location_on">location_on</span>
                      <span className="font-label-sm text-label-sm text-primary">{product.location}</span>
                    </div>
                  </div>
                  <div className="p-md space-y-sm">
                    <div className="flex justify-between items-start">
                      <div>
                        <h3 className="font-title-lg text-title-lg text-primary leading-tight">{product.title}</h3>
                        <p className="font-body-md text-body-md text-on-surface-variant">{product.condition} • {product.category}</p>
                      </div>
                      <span className="font-label-price text-label-price text-primary">
                        {product.listingType === 'FREE' ? 'FREE' : `₹${product.price.toLocaleString()}`}
                      </span>
                    </div>
                    <div className="flex gap-2 pt-2">
                      <Button variant="primary" className="flex-1">Contact Seller</Button>
                    </div>
                  </div>
                </Link>
              ))
            ) : (
              <div className="card-surface p-xl text-center">
                <span className="material-symbols-outlined text-4xl text-on-surface-variant">inventory_2</span>
                <h3 className="font-title-lg text-title-lg text-primary mt-md mb-sm">No listings yet</h3>
                <p className="font-body-md text-body-md text-on-surface-variant mb-md">Be the first to list something!</p>
                {user && (
                  <Button variant="primary" onClick={() => window.location.href = '/sell'}>Create Listing</Button>
                )}
              </div>
            )}
          </div>
        </section>

        {/* Feed Section */}
        <section className="space-y-md">
          <div className="flex justify-between items-end">
            <h2 className="font-title-lg text-title-lg text-primary tracking-tight">Marketplace Feed</h2>
            <Link to="/listings">
              <button className="font-label-sm text-label-sm text-on-surface-variant flex items-center gap-1 hover:text-primary transition-colors">
                View All <span className="material-symbols-outlined text-[16px]" data-icon="chevron_right">chevron_right</span>
              </button>
            </Link>
          </div>
          <div className="grid grid-cols-2 gap-sm lg:grid-cols-4">
            {feedProducts.length > 0 ? (
              feedProducts.map(product => (
                <Link
                  key={product.id}
                  to={`/listings/${product.id}`}
                  className="card-surface p-sm space-y-2 group hover:border-primary-container transition-colors cursor-pointer flex flex-col"
                >
                  <div className="aspect-square w-full bg-surface-container rounded border border-outline-variant overflow-hidden relative">
                    {product.images.length > 0 ? (
                      <img
                        alt={product.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        src={product.images[0]}
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-4xl">📦</div>
                    )}
                    <div className={`absolute bottom-xs left-xs font-label-sm text-label-sm px-1.5 py-0.5 rounded uppercase tracking-wider ${getListingTypeBadgeClass(product.listingType)}`}>
                      {product.listingType}
                    </div>
                  </div>
                  <div className="flex-1 flex flex-col justify-between">
                    <div>
                      <h4 className="font-body-md text-body-md text-primary leading-tight line-clamp-2">{product.title}</h4>
                      <p className="font-label-sm text-label-sm text-on-surface-variant mt-1 flex items-center gap-0.5">
                        <span className="material-symbols-outlined text-[12px]" data-icon="location_on">location_on</span>
                        {product.location}
                      </p>
                    </div>
                    <div className="font-label-price text-label-price text-primary mt-2">
                      {product.listingType === 'FREE' ? 'FREE' : `₹${product.price.toLocaleString()}`}
                    </div>
                  </div>
                </Link>
              ))
            ) : (
              <div className="lg:col-span-4 card-surface p-xl text-center">
                <span className="material-symbols-outlined text-4xl text-on-surface-variant">inventory_2</span>
                <h3 className="font-title-lg text-title-lg text-primary mt-md mb-sm">No active listings</h3>
                <p className="font-body-md text-body-md text-on-surface-variant mb-md">Check back later for new items!</p>
              </div>
            )}
          </div>
        </section>
      </main>
    </div>
  );
}