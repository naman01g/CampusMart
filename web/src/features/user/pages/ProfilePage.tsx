import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Input, Card, CardContent } from '@shared/components/ui';
import { User } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { uploadToCloudinary, validateImageFile, createImagePreview } from '@shared/utils/cloudinary';

export function ProfilePage() {
  const { user, refreshUser } = useAuth();
  const navigate = useNavigate();
  const [profile, setProfile] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [avatarLoading, setAvatarLoading] = useState(false);
  
  const [name, setName] = useState('');
  const [course, setCourse] = useState('');
  const [branch, setBranch] = useState('');
  const [year, setYear] = useState(1);
  const [profileImage, setProfileImage] = useState<string>('');
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (user) {
      fetchProfile();
    }
  }, [user]);

  const fetchProfile = async () => {
    if (!user) return;
    try {
      const db = getFirebaseDb();
      const userDoc = await getDoc(doc(db, 'users', user.uid));
      if (userDoc.exists()) {
        const data = userDoc.data() as User;
        setProfile(data);
        setName(data.name);
        setCourse(data.course);
        setBranch(data.branch);
        setYear(data.year);
        setProfileImage(data.profileImage || '');
      }
    } catch (error) {
      console.error('Error fetching profile:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    
    const validation = validateImageFile(file);
    if (!validation.valid) {
      setErrors({ avatar: validation.error! });
      return;
    }

    setAvatarFile(file);
    setErrors({ avatar: '' });
    
    const preview = await createImagePreview(file);
    setProfileImage(preview);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    const newErrors: Record<string, string> = {};
    if (!name.trim()) newErrors.name = 'Name is required';
    if (!course.trim()) newErrors.course = 'Course is required';
    if (!branch.trim()) newErrors.branch = 'Branch is required';
    if (year < 1 || year > 5) newErrors.year = 'Invalid year';
    
    setErrors(newErrors);
    if (Object.keys(newErrors).length > 0) return;

    setSaving(true);
    try {
      const db = getFirebaseDb();
      const updateData: Partial<User> = {
        name: name.trim(),
        course: course.trim(),
        branch: branch.trim(),
        year,
        updatedAt: serverTimestamp(),
      };

      if (avatarFile) {
        const url = await uploadToCloudinary(avatarFile);
        updateData.profileImage = url;
      }

      await updateDoc(doc(db, 'users', user.uid), updateData);
      await refreshUser();
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (error) {
      console.error('Error updating profile:', error);
      setErrors({ submit: 'Failed to update profile' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="container py-16">
        <div className="max-w-md mx-auto">
          <div className="card p-24 animate-pulse">
            <div className="flex items-center gap-12 mb-16">
              <div className="w-20 h-20 rounded-full bg-[var(--color-border)]" />
              <div>
                <div className="h-6 bg-[var(--color-border)] rounded w-1/2 mb-8" />
                <div className="h-4 bg-[var(--color-border)] rounded w-1/3" />
              </div>
            </div>
            <div className="h-6 bg-[var(--color-border)] rounded w-full mb-16" />
            <div className="h-6 bg-[var(--color-border)] rounded w-full" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1">
      <div className="container py-16">
        <div className="max-w-md mx-auto">
          <h1 className="text-h2 mb-24" style={{ color: 'var(--color-charcoal)' }}>Profile</h1>

          {success && (
            <div className="mb-20 p-12 rounded-lg bg-[var(--color-success)]/10 text-[var(--color-success)] text-body-sm">
              Profile updated successfully
            </div>
          )}

          <form onSubmit={handleSave} className="card" noValidate>
            <CardContent>
              <div className="flex flex-col items-center gap-12 mb-24">
                <div className="relative">
                  <img
                    src={profileImage || `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'User')}&background=E38F2D&color=fff&size=200`}
                    alt={name || 'Profile'}
                    className="w-24 h-24 rounded-full object-cover"
                  />
                  <label className="absolute bottom-0 right-0 w-8 h-8 rounded-full bg-[var(--color-ochre)] text-white flex items-center justify-center cursor-pointer hover:opacity-90 transition-opacity">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleAvatarChange}
                      className="hidden"
                    />
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                  </label>
                </div>
                {errors.avatar && <p className="text-caption" style={{ color: 'var(--color-error)' }}>{errors.avatar}</p>}
              </div>

              <div className="mb-20">
                <Input
                  label="Full Name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  error={errors.name}
                />
              </div>

              <div className="mb-20">
                <Input
                  label="Course"
                  value={course}
                  onChange={(e) => setCourse(e.target.value)}
                  placeholder="e.g., B.Tech, M.Tech, B.Sc"
                  error={errors.course}
                />
              </div>

              <div className="mb-20">
                <Input
                  label="Branch"
                  value={branch}
                  onChange={(e) => setBranch(e.target.value)}
                  placeholder="e.g., Computer Science, Mechanical"
                  error={errors.branch}
                />
              </div>

              <div className="mb-20">
                <label className="label">Year</label>
                <select
                  value={year}
                  onChange={(e) => setYear(Number(e.target.value))}
                  className={`input ${errors.year ? 'input-error' : ''}`}
                >
                  <option value={1}>1st Year</option>
                  <option value={2}>2nd Year</option>
                  <option value={3}>3rd Year</option>
                  <option value={4}>4th Year</option>
                  <option value={5}>5th Year</option>
                </select>
                {errors.year && <p className="text-caption mt-2" style={{ color: 'var(--color-error)' }}>{errors.year}</p>}
              </div>

              <div className="mb-20">
                <p className="text-body-sm text-[var(--color-secondary-text)]">
                  Email: {user?.email}
                </p>
                <p className="text-body-sm text-[var(--color-secondary-text)] mt-4">
                  {user?.isVerified ? '✓ Verified Student' : '⚠ Not Verified'}
                </p>
              </div>

              {errors.submit && (
                <div className="mb-20 p-12 rounded-lg bg-[var(--color-error)]/10 text-[var(--color-error)] text-body-sm">
                  {errors.submit}
                </div>
              )}

              <Button type="submit" loading={saving} className="w-full" size="lg">
                Save Changes
              </Button>
            </CardContent>
          </form>
        </div>
      </div>
    </div>
  );
}