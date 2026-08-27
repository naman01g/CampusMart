import { Timestamp, FieldValue } from 'firebase/firestore';

export type ListingType = 'SELL' | 'EXCHANGE' | 'FREE';
export type ListingStatus = 'ACTIVE' | 'RESERVED' | 'SOLD' | 'REMOVED';
export type UserRole = 'student' | 'admin';
export type ReportStatus = 'pending' | 'reviewed' | 'resolved' | 'dismissed';
export type ReportTargetType = 'product' | 'user';

export type FirestoreTimestamp = Timestamp | Date | FieldValue;

export interface User {
  uid: string;
  name: string;
  email: string;
  profileImage?: string;
  collegeId: string;
  course: string;
  branch: string;
  year: number;
  isVerified: boolean;
  role: UserRole;
  createdAt: FirestoreTimestamp;
  updatedAt: FirestoreTimestamp;
}

export interface College {
  id: string;
  name: string;
  domain: string;
  logo?: string;
  isActive: boolean;
  createdAt: FirestoreTimestamp;
}

export interface Product {
  id: string;
  sellerId: string;
  title: string;
  description: string;
  listingType: ListingType;
  category: string;
  price: number;
  originalPrice?: number;
  isNegotiable: boolean;
  condition: string;
  images: string[];
  location: string;
  status: ListingStatus;
  views: number;
  favoritesCount: number;
  createdAt: FirestoreTimestamp;
  updatedAt: FirestoreTimestamp;
}

export interface Chat {
  id: string;
  buyerId: string;
  sellerId: string;
  productId: string;
  lastMessage: string;
  lastMessageAt: FirestoreTimestamp;
  buyer?: User;
  seller?: User;
  product?: Product;
}

export interface Message {
  id: string;
  chatId: string;
  senderId: string;
  message: string;
  createdAt: FirestoreTimestamp;
  isRead: boolean;
}

export interface Favorite {
  id: string;
  userId: string;
  productId: string;
  createdAt: FirestoreTimestamp;
}

export interface Report {
  id: string;
  reportedBy: string;
  targetType: ReportTargetType;
  targetId: string;
  reason: string;
  description?: string;
  status: ReportStatus;
  createdAt: FirestoreTimestamp;
}

export interface Notification {
  id: string;
  userId: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  isRead: boolean;
  createdAt: FirestoreTimestamp;
}

export interface Review {
  id: string;
  reviewerId: string;
  revieweeId: string;
  productId: string;
  rating: number;
  comment?: string;
  createdAt: FirestoreTimestamp;
}

export const CATEGORIES = [
  'Books',
  'Electronics',
  'Accessories',
  'Furniture',
  'Clothing',
  'Bags',
  'Sports',
  'Study Equipment',
  'Chargers & Cables',
  'Cycles',
  'Gaming',
  'Hostel Items',
  'Other',
] as const;

export type Category = typeof CATEGORIES[number];

export const LISTING_TYPES: { value: ListingType; label: string }[] = [
  { value: 'SELL', label: 'Sell' },
  { value: 'EXCHANGE', label: 'Exchange' },
  { value: 'FREE', label: 'Free' },
];

export const LISTING_STATUSES: { value: ListingStatus; label: string }[] = [
  { value: 'ACTIVE', label: 'Active' },
  { value: 'RESERVED', label: 'Reserved' },
  { value: 'SOLD', label: 'Sold' },
  { value: 'REMOVED', label: 'Removed' },
];

// Helper function to convert Firestore timestamp to Date
export function toDate(timestamp: FirestoreTimestamp): Date {
  if (timestamp instanceof Timestamp) {
    return timestamp.toDate();
  }
  if (timestamp instanceof Date) {
    return timestamp;
  }
  // FieldValue (serverTimestamp) cannot be converted to Date on client
  return new Date();
}