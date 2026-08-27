import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, getDocs, addDoc, serverTimestamp, doc, getDoc } from 'firebase/firestore';
import { Product } from '@shared/types';

export interface ChatCreationResult {
  chatId: string;
  isNew: boolean;
}

export async function findOrCreateChat(
  buyerId: string,
  sellerId: string,
  productId: string
): Promise<ChatCreationResult> {
  if (buyerId === sellerId) {
    throw new Error('Cannot create chat with yourself');
  }

  const db = getFirebaseDb();
  const chatsRef = collection(db, 'chats');

  // Check if chat already exists
  const existingChatQuery = query(
    chatsRef,
    where('buyerId', '==', buyerId),
    where('sellerId', '==', sellerId),
    where('productId', '==', productId)
  );

  const existingSnapshot = await getDocs(existingChatQuery);
  
  if (!existingSnapshot.empty) {
    const existingChat = existingSnapshot.docs[0];
    return { chatId: existingChat.id, isNew: false };
  }

  // Fetch product details for chat preview
  let productTitle = 'Unknown product';
  let productImage = '';
  
  try {
    const productDoc = await getDoc(doc(db, 'products', productId));
    if (productDoc.exists()) {
      const productData = productDoc.data() as Product;
      productTitle = productData.title;
      productImage = productData.images[0] || '';
    }
  } catch (error) {
    console.warn('Could not fetch product for chat:', error);
  }

  // Create new chat
  const chatData = {
    buyerId,
    sellerId,
    productId,
    lastMessage: '',
    lastMessageAt: serverTimestamp(),
    product: {
      id: productId,
      title: productTitle,
      images: productImage ? [productImage] : [],
    } as Product,
  };

  const docRef = await addDoc(chatsRef, chatData);
  return { chatId: docRef.id, isNew: true };
}