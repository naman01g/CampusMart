export const CLOUDINARY_CONFIG = {
  cloudName: 'xaexfxrr',
  uploadPreset: 'campusmart',
  uploadUrl: 'https://api.cloudinary.com/v1_1/xaexfxrr/image/upload',
  maxImages: 5,
  maxFileSizeMB: 5,
};

export async function uploadToCloudinary(
  file: File,
  onProgress?: (progress: number) => void
): Promise<string> {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', CLOUDINARY_CONFIG.uploadPreset);

  const response = await fetch(CLOUDINARY_CONFIG.uploadUrl, {
    method: 'POST',
    body: formData,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Cloudinary upload failed (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  const secureUrl = data.secure_url;

  if (!secureUrl) {
    throw new Error('Cloudinary upload succeeded but no secure_url was returned.');
  }

  if (onProgress) {
    onProgress(1);
  }

  return secureUrl;
}

export async function uploadMultipleToCloudinary(
  files: File[],
  onProgress?: (completed: number, total: number) => void
): Promise<string[]> {
  const urls: string[] = [];
  
  for (let i = 0; i < files.length; i++) {
    const url = await uploadToCloudinary(files[i]);
    urls.push(url);
    if (onProgress) {
      onProgress(i + 1, files.length);
    }
  }
  
  return urls;
}

export function validateImageFile(file: File): { valid: boolean; error?: string } {
  if (!file.type.startsWith('image/')) {
    return { valid: false, error: 'File must be an image' };
  }
  
  if (file.size > CLOUDINARY_CONFIG.maxFileSizeMB * 1024 * 1024) {
    return { valid: false, error: `Image must be less than ${CLOUDINARY_CONFIG.maxFileSizeMB}MB` };
  }
  
  return { valid: true };
}

export function createImagePreview(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (event) => resolve(event.target?.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}