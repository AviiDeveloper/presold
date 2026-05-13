/**
 * Client-side image compression. Browser only — uses HTMLCanvasElement and
 * `Image()`. Phone camera photos are commonly 5–10MB, which exceeds Vercel
 * Hobby's ~4.5MB request body limit; the request gets rejected at the edge
 * before our function ever sees it. Resize to `maxEdge` on the long side
 * and re-encode as JPEG, which drops a typical photo to ~300–800KB.
 *
 * Bonus: smaller images mean faster Haiku vision processing too.
 *
 * Returns the original file when compression isn't useful or fails — the
 * server still enforces its own limits.
 */
export async function compressImage(
  file: File,
  opts: { maxEdge?: number; quality?: number } = {},
): Promise<File> {
  const { maxEdge = 1600, quality = 0.85 } = opts;

  // Skip outright when the photo is already small.
  if (file.size < 500_000) return file;

  let dataUrl: string;
  try {
    dataUrl = await readDataUrl(file);
  } catch {
    return file;
  }

  let img: HTMLImageElement;
  try {
    img = await loadImage(dataUrl);
  } catch {
    return file;
  }

  const ratio = Math.min(maxEdge / img.width, maxEdge / img.height, 1);
  // If the image is already under maxEdge AND under ~1.5MB, don't bother.
  if (ratio === 1 && file.size < 1_500_000) return file;

  const w = Math.round(img.width * ratio);
  const h = Math.round(img.height * ratio);

  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  if (!ctx) return file;
  ctx.drawImage(img, 0, 0, w, h);

  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, "image/jpeg", quality),
  );
  if (!blob) return file;

  return new File([blob], file.name.replace(/\.[^.]+$/, ".jpg"), {
    type: "image/jpeg",
    lastModified: Date.now(),
  });
}

function readDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = (e) => reject(e);
    img.src = src;
  });
}
