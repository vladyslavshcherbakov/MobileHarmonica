export type RecordingFault = 'notListed' | 'unreadable'

export class RecordingError extends Error {
    constructor(
        readonly fault: RecordingFault,
        readonly recording: string,
        message: string
    ) {
        super(message)
        this.name = 'RecordingError'
    }
}
