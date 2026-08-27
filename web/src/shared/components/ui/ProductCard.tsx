import { Link } from 'react-router-dom';
import { Product, ListingType } from '@shared/types';
import { formatDistanceToNow } from 'date-fns';
import { toDate } from '@shared/types';

interface ProductCardProps {
  product: Product;
  showFavorite?: boolean;
  onFavoriteToggle?: (productId: string) => void;
  isFavorited?: boolean;
  variant?: 'default' | 'compact' | 'featured';
  showListingType?: boolean;
  className?: string;
}

const listingTypeClasses: Record<ListingType, string> = {
  SELL: 'badge-sell',
  EXCHANGE: 'badge-exchange',
  FREE: 'badge-free',
};

export function ProductCard({
  product,
  showFavorite = false,
  onFavoriteToggle,
  isFavorited = false,
  variant = 'default',
  showListingType = true,
  className = '',
}: ProductCardProps) {
  const priceDisplay = product.listingType === 'FREE' ? 'FREE' : `₹${product.price.toLocaleString()}`;
  const timeAgo = formatDistanceToNow(toDate(product.createdAt), { addSuffix: true });

  const cardContent = (
    <Link
      to={`/listings/${product.id}`}
      className={`card-surface border border-[var(--color-border)] overflow-hidden flex flex-col transition-colors hover:border-[var(--color-charcoal)] ${className}`}
    >
      <div className="relative aspect-[4/3] bg-[var(--color-surface-container)] overflow-hidden">
        {product.images.length > 0 ? (
          <img
            src={product.images[0]}
            alt={product.title}
            className="w-full h-full object-cover transition-transform duration-300 hover:scale-[1.02]"
            loading="lazy"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-[var(--color-secondary-text)] text-4xl">
            <span className="material-symbols-outlined">inventory_2</span>
          </div>
        )}
        {(showListingType || variant === 'featured') && (
          <span className={`absolute top-2 left-2 badge ${listingTypeClasses[product.listingType] || ''} text-xs`}>
            {product.listingType}
          </span>
        )}
        {showFavorite && (
          <button
            className={`absolute top-2 right-2 w-8 h-8 rounded-full bg-[var(--color-surface)]/90 backdrop-blur-sm flex items-center justify-center transition-colors hover:bg-[var(--color-surface-container)] ${isFavorited ? 'text-[var(--color-error)]' : 'text-[var(--color-secondary-text)] hover:text-[var(--color-error)]'}`}
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              onFavoriteToggle?.(product.id);
            }}
            aria-label={isFavorited ? 'Remove from favorites' : 'Add to favorites'}
          >
            <span className="material-symbols-outlined text-[20px]" data-icon={isFavorited ? 'favorite' : 'favorite_border'}>
              {isFavorited ? 'favorite' : 'favorite_border'}
            </span>
          </button>
        )}
      </div>
      <div className="p-4 flex flex-col flex-1">
        <h3 className="font-medium text-[var(--color-primary-text)] line-clamp-2 leading-snug mb-2">
          {product.title}
        </h3>
        <div className="flex items-center gap-2 text-sm text-[var(--color-secondary-text)] mb-2">
          <span className="material-symbols-outlined text-[14px]">location_on</span>
          <span className="truncate">{product.location}</span>
        </div>
        <div className="flex items-center justify-between mt-auto">
          <span className="font-bold text-lg text-[var(--color-primary-text)]">{priceDisplay}</span>
          <span className="text-xs text-[var(--color-secondary-text)]">{timeAgo}</span>
        </div>
      </div>
    </Link>
  );

  if (variant === 'featured') {
    return (
      <Link
        to={`/listings/${product.id}`}
        className="card-surface border border-[var(--color-border)] overflow-hidden flex flex-col transition-colors hover:border-[var(--color-charcoal)]"
      >
        <div className="relative aspect-video bg-[var(--color-surface-container)] overflow-hidden">
          {product.images.length > 0 ? (
            <img
              src={product.images[0]}
              alt={product.title}
              className="w-full h-full object-cover transition-transform duration-500 hover:scale-[1.02]"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-[var(--color-secondary-text)] text-6xl">
              <span className="material-symbols-outlined">inventory_2</span>
            </div>
          )}
          <div className="absolute top-3 right-3 bg-[var(--color-surface)]/95 backdrop-blur-sm border border-[var(--color-border)] rounded-lg px-3 py-1 flex items-center gap-1">
            <span className="material-symbols-outlined text-[14px] text-[var(--color-secondary-text)]">location_on</span>
            <span className="text-sm font-medium text-[var(--color-primary-text)]">{product.location}</span>
          </div>
        </div>
        <div className="p-6 space-y-3">
          <div className="flex justify-between items-start gap-4">
            <div className="min-w-0">
              <h3 className="text-xl font-semibold text-[var(--color-primary-text)] leading-tight mb-1 line-clamp-2">
                {product.title}
              </h3>
              <p className="text-sm text-[var(--color-secondary-text)]">{product.condition} • {product.category}</p>
            </div>
            <span className="text-xl font-bold text-[var(--color-primary-text)] flex-shrink-0">
              {priceDisplay}
            </span>
          </div>
          <div className="flex items-center gap-2 text-sm text-[var(--color-secondary-text)] pt-2 border-t border-[var(--color-border)]">
            <span className="material-symbols-outlined text-[16px]">schedule</span>
            Posted {timeAgo}
          </div>
        </div>
      </Link>
    );
  }

  return cardContent;
}