import type { Tilt } from './tilt.js'

const slackAroundLevel = 0.05
const gravityWhenFullyTilted = 0.5
const metresPerSecondSquaredOfGravity = 9.81

export class DeviceTilt implements Tilt {
    async requestAccess(): Promise<void> {
        const ask = (DeviceMotionEvent as PermissionAskingDeviceMotion).requestPermission
        if (typeof ask !== 'function') return

        try {
            await ask()
        } catch {
            return
        }
    }

    followTheLean(onLeaning: (fraction: number) => void): void {
        window.addEventListener('devicemotion', event => {
            const gravity = event.accelerationIncludingGravity
            if (gravity === null || gravity.y === null || gravity.y === undefined) return

            onLeaning(towardsLeaning(alongTheRightEdge(gravity.y)))
        })
    }
}

interface PermissionAskingDeviceMotion {
    requestPermission?: () => Promise<string>
}

function alongTheRightEdge(alongTheLongAxis: number): number {
    const gravity = -alongTheLongAxis / metresPerSecondSquaredOfGravity
    return screenRightIsTheDeviceTop() ? gravity : -gravity
}

function screenRightIsTheDeviceTop(): boolean {
    return screen.orientation.angle === 90
}

function towardsLeaning(gravity: number): number {
    const leaned = (gravity - slackAroundLevel) / (gravityWhenFullyTilted - slackAroundLevel)
    return Math.min(1, Math.max(0, leaned))
}
