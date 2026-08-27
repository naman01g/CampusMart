import { Link } from 'react-router-dom';
import { Button } from './Button';

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  action?: {
    label: string;
    href?: string;
    onClick?: () => void;
    variant?: 'primary' | 'outline' | 'ghost';
  };
  className?: string;
}

export function PageHeader({
  title,
  subtitle,
  action,
  className = '',
}: PageHeaderProps) {
  return (
    <header className={`space-y-2 ${className}`}>
      <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-[var(--color-primary-text)] tracking-tight">{title}</h1>
          {subtitle && (
            <p className="text-base text-[var(--color-secondary-text)] mt-1">{subtitle}</p>
          )}
        </div>
        {action && (
          action.href ? (
            <Link
              to={action.href}
              className={`btn btn-${action.variant || 'primary'} btn-sm`}
            >
              {action.label}
            </Link>
          ) : (
            <Button
              variant={action.variant || 'primary'}
              size="sm"
              onClick={action.onClick}
            >
              {action.label}
            </Button>
          )
        )}
      </div>
    </header>
  );
}