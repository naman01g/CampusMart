import { ListingType, ListingStatus } from '../../types';

interface BadgeProps {
  type: ListingType | ListingStatus;
  children?: React.ReactNode;
  className?: string;
}

const typeClasses: Record<string, string> = {
  SELL: 'badge-sell',
  EXCHANGE: 'badge-exchange',
  FREE: 'badge-free',
  ACTIVE: 'badge-active',
  RESERVED: 'badge-reserved',
  SOLD: 'badge-sold',
  REMOVED: 'badge-removed',
};

export function Badge({ type, children, className = '' }: BadgeProps) {
  return (
    <span className={`badge ${typeClasses[type] || ''} ${className}`}>
      {children || type}
    </span>
  );
}