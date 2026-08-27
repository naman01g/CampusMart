import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Badge, Card, CardContent, Input, Textarea } from '@shared/components/ui';
import { Product, ListingType, ListingStatus, User, toDate, ReportTargetType } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { doc, getDoc, updateDoc, increment, serverTimestamp, deleteDoc } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';
import { findOrCreateChat } from '@shared/services/chatService';
import { submitReport, REPORT_REASONS } from '@shared/services/reportService';

export function ListingDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user, refreshUser } = useAuth();
  const [product, setProduct] = useState<Product | null>(null);
  const [seller, setSeller] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [favorited, setFavorited] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [showReportDialog, setShowReportDialog] = useState(false);
  const [reportReason, setReportReason] = useState('');
  const [reportDescription, setReportDescription] = useState('');
  const [reportSubmitting, setReportSubmitting] = useState(false);

  useEffect(() => {
    if (id) {
      fetchProduct();
      checkFavorite();
    }
  }, [id]);

  const fetchProduct = async () => {
    if (!id) return;
    try {
      const db = getFirebaseDb();
      const productDoc = await getDoc(doc(db, 'products', id));
      if (productDoc.exists()) {
        const data = { id: productDoc.id, ...productDoc.data() } as Product;
        setProduct(data);
        await updateDoc(doc(db, 'products', id), { views: increment(1) });
        
        // Fetch seller info
        if (data.sellerId) {
          const sellerDoc = await getDoc(doc(db, 'users', data.sellerId));
          if (sellerDoc.exists()) {
            setSeller({ uid: sellerDoc.id, ...sellerDoc.data() } as User);
          }
        }
      } else {
        navigate('/listings');
      }
    } catch (error) {
      console.error('Error fetching product:', error);
      setError('Failed to load listing. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const checkFavorite = async () => {
    if (!user || !id) return;
    try {
      const db = getFirebaseDb();
      const favoritesRef = doc(db, 'favorites', `${user.uid}_${id}`);
      const favDoc = await getDoc(favoritesRef);
      setFavorited(favDoc.exists());
    } catch (error) {
      console.error('Error checking favorite:', error);
    }
  };

  const toggleFavorite = async () => {
    if (!user || !id) return;
    setActionLoading(true);
    try {
      const db = getFirebaseDb();
      const favoritesRef = doc(db, 'favorites', `${user.uid}_${id}`);
      const favDoc = await getDoc(favoritesRef);
      
      if (favDoc.exists()) {
        await deleteDoc(favoritesRef);
        await updateDoc(doc(db, 'products', id), { favoritesCount: increment(-1) });
        setFavorited(false);
      } else {
        await updateDoc(doc(db, 'products', id), { favoritesCount: increment(1) });
        await updateDoc(favoritesRef, {
          userId: user.uid,
          productId: id,
          createdAt: serverTimestamp(),
        });
        setFavorited(true);
      }
      await refreshUser();
    } catch (error) {
      console.error('Error toggling favorite:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleContactSeller = async () => {
    if (!user) {
      navigate('/login', { state: { from: `/listings/${id}` } });
      return;
    }
    if (!product || !id) return;
    if (product.sellerId === user.uid) {
      alert('This is your own listing');
      return;
    }
    
    setActionLoading(true);
    try {
      const result = await findOrCreateChat(user.uid, product.sellerId, id);
      navigate(`/chat/${result.chatId}`);
    } catch (error) {
      console.error('Error creating chat:', error);
      alert('Failed to start conversation. Please try again.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleShare = async () => {
    const shareData = {
      title: product?.title,
      text: product?.description,
      url: window.location.href,
    };
    
    try {
      if (navigator.share && navigator.canShare(shareData)) {
        await navigator.share(shareData);
      } else {
        await navigator.clipboard.writeText(window.location.href);
        alert('Link copied to clipboard!');
      }
    } catch (error) {
      if (error instanceof Error && error.name !== 'AbortError') {
        console.error('Share failed:', error);
      }
    }
  };

  const handleMarkSold = async () => {
    if (!product || product.sellerId !== user?.uid) return;
    if (!confirm('Mark this listing as sold?')) return;
    
    setActionLoading(true);
    try {
      const db = getFirebaseDb();
      await updateDoc(doc(db, 'products', id!), { status: 'SOLD', updatedAt: serverTimestamp() });
      setProduct(prev => prev ? { ...prev, status: 'SOLD' } : null);
    } catch (error) {
      console.error('Error marking sold:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!product || product.sellerId !== user?.uid) return;
    if (!confirm('Delete this listing permanently?')) return;
    
    setActionLoading(true);
    try {
      const db = getFirebaseDb();
      await updateDoc(doc(db, 'products', id!), { status: 'REMOVED', updatedAt: serverTimestamp() });
      navigate('/my-listings');
    } catch (error) {
      console.error('Error deleting:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleReport = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !id || !reportReason) return;
    
    setReportSubmitting(true);
    try {
      await submitReport({
        targetType: 'product',
        targetId: id,
        reason: reportReason,
        description: reportDescription || undefined,
      });
      setShowReportDialog(false);
      setReportReason('');
      setReportDescription('');
      alert('Report submitted successfully. Our team will review it.');
    } catch (error) {
      console.error('Error submitting report:', error);
      alert('Failed to submit report. Please try again.');
    } finally {
      setReportSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="container py-lg">
        <div className="max-w-container-max mx-auto">
          <div className="card-surface p-xl animate-pulse">
            <div className="aspect-square bg-surface-container-low rounded-lg mb-lg" />
            <div className="h-8 bg-surface-container-highest rounded w-3/4 mb-lg" />
            <div className="h-6 bg-surface-container-highest rounded w-1/2 mb-xl" />
            <div className="h-4 bg-surface-container-highest rounded w-full mb-lg" />
            <div className="h-4 bg-surface-container-highest rounded w-full mb-lg" />
            <div className="h-4 bg-surface-container-highest rounded w-2/3" />
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container py-lg text-center">
        <span className="material-symbols-outlined text-6xl text-error">error_outline</span>
        <h2 className="font-title-lg text-title-lg text-primary mt-md mb-sm">Failed to load listing</h2>
        <p className="font-body-md text-body-md text-on-surface-variant mb-lg">{error}</p>
        <Button variant="outline" onClick={() => window.location.reload()}>Retry</Button>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="container py-lg text-center">
        <h2 className="font-title-lg text-title-lg text-primary">Listing not found</h2>
        <Link to="/listings" className="btn btn-primary mt-lg inline-block">Browse Listings</Link>
      </div>
    );
  }

  const isOwner = product.sellerId === user?.uid;
  const isSold = product.status === 'SOLD' || product.status === 'REMOVED';

  return (
    <div className="flex-1">
      <main className="container py-lg max-w-container-max mx-auto">
        <nav className="mb-lg" aria-label="Breadcrumb">
          <ol className="flex items-center gap-xs font-body-md text-body-md text-on-surface-variant">
            <li><Link to="/" className="hover:text-on-surface">Home</Link></li>
            <li><span className="material-symbols-outlined text-[16px]">chevron_right</span></li>
            <li><Link to="/listings" className="hover:text-on-surface">Listings</Link></li>
            <li><span className="material-symbols-outlined text-[16px]">chevron_right</span></li>
            <li className="text-on-surface truncate max-w-xs">{product.title}</li>
          </ol>
        </nav>

        <div className="grid lg:grid-cols-12 gap-lg">
          {/* Left Column: Image Gallery */}
          <div className="lg:col-span-7 flex flex-col gap-sm">
            <div className="w-full aspect-square bg-surface-container-lowest border border-outline-variant rounded-lg overflow-hidden relative group">
              {product.images.length > 0 ? (
                <img
                  src={product.images[currentImageIndex]}
                  alt={product.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-6xl">📦</div>
              )}
              <div className="absolute bottom-sm right-sm bg-surface-white/90 backdrop-blur-sm px-sm py-xs border border-outline-variant rounded-lg font-label-sm text-label-sm text-on-surface">
                {currentImageIndex + 1}/{product.images.length}
              </div>
            </div>
            {/* Thumbnail Strip */}
            {product.images.length > 1 && (
              <div className="grid grid-cols-4 gap-sm">
                {product.images.map((image, index) => (
                  <button
                    key={index}
                    onClick={() => setCurrentImageIndex(index)}
                    className={`aspect-square bg-surface-container-lowest border rounded-lg overflow-hidden cursor-pointer hover:border-primary transition-colors ${
                      index === currentImageIndex ? 'border-2 border-primary' : 'border border-outline-variant'
                    }`}
                  >
                    <img
                      src={image}
                      alt={`Image ${index + 1}`}
                      className="w-full h-full object-cover"
                    />
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Right Column: Details & Actions */}
          <div className="lg:col-span-5 flex flex-col gap-lg">
            {/* Title & Price Block */}
            <div className="flex flex-col gap-sm">
              <div className="flex justify-between items-start">
                <h1 className="font-headline-lg-mobile text-headline-lg-mobile md:font-headline-lg md:text-headline-lg text-on-surface">{product.title}</h1>
                <div className="flex items-center gap-sm">
                  <button className="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-full border border-outline-variant bg-surface-white hover:border-charcoal transition-colors" onClick={handleShare} aria-label="Share">
                    <span className="material-symbols-outlined text-on-surface" data-icon="share">share</span>
                  </button>
                  <button className="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-full border border-outline-variant bg-surface-white hover:border-charcoal transition-colors ml-sm" onClick={toggleFavorite}>
                    <span className="material-symbols-outlined text-on-surface" data-icon="favorite_border">{favorited ? 'favorite' : 'favorite_border'}</span>
                  </button>
                </div>
              </div>
              <p className="font-label-price text-label-price text-primary">{product.listingType === 'FREE' ? 'FREE' : `₹${product.price.toLocaleString()}`}</p>
              <p className="font-body-md text-body-md text-on-surface-variant flex items-center gap-xs">
                <span className="material-symbols-outlined text-[16px]" data-icon="schedule">schedule</span> Posted {formatDistanceToNow(toDate(product.createdAt), { addSuffix: true })}
              </p>
            </div>
            {/* Chips / Quick Specs */}
            <div className="flex flex-wrap gap-sm">
              <span className="chip px-sm py-xs font-label-sm text-label-sm">{product.category}</span>
              <span className="chip px-sm py-xs font-label-sm text-label-sm">{product.condition}</span>
              {product.isNegotiable && product.listingType === 'SELL' && (
                <span className="chip px-sm py-xs font-label-sm text-label-sm" style={{ backgroundColor: 'var(--color-ochre-light)', color: 'var(--color-ochre)' }}>Negotiable</span>
              )}
            </div>
            <hr className="border-outline-variant"/>
            {/* Description Block */}
            <div className="flex flex-col gap-sm">
              <h2 className="font-title-lg text-title-lg text-on-surface">Description</h2>
              <p className="font-body-md text-body-md text-on-surface">{product.description}</p>
            </div>
            {/* Meetup Location */}
            <div className="card-surface p-md flex gap-md items-center">
              <div className="w-12 h-12 rounded-full bg-surface-container-highest flex items-center justify-center flex-shrink-0">
                <span className="material-symbols-outlined text-on-surface" data-icon="location_on">location_on</span>
              </div>
              <div className="flex-1">
                <h3 className="font-title-lg text-title-lg text-on-surface">Meetup Location</h3>
                <p className="font-body-md text-body-md text-on-surface-variant">{product.location}</p>
              </div>
            </div>
            {/* Seller Block */}
            <div className="card-surface p-md flex flex-col gap-md">
              <h2 className="font-title-lg text-title-lg text-on-surface">Seller Information</h2>
              <div className="flex items-center gap-md">
                <div className="w-16 h-16 rounded-full border border-outline-variant overflow-hidden bg-surface-container-highest flex-shrink-0">
                  {seller?.profileImage ? (
                    <img src={seller.profileImage} alt={seller.name || 'Seller'} className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full bg-cover bg-center" style={{ backgroundImage: `url(https://ui-avatars.com/api/?name=${encodeURIComponent(seller?.name || 'User')}&background=E38F2D&color=fff)` }} />
                  )}
                </div>
                <div className="flex-1 flex flex-col justify-center">
                  <div className="flex items-center gap-xs">
                    <span className="font-title-lg text-title-lg text-on-surface leading-none">{seller?.name || 'Unknown'}</span>
                    {seller?.isVerified && (
                      <span className="material-symbols-outlined text-on-tertiary-container text-[18px]" data-icon="verified" data-weight="fill" style={{ fontVariationSettings: "'FILL' 1" }}>verified</span>
                    )}
                  </div>
                  <p className="font-body-md text-body-md text-on-surface-variant leading-snug mt-xs">{seller?.course} • {seller?.branch} • Year {seller?.year}</p>
                  <p className="font-label-sm text-label-sm text-on-surface-variant mt-sm">Seller</p>
                </div>
                {!isOwner && user && (
                  <button
                    className="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-full border border-outline-variant bg-surface-white hover:border-charcoal transition-colors ml-auto text-error"
                    onClick={() => setShowReportDialog(true)}
                    aria-label="Report listing"
                  >
                    <span className="material-symbols-outlined" data-icon="flag">flag</span>
                  </button>
                )}
                {isOwner && (
                  <button className="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-full border border-outline-variant bg-surface-white hover:border-charcoal transition-colors ml-auto">
                    <span className="material-symbols-outlined text-on-surface" data-icon="chevron_right">chevron_right</span>
                  </button>
                )}
              </div>
            </div>
            {/* Quick Actions Block (Desktop placement) */}
            <div className="hidden lg:flex flex-col gap-sm">
              <h3 className="font-label-sm text-label-sm text-on-surface-variant">Quick Actions</h3>
              <button className="btn-ghost w-full py-sm px-md flex items-center justify-between hover:border-charcoal transition-colors">
                <span className="font-body-md text-body-md text-on-surface">Hi, is this still available?</span>
                <span className="material-symbols-outlined text-[20px]" data-icon="send">send</span>
              </button>
              <Button variant="primary" className="w-full py-sm px-md flex items-center justify-center gap-xs font-title-lg text-title-lg" onClick={handleContactSeller} disabled={actionLoading || isOwner || isSold}>
                <span className="material-symbols-outlined" data-icon="chat">chat</span>
                <span>Contact Seller</span>
              </Button>
            </div>
          </div>
        </div>
      </main>

      {/* Sticky Bottom Action Bar (Mobile & Desktop) */}
      <div className="fixed bottom-0 w-full z-50 bg-surface-white border-t border-outline-variant p-md flex flex-col md:flex-row gap-sm pb-safe md:px-gutter lg:justify-center">
        {/* Quick Action (Mobile only in sticky bar to save space above) */}
        <div className="lg:hidden w-full max-w-container-max mx-auto mb-sm">
          <button className="btn-ghost w-full py-xs px-md flex items-center justify-between hover:border-charcoal transition-colors text-left">
            <span className="font-body-md text-body-md text-on-surface-variant truncate">Hi, is this still available?</span>
            <span className="material-symbols-outlined text-[18px] text-on-surface-variant" data-icon="send">send</span>
          </button>
        </div>
        <div className="flex gap-sm w-full max-w-container-max mx-auto lg:max-w-md">
          <Button variant="ghost" className="flex-1 h-12 flex items-center justify-center gap-xs font-title-lg text-title-lg hover:border-charcoal hover:text-charcoal transition-colors" onClick={toggleFavorite}>
            <span className="material-symbols-outlined" data-icon="bookmark_border">{favorited ? 'favorite' : 'bookmark_border'}</span>
            <span>{favorited ? 'Saved' : 'Save'}</span>
          </Button>
          <Button variant="primary" className="flex-1 h-12 flex items-center justify-center gap-xs font-title-lg text-title-lg hover:bg-ochre-light transition-colors" onClick={handleContactSeller} disabled={actionLoading || isOwner || isSold}>
            <span className="material-symbols-outlined" data-icon="chat">chat</span>
            <span>Contact Seller</span>
          </Button>
        </div>
      </div>

      {/* Report Dialog */}
      {showReportDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-md" role="dialog" aria-modal="true" aria-labelledby="report-dialog-title">
          <div className="card-surface w-full max-w-md mx-auto p-lg rounded-lg shadow-xl">
            <h2 id="report-dialog-title" className="font-title-lg text-title-lg text-on-surface mb-md">Report Listing</h2>
            <p className="font-body-md text-body-md text-on-surface-variant mb-lg">
              Help keep CampusMart safe. Your report is anonymous.
            </p>
            <form onSubmit={handleReport} className="space-y-md">
              <div>
                <label className="label">Reason</label>
                <select
                  value={reportReason}
                  onChange={(e) => setReportReason(e.target.value)}
                  className="input w-full"
                  required
                >
                  <option value="">Select a reason</option>
                  {REPORT_REASONS.map(r => (
                    <option key={r.value} value={r.value}>{r.label}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="label">Additional details (optional)</label>
                <Textarea
                  value={reportDescription}
                  onChange={(e) => setReportDescription(e.target.value)}
                  placeholder="Any additional information..."
                  rows={3}
                  maxLength={500}
                />
              </div>
              <div className="flex gap-sm pt-md">
                <Button type="button" variant="outline" className="flex-1" onClick={() => setShowReportDialog(false)}>
                  Cancel
                </Button>
                <Button type="submit" variant="primary" className="flex-1" loading={reportSubmitting}>
                  Submit Report
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}