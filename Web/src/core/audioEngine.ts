import type { CoreAudio } from './coreAudio.js'

export type AudioEngineError =
    | { readonly kind: 'noRecordings' }
    | { readonly kind: 'recordingUnreadable'; readonly recording: string }
    | { readonly kind: 'outputRefused' }

export class AudioEngineFailure extends Error {
    constructor(readonly error: AudioEngineError, cause: string) {
        super(cause)
        this.name = 'AudioEngineFailure'
    }
}

export interface AudioEngine extends CoreAudio {
    prepare(): Promise<void>
}
