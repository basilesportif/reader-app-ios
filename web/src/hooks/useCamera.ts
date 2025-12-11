import { useRef, useState, useEffect, useCallback } from 'react'

export type FacingMode = 'user' | 'environment'

export function useCamera() {
  const videoRef = useRef<HTMLVideoElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const [isReady, setIsReady] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [facingMode, setFacingMode] = useState<FacingMode>('environment')

  const startCamera = useCallback(async (mode: FacingMode) => {
    // Stop existing stream
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop())
    }

    setIsReady(false)
    setError(null)

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: mode },
        audio: false,
      })

      streamRef.current = stream

      if (videoRef.current) {
        videoRef.current.srcObject = stream
        videoRef.current.onloadedmetadata = () => {
          setIsReady(true)
        }
      }
    } catch (err) {
      if (err instanceof Error) {
        if (err.name === 'NotAllowedError') {
          setError('Camera access denied')
        } else if (err.name === 'NotFoundError') {
          setError('No camera found')
        } else {
          setError(err.message)
        }
      }
    }
  }, [])

  useEffect(() => {
    startCamera(facingMode)

    return () => {
      if (streamRef.current) {
        streamRef.current.getTracks().forEach(track => track.stop())
      }
    }
  }, [facingMode, startCamera])

  const capturePhoto = useCallback(async (): Promise<string | null> => {
    const video = videoRef.current
    if (!video || !isReady) return null

    const canvas = document.createElement('canvas')
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight

    const ctx = canvas.getContext('2d')
    if (!ctx) return null

    ctx.drawImage(video, 0, 0)

    // Get base64 without data URL prefix
    const dataUrl = canvas.toDataURL('image/jpeg', 0.8)
    return dataUrl.split(',')[1]
  }, [isReady])

  const toggleCamera = useCallback(() => {
    setFacingMode(prev => prev === 'user' ? 'environment' : 'user')
  }, [])

  return { videoRef, isReady, error, capturePhoto, facingMode, toggleCamera }
}
