import { useState } from 'react'
import { Provider, Model, modelsByProvider } from '../services/api'
import './QueryInterface.css'

interface QueryInterfaceProps {
  imageData: string
  onSubmit: (prompt: string) => void
  onRetake: () => void
  isLoading: boolean
  provider: Provider
  model: Model
}

export function QueryInterface({
  imageData,
  onSubmit,
  onRetake,
  isLoading,
  provider,
  model,
}: QueryInterfaceProps) {
  const [prompt, setPrompt] = useState('')
  const [rotation, setRotation] = useState(0)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (prompt.trim() && !isLoading) {
      onSubmit(prompt.trim())
    }
  }

  const handleRotate = () => {
    setRotation((prev) => (prev + 90) % 360)
  }

  const imageSrc = 'data:image/jpeg;base64,' + imageData

  // Get the human-readable model name
  const modelLabel = modelsByProvider[provider].find(m => m.value === model)?.label || model

  return (
    <div className="query-interface">
      <div className="preview-container">
        <img
          src={imageSrc}
          alt="Captured"
          className="preview-image"
          style={{ transform: `rotate(${rotation}deg)` }}
        />
        <button
          className="rotate-button"
          onClick={handleRotate}
          title="Rotate image 90°"
          disabled={isLoading}
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8" />
            <path d="M21 3v5h-5" />
          </svg>
        </button>
      </div>

      <form onSubmit={handleSubmit} className="query-form">
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="Enter your question about this image..."
          className="query-input"
          rows={3}
          disabled={isLoading}
        />

        <div className="query-actions">
          <button
            type="button"
            onClick={onRetake}
            className="btn btn-secondary"
            disabled={isLoading}
          >
            Retake
          </button>
          <button
            type="submit"
            className="btn btn-primary"
            disabled={!prompt.trim() || isLoading}
          >
            {isLoading && <span className="spinner" />}
            {isLoading ? `Querying ${modelLabel}...` : 'Send'}
          </button>
        </div>
      </form>
    </div>
  )
}
