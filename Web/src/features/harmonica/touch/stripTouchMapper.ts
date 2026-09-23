import type { CoreFinger } from '../../../core/coreFinger.js'
import type { AreaSize } from './areaSize.js'
import type { Contact } from './contact.js'
import type { FingerMark } from './fingerMark.js'
import { restingDiameter } from './fingerMark.js'
import type { FingerMarksViewState, FingerWidthViewState } from '../harmonicaViewState.js'

const holeCount = 10
const clickForce = 1
const firmestForce = 3
const holesUnderTheFirmestPress = 2.9
const holesUnderAClick = holesUnderTheFirmestPress / 4
const holesHeldBack = 1

export class StripTouchMapper {
    constructor(
        private readonly contacts: readonly Contact[],
        private readonly size: AreaSize
    ) {}

    positions(): CoreFinger[] {
        return this.contacts.map(contact => this.positionOf(contact))
    }

    marks(drawn: FingerMarksViewState): FingerMark[] {
        const positions = this.positions()
        const deciding = topmostOf(positions.filter(isOnTheHarmonica))
        return this.contacts.flatMap((contact, index) => {
            const position = positions[index]
            if (position === undefined) return []

            const isTheDecidingFinger = position === deciding
            const isDrawn = drawn.drawsOnlyTheDecidingFinger ? isTheDecidingFinger : isOnTheHarmonica(position)
            if (!isDrawn) return []

            return [{ x: contact.x, y: contact.y, diameter: this.diameterOf(contact, drawn.width), isTheDecidingFinger }]
        })
    }

    private positionOf(contact: Contact): CoreFinger {
        return {
            fractionFromLeftEdge: contact.x / this.size.width,
            fractionAboveCentreLine: (this.size.height / 2 - contact.y) / this.size.height,
            fractionCoveredEitherSide: holesPressedIn(contact) / 2 / holeCount
        }
    }

    private diameterOf(contact: Contact, width: FingerWidthViewState): number {
        switch (width.kind) {
            case 'resting': return restingDiameter
            case 'holesWide': return this.widthOf(width.holes)
            case 'pressed': return Math.max(restingDiameter, this.widthOf(holesPressedIn(contact)))
        }
    }

    private widthOf(holes: number): number {
        return (holes * this.size.width) / holeCount
    }
}

function holesPressedIn(contact: Contact): number {
    return contact.force === null ? 0 : holesPressedBy(contact.force)
}

function holesPressedBy(force: number): number {
    const forceWithinTheTrackpad = Math.min(firmestForce, Math.max(clickForce, force))
    const firmness = (forceWithinTheTrackpad - clickForce) / (firmestForce - clickForce)
    const holesAlongTheLine = holesUnderAClick + firmness * (holesUnderTheFirmestPress - holesUnderAClick)
    return Math.max(0, holesAlongTheLine - holesHeldBack)
}

function isOnTheHarmonica(finger: CoreFinger): boolean {
    return finger.fractionFromLeftEdge >= 0 && finger.fractionFromLeftEdge <= 1
}

function topmostOf(fingers: readonly CoreFinger[]): CoreFinger | null {
    let topmost: CoreFinger | null = null
    for (const finger of fingers) {
        if (topmost === null || finger.fractionAboveCentreLine > topmost.fractionAboveCentreLine) {
            topmost = finger
        }
    }
    return topmost
}
