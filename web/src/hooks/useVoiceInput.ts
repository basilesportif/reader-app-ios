import { useState, useRef, useCallback } from 'react'

export type VoiceInputState = 'idle' | 'recording' | 'transcribing'

export function useVoiceInput() {
  const [state, setState] = useState<VoiceInputState>('idle')
  const [error, setError] = useState<string | null>(null)
  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const chunksRef = useRef<Blob[]>([])

  const startRecording = useCallback(async () => {
    setError(null)
    chunksRef.current = []

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })

      // Try webm/opus first, fall back to whatever is supported
      let mimeType = 'audio/webm;codecs=opus'
      if (!MediaRecorder.isTypeSupported(mimeType)) {
        mimeType = 'audio/webm'
        if (!MediaRecorder.isTypeSupported(mimeType)) {
          mimeType = '' // Let browser choose
        }
      }

      const mediaRecorder = new MediaRecorder(stream, mimeType ? { mimeType } : undefined)

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          chunksRef.current.push(event.data)
        }
      }

      mediaRecorderRef.current = mediaRecorder
      mediaRecorder.start()
      setState('recording')
    } catch (err) {
      if (err instanceof Error) {
        if (err.name === 'NotAllowedError') {
          setError('Microphone access denied')
        } else {
          setError(err.message)
        }
      }
    }
  }, [])

  const stopRecording = useCallback(async (): Promise<string | null> => {
    return new Promise((resolve) => {
      const mediaRecorder = mediaRecorderRef.current
      if (!mediaRecorder || mediaRecorder.state !== 'recording') {
        resolve(null)
        return
      }

      mediaRecorder.onstop = async () => {
        setState('transcribing')

        // Stop all tracks
        mediaRecorder.stream.getTracks().forEach((track) => track.stop())

        try {
          const audioBlob = new Blob(chunksRef.current, { type: 'audio/webm' })
          const base64 = await blobToBase64(audioBlob)

          const response = await fetch('/api/transcribe', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ audio: base64, format: 'webm' }),
          })

          if (!response.ok) {
            const errorData = await response.json()
            throw new Error(errorData.error || 'Transcription failed')
          }

          const data = await response.json()
          setState('idle')
          resolve(data.text)
        } catch (err) {
          setError(err instanceof Error ? err.message : 'Transcription failed')
          setState('idle')
          resolve(null)
        }
      }

      mediaRecorder.stop()
    })
  }, [])

  const cancelRecording = useCallback(() => {
    const mediaRecorder = mediaRecorderRef.current
    if (mediaRecorder && mediaRecorder.state === 'recording') {
      mediaRecorder.stream.getTracks().forEach((track) => track.stop())
      mediaRecorder.stop()
    }
    chunksRef.current = []
    setState('idle')
    setError(null)
  }, [])

  return { state, error, startRecording, stopRecording, cancelRecording }
}

function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onloadend = () => {
      const base64 = (reader.result as string).split(',')[1]
      resolve(base64)
    }
    reader.onerror = reject
    reader.readAsDataURL(blob)
  })
}
