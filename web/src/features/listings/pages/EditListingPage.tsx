import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@features/auth/context/AuthContext';
import { Button, Input, Textarea, Card, CardContent } from '@shared/components/ui';
import { CATEGORIES, ListingType, Product } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { uploadMultipleToCloudinary, validateImageFile, createImagePreview, CLOUDINARY_CONFIG } from '@shared/utils/cloudinary';

export function EditListingPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('');
  const [price, setPrice] = useState('');
  const [originalPrice, setOriginalPrice] = useState('');
  const [isNegotiable, setIsNegotiable] = useState(false);
  const [condition, setCondition] = useState('');
  const [images, setImages] = useState<string[]>([]);
  const [newImages, setNewImages] = useState<File[]>([]);
  const [newImagePreviews, setNewImagePreviews] = useState<string[]>([]);
  const [location, setLocation] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (id) fetchProduct();
  }, [id]);

  const fetchProduct = async () => {
    if (!id) return;
    try {
      const db = getFirebaseDb();
      const productDoc = await getDoc(doc(db, 'products', id));
      if (productDoc.exists() && productDoc.data().sellerId === user?.uid) {
        const data = { id: productDoc.id, ...productDoc.data() } as Product;
        setProduct(data);
        setTitle(data.title);
        setDescription(data.description);
        setCategory(data.category);
        setPrice(data.price.toString());
        setOriginalPrice(data.originalPrice?.toString() || '');
        setIsNegotiable(data.isNegotiable);
        setCondition(data.condition);
        setImages(data.images);
        setLocation(data.location);
      } else {
        navigate('/my-listings');
      }
    } catch (error) {
      console.error('Error fetching product:', error);
      navigate('/my-listings');
    } finally {
      setLoading(false);
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    if (!title.trim()) newErrors.title = 'Title is required';
    if (!description.trim()) newErrors.description = 'Description is required';
    if (!category) newErrors.category = 'Category is required';
    if (product?.listingType === 'SELL' && (!price || Number(price) <= 0)) newErrors.price = 'Valid price is required';
    if (!condition) newErrors.condition = 'Condition is required';
    if (!location.trim()) newErrors.location = 'Location is required';
    if (images.length + newImages.length === 0) newErrors.images = 'At least one image is required';
    if (images.length + newImages.length > 5) newErrors.images = 'Maximum 5 images allowed';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNewImageChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length + images.length + newImages.length > CLOUDINARY_CONFIG.maxImages) {
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

    const newFiles = [...newImages, ...files];
    setNewImages(newFiles);
    setErrors(prev => ({ ...prev, images: '' }));

    for (const file of files) {
      const preview = await createImagePreview(file);
      setNewImagePreviews(prev => [...prev, preview]);
    }
  };

  const removeExistingImage = (index: number) => {
    setImages(prev => prev.filter((_, i) => i !== index));
  };

  const removeNewImage = (index: number) => {
    setNewImages(prev => prev.filter((_, i) => i !== index));
    setNewImagePreviews(prev => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm() || !user || !id) return;

    setSubmitting(true);
    try {
      const uploadedUrls = await uploadMultipleToCloudinary(newImages);
      const imageUrls = [...images, ...uploadedUrls];

      const db = getFirebaseDb();
      const updateData: Partial<Product> = {
        title: title.trim(),
        description: description.trim(),
        category,
        condition,
        location: location.trim(),
        images: imageUrls,
        updatedAt: serverTimestamp(),
      };

      if (product?.listingType === 'SELL') {
        updateData.price = Number(price);
        updateData.originalPrice = originalPrice ? Number(originalPrice) : undefined;
        updateData.isNegotiable = isNegotiable;
      }

      await updateDoc(doc(db, 'products', id), updateData);
      navigate(`/listings/${id}`);
    } catch (error) {
      console.error('Error updating listing:', error);
      setErrors({ submit: 'Failed to update listing. Please try again.' });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteImage = (imageUrl: string) => {
    if (!confirm('Delete this image?')) return;
    setImages(prev => prev.filter(url => url !== imageUrl));
  };

  if (loading) {
    return (
      <div className="container py-16">
        <div className="max-w-2xl mx-auto">
          <div className="card p-24 animate-pulse">
            <div className="h-8 bg-[var(--color-border)] rounded w-1/2 mb-16" />
            <div className="h-6 bg-[var(--color-border)] rounded w-full mb-8" />
            <div className="h-6 bg-[var(--color-border)] rounded w-full mb-8" />
            <div className="h-6 bg-[var(--color-border)] rounded w-full" />
          </div>
        </div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="container py-16 text-center">
        <h2 className="text-h3" style={{ color: 'var(--color-charcoal)' }}>Listing not found</h2>
        <Button variant="outline" onClick={() => navigate('/my-listings')} className="mt-16">
          Back to My Listings
        </Button>
      </div>
    );
  }

  return (
    <div className="flex-1">
      <div className="container py-16">
        <div className="max-w-2xl mx-auto">
          <div className="mb-24">
            <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Edit Listing</h1>
            <p className="text-body text-[var(--color-secondary-text)] mt-4">
              Update your listing details
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
                      disabled
                      className={`flex-1 py-12 px-16 rounded-lg border-2 text-body font-medium ${
                        product.listingType === type
                          ? 'border-[var(--color-ochre)] bg-[var(--color-ochre)]/5 text-[var(--color-ochre)]'
                          : 'border-[var(--color-border)] text-[var(--color-secondary-text)]'
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

              {product.listingType === 'SELL' && (
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
                  {images.map((imageUrl, index) => (
                    <div key={index} className="relative w-24 h-24 rounded-lg overflow-hidden">
                      <img src={imageUrl} alt={`Image ${index + 1}`} className="w-full h-full object-cover" />
                      <button
                        type="button"
                        onClick={() => handleDeleteImage(imageUrl)}
                        className="absolute top-2 right-2 w-6 h-6 rounded-full bg-black/50 text-white flex items-center justify-center hover:bg-black/70"
                      >
                        ×
                      </button>
                    </div>
                  ))}
                  {newImagePreviews.map((preview, index) => (
                    <div key={index} className="relative w-24 h-24 rounded-lg overflow-hidden">
                      <img src={preview} alt={`New image ${index + 1}`} className="w-full h-full object-cover" />
                      <button
                        type="button"
                        onClick={() => removeNewImage(index)}
                        className="absolute top-2 right-2 w-6 h-6 rounded-full bg-black/50 text-white flex items-center justify-center hover:bg-black/70"
                      >
                        ×
                      </button>
                    </div>
                  ))}
                  {images.length + newImages.length < 5 && (
                    <label className="w-24 h-24 rounded-lg border-2 border-dashed border-[var(--color-border)] flex flex-col items-center justify-center cursor-pointer hover:border-[var(--color-ochre)] transition-colors">
                      <span className="text-2xl">+</span>
                      <span className="text-caption mt-2 text-[var(--color-secondary-text)]">Add</span>
                      <input
                        type="file"
                        accept="image/*"
                        onChange={handleNewImageChange}
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
                  Save Changes
                </Button>
              </div>
            </CardContent>
          </form>
        </div>
      </div>
    </div>
  );
}