import { ListingType } from '@shared/types';
import { Input } from './Input';
import { Button } from './Button';
import { Link } from 'react-router-dom';

interface FilterBarProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  onSearchSubmit?: (query: string) => void;
  placeholder?: string;
  showCreateButton?: boolean;
  createButtonHref?: string;
  className?: string;
}

export function FilterBar({
  searchQuery,
  onSearchChange,
  onSearchSubmit,
  placeholder = 'Search listings...',
  showCreateButton = false,
  createButtonHref = '/sell',
  className = '',
}: FilterBarProps) {
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSearchSubmit?.(searchQuery);
  };

  return (
    <form onSubmit={handleSubmit} className={`card-surface border border-[var(--color-border)] p-4 ${className}`}>
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-secondary-text)] text-lg" data-icon="search">
            search
          </span>
<input
              type="text"
              placeholder={placeholder}
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              className="w-full pl-10 pr-10 py-2.5 bg-[var(--color-surface)] border border-[var(--color-border)] rounded-lg text-[var(--color-primary-text)] placeholder-[var(--color-secondary-text)] focus:outline-none focus:border-[var(--color-ochre)] transition-colors"
            />
        </div>
        {showCreateButton && (
          <Link to={createButtonHref} className="btn btn-primary btn-sm">
            Create Listing
          </Link>
        )}
      </div>
    </form>
  );
}