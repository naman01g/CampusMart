import { Button } from './Button';
import { Link } from 'react-router-dom';

interface EmptyStateProps {
  icon?: string;
  title: string;
  description?: string;
  actionLabel?: string;
  actionHref?: string;
  actionOnClick?: () => void;
  variant?: 'default' | 'centered';
  className?: string;
}

export function EmptyState({
  icon = 'inventory_2',
  title,
  description,
  actionLabel,
  actionHref,
  actionOnClick,
  variant = 'default',
  className = '',
}: EmptyStateProps) {
  const content = (
    <div className={`flex flex-col items-center text-center py-16 ${className}`}>
      <span className="material-symbols-outlined text-6xl text-[var(--color-secondary-text)] mb-4" data-icon={icon}>
        {icon}
      </span>
      <h3 className="text-xl font-semibold text-[var(--color-primary-text)] mb-2">{title}</h3>
      {description && (
        <p className="text-base text-[var(--color-secondary-text)] max-w-sm mb-6">{description}</p>
      )}
      {actionLabel && (
        actionHref ? (
          <Link
            to={actionHref}
            className="btn btn-primary w-full sm:w-auto"
          >
            {actionLabel}
          </Link>
        ) : (
          <Button
            variant="primary"
            className="w-full sm:w-auto"
            onClick={actionOnClick}
          >
            {actionLabel}
          </Button>
        )
      )}
    </div>
  );

  if (variant === 'centered') {
    return (
      <div className="flex-1 flex items-center justify-center px-4">
        {content}
      </div>
    );
  }

  return content;
}