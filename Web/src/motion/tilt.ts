export interface Tilt {
    requestAccess(): Promise<void>
    followTheLean(onLeaning: (fraction: number) => void): void
}
