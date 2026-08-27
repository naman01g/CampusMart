import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Input } from '@shared/components/ui';
import { AuthError } from '@features/auth/context/AuthContext';

export function ForgotPasswordPage() {
  const navigate = useNavigate();
  const { resetPassword } = useAuth();
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await resetPassword(email);
      setSuccess(true);
    } catch (err) {
      if (err instanceof AuthError) {
        setError(err.message);
      } else {
        setError('Failed to send reset email');
      }
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="flex items-center justify-center min-h-[calc(100vh-200px)] px-16">
        <div className="w-full max-w-md text-center">
          <div className="w-16 h-16 mx-auto mb-16 rounded-full bg-[var(--color-success)]/10 flex items-center justify-center">
            <svg className="w-8 h-8" style={{ color: 'var(--color-success)' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h1 className="text-h3" style={{ color: 'var(--color-charcoal)' }}>Check your email</h1>
          <p className="text-body mt-8 text-[var(--color-secondary-text)]">
            We&apos;ve sent a password reset link to <strong>{email}</strong>. Please check your inbox.
          </p>
          <Button className="mt-24" onClick={() => navigate('/login')}>
            Back to Login
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex items-center justify-center min-h-[calc(100vh-200px)] px-16">
      <div className="w-full max-w-md">
        <div className="text-center mb-24">
          <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Reset password</h1>
          <p className="text-body mt-8 text-[var(--color-secondary-text)]">Enter your AKGEC email and we&apos;ll send you a reset link</p>
        </div>

        <form onSubmit={handleSubmit} className="card p-24" noValidate>
          {error && (
            <div className="mb-16 p-12 rounded-lg bg-[var(--color-error)]/10 text-[var(--color-error)] text-body-sm">
              {error}
            </div>
          )}

          <Input
            label="AKGEC Email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="student@akgec.ac.in"
            required
            autoComplete="email"
            disabled={loading}
          />

          <Button type="submit" className="mt-24 w-full" loading={loading}>
            Send Reset Link
          </Button>
        </form>

        <p className="text-center text-body-sm text-[var(--color-secondary-text)] mt-24">
          <Link to="/login" style={{ color: 'var(--color-ochre)', fontWeight: 500 }}>Back to Login</Link>
        </p>
      </div>
    </div>
  );
}