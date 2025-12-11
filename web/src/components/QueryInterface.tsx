import { useState } from 'react'
import { Provider, Model, modelsByProvider } from '../services/api'
import { useVoiceInput } from '../hooks/useVoiceInput'
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
  const { state: voiceState, error: voiceError, startRecording, stopRecording } = useVoiceInput()

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (prompt.trim() && !isLoading) {
      onSubmit(prompt.trim())
    }
  }

  const handleRotate = () => {
    setRotation((prev) => (prev + 90) % 360)
  }

  const handleVoiceClick = async () => {
    if (voiceState === 'recording') {
      const text = await stopRecording()
      if (text) {
        setPrompt((prev) => (prev ? `${prev} ${text}` : text))
      }
    } else if (voiceState === 'idle') {
      startRecording()
    }
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
        <div className="prompt-input-container">
          <textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Enter your question about this image..."
            className="query-input"
            rows={3}
            disabled={isLoading || voiceState !== 'idle'}
          />
          <button
            type="button"
            className={`voice-button ${voiceState === 'recording' ? 'recording' : ''}`}
            onClick={handleVoiceClick}
            disabled={isLoading || voiceState === 'transcribing'}
            title={voiceState === 'recording' ? 'Stop recording' : 'Start voice input'}
          >
            {voiceState === 'transcribing' ? (
              <span className="voice-spinner" />
            ) : voiceState === 'recording' ? (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <rect x="6" y="6" width="12" height="12" rx="2" />
              </svg>
            ) : (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z" />
                <path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z" />
              </svg>
            )}
          </button>
        </div>

        {voiceError && <div className="voice-error">{voiceError}</div>}

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
