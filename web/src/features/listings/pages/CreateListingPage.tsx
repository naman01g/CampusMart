import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Input, Textarea, Card, CardContent, Badge } from '@shared/components/ui';
import { CATEGORIES, ListingType, Product } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { uploadMultipleToCloudinary, validateImageFile, createImagePreview, CLOUDINARY_CONFIG } from '@shared/utils/cloudinary';

export function CreateListingPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [listingType, setListingType] = useState<ListingType>('SELL');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('');
  const [price, setPrice] = useState('');
  const [originalPrice, setOriginalPrice] = useState('');
  const [isNegotiable, setIsNegotiable] = useState(false);
  const [condition, setCondition] = useState('');
  const [images, setImages] = useState<File[]>([]);
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [location, setLocation] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    if (!title.trim()) newErrors.title = 'Title is required';
    if (!description.trim()) newErrors.description = 'Description is required';
    if (!category) newErrors.category = 'Category is required';
    if (listingType === 'SELL' && (!price || Number(price) <= 0)) newErrors.price = 'Valid price is required';
    if (!condition) newErrors.condition = 'Condition is required';
    if (!location.trim()) newErrors.location = 'Location is required';
    if (images.length === 0) newErrors.images = 'At least one image is required';
    if (images.length > 5) newErrors.images = 'Maximum 5 images allowed';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleImageChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length + images.length > CLOUDINARY_CONFIG.maxImages) {
      setErrors({ ...errors, images: `Maximum ${CLOUDINARY_CONFIG.maxImages} images allowed` });
      return;
    }

    for (const file of files) {
      const validation = validateImageFile(file);
      if (!validation.valid) {
        setErrors({ ...errors, images: validation.error! });
        return;
      }
    }

    const newImages = [...images, ...files];
    setImages(newImages);
    setErrors(prev => ({ ...prev, images: '' }));

    for (const file of files) {
      const preview = await createImagePreview(file);
      setImagePreviews(prev => [...prev, preview]);
    }
  };

  const removeImage = (index: number) => {
    setImages(prev => prev.filter((_, i) => i !== index));
    setImagePreviews(prev => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm() || !user) return;

    setSubmitting(true);
    try {
      const imageUrls = await uploadMultipleToCloudinary(images);

      const db = getFirebaseDb();
      const productData: Omit<Product, 'id'> = {
        sellerId: user.uid,
        title: title.trim(),
        description: description.trim(),
        listingType,
        category,
        price: listingType === 'SELL' ? Number(price) : 0,
        originalPrice: originalPrice ? Number(originalPrice) : undefined,
        isNegotiable: listingType === 'SELL' ? isNegotiable : false,
        condition,
        images: imageUrls,
        location: location.trim(),
        status: 'ACTIVE',
        views: 0,
        favoritesCount: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      const docRef = await addDoc(collection(db, 'products'), productData);
      navigate(`/listings/${docRef.id}`);
    } catch (error) {
      console.error('Error creating listing:', error);
      setErrors({ submit: 'Failed to create listing. Please try again.' });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex-1">
      <div className="container py-16">
        <div className="max-w-2xl mx-auto">
          <div className="mb-24">
            <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Create Listing</h1>
            <p className="text-body text-[var(--color-secondary-text)] mt-4">
              Fill in the details below to list your item
            </p>
          </div>

          <form onSubmit={handleSubmit} className="card" noValidate>
            <CardContent>
              <div className="mb-20">
                <label className="label">Listing Type</label>
                <div className="flex gap-12">
                  {(['SELL', 'EXCHANGE', 'FREE'] as ListingType[]).map(type => (
                    <button
                      key={type}
                      type="button"
                      onClick={() => setListingType(type)}
                      className={`flex-1 py-12 px-16 rounded-lg border-2 text-body font-medium transition-all ${
                        listingType === type
                          ? 'border-[var(--color-ochre)] bg-[var(--color-ochre)]/5 text-[var(--color-ochre)]'
                          : 'border-[var(--color-border)] hover:border-[var(--color-ochre)]/50'
                      }`}
                    >
                      {type}
                    </button>
                  ))}
                </div>
              </div>

              <div className="mb-20">
                <Input
                  label="Title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder='e.g., MacBook Pro 13" M1 256GB'
                  error={errors.title}
                  maxLength={100}
                />
              </div>

              <div className="mb-20">
                <Textarea
                  label="Description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Describe the item condition, specifications, reason for selling, etc."
                  rows={5}
                  error={errors.description}
                  maxLength={2000}
                />
              </div>

<div className="mb-20">
                <label className="label">Category</label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className={`input ${errors.category ? 'input-error' : ''}`}
                >
                  <option value="">Select category</option>
                  {CATEGORIES.map(cat => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
                {errors.category && <p className="text-caption mt-2" style={{ color: 'var(--color-error)' }}>{errors.category}</p>}
              </div>

              {listingType === 'SELL' && (
                <>
                  <div className="mb-20">
                    <Input
                      label="Price (₹)"
                      type="number"
                      value={price}
                      onChange={(e) => setPrice(e.target.value)}
                      placeholder="0"
                      error={errors.price}
                      min="1"
                    />
                  </div>
                  <div className="mb-20">
                    <Input
                      label="Original Price (₹) - Optional"
                      type="number"
                      value={originalPrice}
                      onChange={(e) => setOriginalPrice(e.target.value)}
                      placeholder="Original price for reference"
                    />
                  </div>
                  <div className="mb-20">
                    <label className="flex items-center gap-8 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={isNegotiable}
                        onChange={(e) => setIsNegotiable(e.target.checked)}
                        className="w-4 h-4 accent-[var(--color-ochre)]"
                      />
                      <span className="text-body" style={{ color: 'var(--color-primary-text)' }}>
                        Price is negotiable
                      </span>
                    </label>
                  </div>
                </>
              )}

              <div className="mb-20">
                <Input
                  label="Condition"
                  value={condition}
                  onChange={(e) => setCondition(e.target.value)}
                  placeholder="e.g., Like new, Good, Fair, Needs repair"
                  error={errors.condition}
                />
              </div>

              <div className="mb-20">
                <label className="label">Images (max 5)</label>
                <div className="flex flex-wrap gap-12 mb-8">
                  {imagePreviews.map((preview, index) => (
                    <div key={index} className="relative w-24 h-24 rounded-lg overflow-hidden">
                      <img src={preview} alt={`Preview ${index + 1}`} className="w-full h-full object-cover" />
                      <button
                        type="button"
                        onClick={() => removeImage(index)}
                        className="absolute top-2 right-2 w-6 h-6 rounded-full bg-black/50 text-white flex items-center justify-center hover:bg-black/70"
                      >
                        ×
                      </button>
                    </div>
                  ))}
                  {images.length < 5 && (
                    <label className="w-24 h-24 rounded-lg border-2 border-dashed border-[var(--color-border)] flex flex-col items-center justify-center cursor-pointer hover:border-[var(--color-ochre)] transition-colors">
                      <span className="text-2xl">+</span>
                      <span className="text-caption mt-2 text-[var(--color-secondary-text)]">Add</span>
                      <input
                        type="file"
                        accept="image/*"
                        onChange={handleImageChange}
                        multiple
                        className="hidden"
                        id="image-upload"
                      />
                    </label>
                  )}
                </div>
                {errors.images && <p className="text-caption" style={{ color: 'var(--color-error)' }}>{errors.images}</p>}
              </div>

              <div className="mb-20">
                <Input
                  label="Location (Campus area)"
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  placeholder="e.g., Hostel Block A, Library, Main Gate"
                  error={errors.location}
                />
              </div>

              {errors.submit && (
                <div className="mb-20 p-12 rounded-lg bg-[var(--color-error)]/10 text-[var(--color-error)] text-body-sm">
                  {errors.submit}
                </div>
              )}

              <div className="flex gap-12">
                <Button type="button" variant="outline" onClick={() => navigate(-1)} className="flex-1">
                  Cancel
                </Button>
                <Button type="submit" loading={submitting} className="flex-1">
                  Create Listing
                </Button>
              </div>
            </CardContent>
          </form>
        </div>
      </div>
    </div>
  );
}