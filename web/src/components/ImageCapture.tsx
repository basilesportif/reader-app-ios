import { useState, useRef, useCallback } from 'react'
import { useCamera } from '../hooks/useCamera'
import './ImageCapture.css'

interface ImageCaptureProps {
  onCapture: (imageData: string) => void
}

export function ImageCapture({ onCapture }: ImageCaptureProps) {
  const [mode, setMode] = useState<'camera' | 'upload'>('camera')
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { videoRef, isReady, error, capturePhoto, facingMode, toggleCamera } = useCamera()

  const handleCameraCapture = useCallback(async () => {
    const imageData = await capturePhoto()
    if (imageData) {
      onCapture(imageData)
    }
  }, [capturePhoto, onCapture])

  const handleFileChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result as string
      // Remove data URL prefix to get just base64
      const base64 = result.split(',')[1]
      onCapture(base64)
    }
    reader.readAsDataURL(file)
  }, [onCapture])

  const handleUploadClick = () => {
    fileInputRef.current?.click()
  }

  const cameraTabClass = mode === 'camera' ? 'mode-tab active' : 'mode-tab'
  const uploadTabClass = mode === 'upload' ? 'mode-tab active' : 'mode-tab'

  return (
    <div className="image-capture">
      <div className="mode-tabs">
        <button
          className={cameraTabClass}
          onClick={() => setMode('camera')}
        >
          Camera
        </button>
        <button
          className={uploadTabClass}
          onClick={() => setMode('upload')}
        >
          Upload
        </button>
      </div>

      {mode === 'camera' ? (
        <div className="camera-container">
          {error ? (
            <div className="camera-error">
              <p>{error}</p>
              <p className="camera-error-hint">
                Please allow camera access or use file upload instead.
              </p>
            </div>
          ) : (
            <>
              <div className="camera-preview-container">
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  muted
                  className="camera-preview"
                />
                <button
                  className="flip-camera-button"
                  onClick={toggleCamera}
                  title={facingMode === 'user' ? 'Switch to back camera' : 'Switch to front camera'}
                >
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M16 3h5v5M8 21H3v-5M21 3l-7 7M3 21l7-7M11 12a4 4 0 1 0 4 4" />
                  </svg>
                </button>
              </div>
              <button
                className="capture-button"
                onClick={handleCameraCapture}
                disabled={!isReady}
              >
                <span className="capture-button-inner" />
              </button>
            </>
          )}
        </div>
      ) : (
        <div className="upload-container">
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleFileChange}
            className="file-input"
          />
          <button className="upload-button" onClick={handleUploadClick}>
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="17,8 12,3 7,8" />
              <line x1="12" y1="3" x2="12" y2="15" />
            </svg>
            <span>Click to upload an image</span>
            <span className="upload-hint">or drag and drop</span>
          </button>
        </div>
      )}
    </div>
  )
}
