import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Input } from '@shared/components/ui';
import { AuthError } from '@features/auth/context/AuthContext';

export function RegisterPage() {
  const navigate = useNavigate();
  const { register } = useAuth();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }

    if (!email.endsWith('@akgec.ac.in')) {
      setError('Use your AKGEC student email to continue.');
      return;
    }

    setLoading(true);
    try {
      await register(email, password, name);
      navigate('/', { replace: true });
    } catch (err) {
      if (err instanceof AuthError) {
        setError(err.message);
      } else if (err instanceof Error) {
        if (err.message.includes('auth/email-already-in-use')) {
          setError('An account with this email already exists');
        } else if (err.message.includes('auth/invalid-email')) {
          setError('Invalid email address');
        } else if (err.message.includes('auth/weak-password')) {
          setError('Password is too weak');
        } else {
          setError(err.message);
        }
      } else {
        setError('Registration failed');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-[calc(100vh-200px)] px-16">
      <div className="w-full max-w-md">
        <div className="text-center mb-24">
          <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Create your account</h1>
          <p className="text-body mt-8 text-[var(--color-secondary-text)]">Join CampusMart with your AKGEC email</p>
        </div>

        <form onSubmit={handleSubmit} className="card p-24" noValidate>
          {error && (
            <div className="mb-16 p-12 rounded-lg bg-[var(--color-error)]/10 text-[var(--color-error)] text-body-sm">
              {error}
            </div>
          )}

          <Input
            label="Full Name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="John Doe"
            required
            autoComplete="name"
            disabled={loading}
          />

          <div className="mt-16">
            <Input
              label="AKGEC Email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="student@akgec.ac.in"
              required
              autoComplete="email"
              disabled={loading}
              helperText="Must be a valid AKGEC email address"
            />
          </div>

          <div className="mt-16">
            <Input
              label="Password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              autoComplete="new-password"
              disabled={loading}
              helperText="At least 6 characters"
            />
          </div>

          <div className="mt-16">
            <Input
              label="Confirm Password"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="••••••••"
              required
              autoComplete="new-password"
              disabled={loading}
            />
          </div>

          <Button type="submit" className="mt-24 w-full" loading={loading}>
            Create Account
          </Button>
        </form>

        <p className="text-center text-body-sm text-[var(--color-secondary-text)] mt-24">
          Already have an account? <Link to="/login" style={{ color: 'var(--color-ochre)', fontWeight: 500 }}>Sign in</Link>
        </p>
      </div>
    </div>
  );
}