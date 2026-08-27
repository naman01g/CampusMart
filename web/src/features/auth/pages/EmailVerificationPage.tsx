import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button } from '@shared/components/ui';
import { AuthError } from '@features/auth/context/AuthContext';

export function EmailVerificationPage() {
  const navigate = useNavigate();
  const { sendEmailVerification, reloadUser, isEmailVerified } = useAuth();
  const [loading, setLoading] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);
  const [error, setError] = useState('');

  useEffect(() => {
    startResendCooldown();
  }, []);

  const startResendCooldown = () => {
    setResendCooldown(60);
    const interval = setInterval(() => {
      setResendCooldown(prev => {
        if (prev <= 1) {
          clearInterval(interval);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
  };

  const handleResend = async () => {
    setError('');
    try {
      await sendEmailVerification();
      startResendCooldown();
    } catch (err) {
      setError('Failed to resend verification email');
    }
  };

  const handleCheckVerified = async () => {
    try {
      await reloadUser();
      const verified = await isEmailVerified();
      if (verified) {
        navigate('/', { replace: true });
      }
    } catch (err) {
      console.error('Verification check failed:', err);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-[calc(100vh-200px)] px-16">
      <div className="w-full max-w-md text-center">
        <div className="w-20 h-20 mx-auto mb-12 rounded-full bg-[var(--color-ochre)]/10 flex items-center justify-center">
          <svg className="w-10 h-10 mx-auto text-[var(--color-ochre)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
          </svg>
        </div>
        <h1 className="text-h2 mb-8" style={{ color: 'var(--color-charcoal)' }}>Verify your email</h1>
        <p className="text-body text-[var(--color-secondary-text)] mb-12">
          We&apos;ve sent a verification email to your AKGEC email address. Please check your inbox and click the verification link.
        </p>

        <Button
          className="w-full mb-8"
          loading={loading}
          onClick={handleCheckVerified}
        >
          I&apos;ve Verified My Email
        </Button>

        <div className="mb-8">
          {resendCooldown > 0 ? (
            <p className="text-body-sm text-[var(--color-secondary-text)]">
              Resend available in {resendCooldown} seconds
            </p>
          ) : (
            <Button
              variant="ghost"
              onClick={handleResend}
              disabled={loading}
            >
              Resend Verification Email
            </Button>
          )}
        </div>

        <p className="text-body-sm text-[var(--color-secondary-text)]">
          <Link to="/login" style={{ color: 'var(--color-ochre)', fontWeight: 500 }}>
            Back to Login
          </Link>
        </p>
      </div>
    </div>
  );
}