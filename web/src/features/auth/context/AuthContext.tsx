import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import {
  User as FirebaseUser,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  sendPasswordResetEmail,
  updateProfile,
  UserCredential,
} from 'firebase/auth';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { getFirebaseAuth, getFirebaseDb } from '@shared/utils/firebase';
import { User, UserRole } from '@shared/types';
import { AppConfig } from '@shared/config/appConfig';

interface AuthContextType {
  user: User | null;
  firebaseUser: FirebaseUser | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, name: string) => Promise<void>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updateUserProfile: (data: Partial<User>) => Promise<void>;
  refreshUser: () => Promise<void>;
  sendEmailVerification: () => Promise<void>;
  reloadUser: () => Promise<void>;
  isEmailVerified: () => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AuthError';
  }
}

function isValidAKGECEmail(email: string): boolean {
  return email.toLowerCase().endsWith(`@${AppConfig.collegeEmailDomain}`);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [firebaseUser, setFirebaseUser] = useState<FirebaseUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const auth = getFirebaseAuth();
    const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
      setFirebaseUser(fbUser);
      if (fbUser) {
        await fetchUserData(fbUser.uid);
      } else {
        setUser(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const fetchUserData = async (uid: string) => {
    const db = getFirebaseDb();
    const userDoc = await getDoc(doc(db, 'users', uid));
    if (userDoc.exists()) {
      setUser({ ...userDoc.data(), uid: userDoc.id } as User);
    } else {
      setUser(null);
    }
  };

  const login = async (email: string, password: string) => {
    if (!isValidAKGECEmail(email)) {
      throw new AuthError('Use your AKGEC student email to continue.');
    }
    const auth = getFirebaseAuth();
    await signInWithEmailAndPassword(auth, email, password);
  };

const register = async (email: string, password: string, name: string) => {
    if (!isValidAKGECEmail(email)) {
      throw new AuthError('Use your AKGEC student email to continue.');
    }
    const auth = getFirebaseAuth();
    const db = getFirebaseDb();
    const credential = await createUserWithEmailAndPassword(auth, email, password);
    const fbUser = credential.user;
    // Use type assertion to access Firebase-specific method
    (fbUser as unknown as { sendEmailVerification: () => Promise<void> }).sendEmailVerification();
    await updateProfile(fbUser, { displayName: name });
    
    const newUser: Omit<User, 'uid'> = {
      name,
      email,
      collegeId: AppConfig.collegeId,
      course: '',
      branch: '',
      year: 1,
      isVerified: false, // Initially false until email verified
      role: 'student',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
    
    await setDoc(doc(db, 'users', fbUser.uid), newUser);
  };

  const logout = async () => {
    const auth = getFirebaseAuth();
    await firebaseSignOut(auth);
  };

  const resetPassword = async (email: string) => {
    if (!isValidAKGECEmail(email)) {
      throw new AuthError('Use your AKGEC student email to continue.');
    }
    const auth = getFirebaseAuth();
    await sendPasswordResetEmail(auth, email);
  };

  const sendEmailVerification = async () => {
    const auth = getFirebaseAuth();
    const user = auth.currentUser;
    if (!user) throw new Error('Not authenticated');
    (user as unknown as { sendEmailVerification: () => Promise<void> }).sendEmailVerification();
  };

  const reloadUser = async () => {
    const auth = getFirebaseAuth();
    const user = auth.currentUser as FirebaseUser | null;
    if (user) {
      await user.reload();
    }
  };

  const isEmailVerified = async () => {
    const auth = getFirebaseAuth();
    const user = auth.currentUser as FirebaseUser | null;
    if (!user) return false;
    await user.reload();
    return user.emailVerified;
  };

  const updateUserProfile = async (data: Partial<User>) => {
    const db = getFirebaseDb();
    const auth = getFirebaseAuth();
    if (!auth.currentUser) throw new Error('Not authenticated');
    
    // Prevent modification of protected fields
    const protectedFields = ['uid', 'isVerified', 'role', 'collegeId', 'email'];
    const filteredData = { ...data };
    for (const field of protectedFields) {
      delete filteredData[field as keyof typeof filteredData];
    }
    
    const updates = { ...filteredData, updatedAt: serverTimestamp() };
    await updateDoc(doc(db, 'users', auth.currentUser.uid), updates);
    await fetchUserData(auth.currentUser.uid);
  };

  const refreshUser = async () => {
    const auth = getFirebaseAuth();
    if (auth.currentUser) {
      await fetchUserData(auth.currentUser.uid);
    }
  };

  return (
    <AuthContext.Provider value={{ user, firebaseUser, loading, login, register, logout, resetPassword, updateUserProfile, refreshUser, sendEmailVerification, reloadUser, isEmailVerified }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

export function useRequireAuth() {
  const { user, loading } = useAuth();
  return { user, loading, isAuthenticated: !!user && !loading };
}

export function useRequireAdmin() {
  const { user, loading } = useAuth();
  return { user, loading, isAdmin: user?.role === 'admin' && !loading };
}