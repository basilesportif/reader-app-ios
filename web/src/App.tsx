import { useState } from 'react'
import { ImageCapture } from './components/ImageCapture'
import { QueryInterface } from './components/QueryInterface'
import { ResponseView } from './components/ResponseView'
import { QueryHistory } from './components/QueryHistory'
import { Header } from './components/Header'
import { queryApi, Provider } from './services/api'
import { useQueryHistory, createThumbnail, QueryHistoryItem } from './hooks/useQueryHistory'
import './App.css'

type ViewState = 'capture' | 'query' | 'response' | 'history'

function App() {
  const [viewState, setViewState] = useState<ViewState>('capture')
  const [imageData, setImageData] = useState<string | null>(null)
  const [provider, setProvider] = useState<Provider>('claude')
  const [response, setResponse] = useState<string>('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [lastPrompt, setLastPrompt] = useState<string>('')

  const { history, addToHistory, removeFromHistory, clearHistory } = useQueryHistory()

  const handleImageCapture = (data: string) => {
    setImageData(data)
    setViewState('query')
    setError(null)
  }

  const handleQuery = async (prompt: string) => {
    if (!imageData) return

    setIsLoading(true)
    setError(null)
    setLastPrompt(prompt)

    try {
      const result = await queryApi(imageData, prompt, provider)
      setResponse(result.response)
      setViewState('response')

      // Save to history
      const thumbnail = await createThumbnail(imageData)
      addToHistory({
        prompt,
        response: result.response,
        provider: result.provider,
        imagePreview: thumbnail,
      })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setIsLoading(false)
    }
  }

  const handleHistorySelect = (item: QueryHistoryItem) => {
    setResponse(item.response)
    setLastPrompt(item.prompt)
    setViewState('response')
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
      <Header
        provider={provider}
        onProviderChange={setProvider}
        onHistoryClick={() => setViewState('history')}
        historyCount={history.length}
      />

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

        {viewState === 'history' && (
          <QueryHistory
            history={history}
            onSelect={handleHistorySelect}
            onDelete={removeFromHistory}
            onClear={clearHistory}
          />
        )}
      </main>
    </div>
  )
}

export default App
