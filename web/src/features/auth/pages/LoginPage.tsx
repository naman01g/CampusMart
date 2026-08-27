import { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Input } from '@shared/components/ui';
import { AuthError } from '@features/auth/context/AuthContext';

export function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const from = (location.state as { from?: Location })?.from?.pathname || '/';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
      navigate(from, { replace: true });
    } catch (err) {
      if (err instanceof AuthError) {
        setError(err.message);
      } else {
        setError('Invalid email or password');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-[calc(100vh-200px)] px-16">
      <div className="w-full max-w-md">
        <div className="text-center mb-24">
          <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Welcome back</h1>
          <p className="text-body mt-8 text-[var(--color-secondary-text)]">Sign in to your CampusMart account</p>
        </div>

        <form onSubmit={handleSubmit} className="card p-24" noValidate>
          {error && (
            <div className="mb-16 p-12 rounded-lg bg-[var(--color-error)]/10 text-[var(--color-error)] text-body-sm">
              {error}
            </div>
          )}

          <Input
            label="Email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="student@akgec.ac.in"
            required
            autoComplete="email"
            disabled={loading}
          />

          <div className="mt-16">
            <Input
              label="Password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              autoComplete="current-password"
              disabled={loading}
            />
          </div>

          <div className="mt-8 text-right">
            <Link to="/forgot-password" className="text-body-sm" style={{ color: 'var(--color-ochre)' }}>
              Forgot password?
            </Link>
          </div>

          <Button type="submit" className="mt-24 w-full" loading={loading}>
            Sign In
          </Button>
        </form>

        <p className="text-center text-body-sm text-[var(--color-secondary-text)] mt-24">
          Don&apos;t have an account? <Link to="/register" style={{ color: 'var(--color-ochre)', fontWeight: 500 }}>Sign up</Link>
        </p>
      </div>
    </div>
  );
}