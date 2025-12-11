import { useState } from 'react'
import { ImageCapture } from './components/ImageCapture'
import { QueryInterface } from './components/QueryInterface'
import { ResponseView } from './components/ResponseView'
import { Header } from './components/Header'
import { queryApi, Provider } from './services/api'
import './App.css'

type ViewState = 'capture' | 'query' | 'response'

function App() {
  const [viewState, setViewState] = useState<ViewState>('capture')
  const [imageData, setImageData] = useState<string | null>(null)
  const [provider, setProvider] = useState<Provider>('claude')
  const [response, setResponse] = useState<string>('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleImageCapture = (data: string) => {
    setImageData(data)
    setViewState('query')
    setError(null)
  }

  const handleQuery = async (prompt: string) => {
    if (!imageData) return
    
    setIsLoading(true)
    setError(null)
    
    try {
      const result = await queryApi(imageData, prompt, provider)
      setResponse(result.response)
      setViewState('response')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setIsLoading(false)
    }
  }

  const handleReset = () => {
    setImageData(null)
    setResponse('')
    setViewState('capture')
    setError(null)
  }

  const handleRetake = () => {
    setViewState('capture')
    setError(null)
  }

  return (
    <div className="app">
      <Header provider={provider} onProviderChange={setProvider} />
      
      <main className="main">
        {error && (
          <div className="error-banner">
            {error}
            <button onClick={() => setError(null)}>×</button>
          </div>
        )}
        
        {viewState === 'capture' && (
          <ImageCapture onCapture={handleImageCapture} />
        )}
        
        {viewState === 'query' && imageData && (
          <QueryInterface
            imageData={imageData}
            onSubmit={handleQuery}
            onRetake={handleRetake}
            isLoading={isLoading}
            provider={provider}
          />
        )}
        
        {viewState === 'response' && (
          <ResponseView
            response={response}
            onNewCapture={handleReset}
          />
        )}
      </main>
    </div>
  )
}

export default App
