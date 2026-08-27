import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { ReportTargetType } from '@shared/types';

export interface ReportData {
  targetType: ReportTargetType;
  targetId: string;
  reason: string;
  description?: string;
}

export async function submitReport(reportData: ReportData): Promise<string> {
  const db = getFirebaseDb();
  const reportsRef = collection(db, 'reports');
  
  const docRef = await addDoc(reportsRef, {
    ...reportData,
    reportedBy: '', // Will be set by security rules based on auth
    status: 'pending',
    createdAt: serverTimestamp(),
  });
  
  return docRef.id;
}

export const REPORT_REASONS = [
  { value: 'inappropriate', label: 'Inappropriate content' },
  { value: 'spam', label: 'Spam or misleading' },
  { value: 'fake', label: 'Fake listing' },
  { value: 'prohibited', label: 'Prohibited item' },
  { value: 'harassment', label: 'Harassment or abuse' },
  { value: 'other', label: 'Other' },
] as const;