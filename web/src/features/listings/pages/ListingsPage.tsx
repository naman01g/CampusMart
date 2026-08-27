import { useState, useEffect, useMemo } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Input, Badge, Card, CardContent } from '@shared/components/ui';
import { Product, ListingType, ListingStatus, CATEGORIES, Category, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, limit, getDocs, startAfter, DocumentSnapshot } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function ListingsPage() {
  const { user } = useAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentSnapshot | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<{
    query: string;
    category: string;
    listingType: ListingType | '';
    minPrice: string;
    maxPrice: string;
    sortBy: string;
  }>({
    query: searchParams.get('q') || '',
    category: searchParams.get('category') || '',
    listingType: (searchParams.get('type') as ListingType) || '',
    minPrice: searchParams.get('minPrice') || '',
    maxPrice: searchParams.get('maxPrice') || '',
    sortBy: searchParams.get('sort') || 'newest',
  });

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
        where('status', '==', 'ACTIVE'),
        orderBy('createdAt', 'desc'),
        limit(20)
      );

      if (filters.category) {
        q = query(q, where('category', '==', filters.category));
      }

      if (filters.listingType) {
        q = query(q, where('listingType', '==', filters.listingType));
      }

      if (filters.minPrice) {
        q = query(q, where('price', '>=', Number(filters.minPrice)));
      }

      if (filters.maxPrice) {
        q = query(q, where('price', '<=', Number(filters.maxPrice)));
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
      setError('Failed to load listings. Please try again.');
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  useEffect(() => {
    fetchProducts(true);
  }, [filters.category, filters.listingType, filters.minPrice, filters.maxPrice, filters.sortBy]);

  // Client-side search filtering
  const filteredProducts = useMemo(() => {
    if (!filters.query) return products;
    const searchTerm = filters.query.toLowerCase().trim();
    return products.filter(product =>
      product.title.toLowerCase().includes(searchTerm) ||
      product.description.toLowerCase().includes(searchTerm) ||
      product.category.toLowerCase().includes(searchTerm) ||
      product.location.toLowerCase().includes(searchTerm)
    );
  }, [products, filters.query]);

  const handleFilterChange = (key: string, value: string) => {
    const newFilters = { ...filters, [key]: value };
    setFilters(newFilters);
    const params = new URLSearchParams();
    Object.entries(newFilters).forEach(([k, v]) => {
      if (v) params.set(k, v);
    });
    setSearchParams(params);
  };

  const clearFilters = () => {
    setFilters({ query: '', category: '', listingType: '', minPrice: '', maxPrice: '', sortBy: 'newest' });
    setSearchParams({});
  };

  const hasActiveFilters = filters.category || filters.listingType || filters.minPrice || filters.maxPrice || filters.query;

  return (
    <div className="flex-1">
      <main className="container py-lg space-y-xl max-w-container-max mx-auto">
        <header className="space-y-md">
          <div className="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-lg">
            <div>
              <h1 className="font-headline-md text-headline-md text-primary">Browse Listings</h1>
              <p className="font-body-md text-body-md text-on-surface-variant mt-sm">
                {filteredProducts.length} of {products.length} items
              </p>
            </div>
            <div className="flex flex-wrap gap-sm">
              <span className="material-symbols-outlined text-primary">tune</span>
            </div>
          </div>
          {/* Quick Filters (Chips) */}
          <div className="flex gap-sm overflow-x-auto hide-scrollbar py-1">
            <button className="flex items-center gap-xs px-sm py-xs bg-primary-container text-on-primary rounded border border-primary-container font-label-sm text-label-sm whitespace-nowrap">
              All Types
            </button>
            <button className="flex items-center gap-xs px-sm py-xs bg-surface-container-lowest text-on-surface rounded border border-outline-variant font-label-sm text-label-sm whitespace-nowrap hover:border-primary-container transition-colors">
              Sell
            </button>
            <button className="flex items-center gap-xs px-sm py-xs bg-surface-container-lowest text-on-surface rounded border border-outline-variant font-label-sm text-label-sm whitespace-nowrap hover:border-primary-container transition-colors">
              Exchange
            </button>
            <button className="flex items-center gap-xs px-sm py-xs bg-surface-container-lowest text-on-surface rounded border border-outline-variant font-label-sm text-label-sm whitespace-nowrap hover:border-primary-container transition-colors">
              Free
            </button>
          </div>
        </header>

        {/* Search and Filter Bar */}
        <div className="card-surface p-md space-y-md">
          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-md">
            <div className="relative w-full lg:w-[280px]">
              <span className="material-symbols-outlined absolute left-sm top-1/2 -translate-y-1/2 text-on-surface-variant">search</span>
              <input
                type="text"
                placeholder="Search listings..."
                value={filters.query}
                onChange={(e) => handleFilterChange('query', e.target.value)}
                className="w-full pl-[36px] pr-sm py-sm bg-surface-container-lowest border border-outline-variant rounded-lg font-body-md text-on-surface focus:outline-none focus:border-primary-container transition-colors"
              />
              <span className="material-symbols-outlined absolute right-sm top-1/2 -translate-y-1/2 text-on-surface-variant text-sm">close</span>
            </div>
            <div className="flex flex-wrap gap-sm">
              {user && (
                <Link to="/sell">
                  <Button>Create Listing</Button>
                </Link>
              )}
            </div>
          </div>
        </div>

        {/* Results Grid */}
        <section>
          {loading ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-sm">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="card-surface border border-outline-variant rounded-lg overflow-hidden animate-pulse">
                  <div className="aspect-square w-full bg-surface-container-low overflow-hidden">
                    <div className="w-full h-full bg-surface-container-low" />
                  </div>
                  <div className="p-sm flex flex-col gap-xs flex-grow">
                    <div className="flex justify-between items-start">
                      <div className="h-6 bg-surface-container-highest rounded w-3/4" />
                    </div>
                    <div className="mt-auto">
                      <div className="h-6 bg-surface-container-highest rounded w-1/4" />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : error ? (
            <div className="text-center py-xl">
              <span className="material-symbols-outlined text-6xl text-error">error_outline</span>
              <h3 className="font-title-lg text-title-lg text-primary mt-md mb-sm">Failed to load listings</h3>
              <p className="font-body-md text-body-md text-on-surface-variant mb-md">{error}</p>
              <Button variant="outline" onClick={() => fetchProducts(true)}>Retry</Button>
            </div>
          ) : filteredProducts.length === 0 ? (
            <div className="text-center py-xl">
              <span className="material-symbols-outlined text-6xl text-on-surface-variant">inventory_2</span>
              <h3 className="font-title-lg text-title-lg text-primary mt-md mb-sm">No listings found</h3>
              <p className="font-body-md text-body-md text-on-surface-variant mb-md">Try adjusting your filters or search terms</p>
              <Button variant="outline" onClick={clearFilters}>Clear Filters</Button>
            </div>
          ) : (
            <>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-sm">
                {filteredProducts.map(product => (
                  <Link key={product.id} to={`/listings/${product.id}`} className="card-surface border border-outline-variant rounded-lg overflow-hidden flex flex-col hover:border-primary-container transition-colors cursor-pointer group">
                    <div className="aspect-square w-full relative bg-surface-container-low overflow-hidden">
                      {product.images.length > 0 ? (
                        <img
                          src={product.images[0]}
                          alt={product.title}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-4xl">📦</div>
                      )}
                      <div className="absolute top-xs left-xs">
                        <Badge type={product.listingType} />
                      </div>
                    </div>
                    <div className="p-sm flex flex-col gap-xs flex-grow">
                      <div className="flex justify-between items-start">
                        <h3 className="font-body-md text-body-md text-on-surface line-clamp-2">{product.title}</h3>
                        <span className="material-symbols-outlined text-on-surface-variant text-sm">favorite_border</span>
                      </div>
                      <div className="mt-auto">
                        <p className="font-label-price text-label-price text-primary">
                          {product.listingType === 'FREE' ? 'FREE' : `₹${product.price.toLocaleString()}`}
                        </p>
                        <p className="font-label-sm text-label-sm text-on-surface-variant mt-xs">
                          {product.location} • {formatDistanceToNow(toDate(product.createdAt), { addSuffix: true })}
                        </p>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>

              {hasMore && (
                <div className="text-center mt-lg">
                  <Button 
                    variant="outline" 
                    onClick={() => fetchProducts(false)}
                    loading={loadingMore}
                    className="w-full sm:w-auto"
                  >
                    Load More
                  </Button>
                </div>
              )}
            </>
          )}
        </section>
      </main>
    </div>
  );
}