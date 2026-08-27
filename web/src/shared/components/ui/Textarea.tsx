import { TextareaHTMLAttributes, forwardRef } from 'react';

interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  helperText?: string;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, error, helperText, className = '', id, ...props }, ref) => {
    const textareaId = id || label?.toLowerCase().replace(/\s+/g, '-');

    return (
      <div className="w-full">
        {label && <label htmlFor={textareaId} className="label">{label}</label>}
        <textarea
          ref={ref}
          id={textareaId}
          className={`input ${error ? 'input-error' : ''} ${className}`}
          aria-invalid={error ? 'true' : 'false'}
          aria-describedby={error ? `${textareaId}-error` : helperText ? `${textareaId}-helper` : undefined}
          {...props}
        />
        {error && <p id={`${textareaId}-error`} className="text-caption mt-2" style={{ color: 'var(--color-error)' }}>{error}</p>}
        {helperText && !error && <p id={`${textareaId}-helper`} className="text-caption mt-2 text-[var(--color-secondary-text)]">{helperText}</p>}
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';