import type { AreaSize } from './areaSize.js'
import type { Contact } from './contact.js'
import type { FingerMark } from './fingerMark.js'
import { restingDiameter } from './fingerMark.js'

export interface SquareShaping {
    readonly pitch: number
    readonly vibrato: number
}

export class SquareTouchMapper {
    constructor(
        private readonly contacts: readonly Contact[],
        private readonly size: AreaSize
    ) {}

    shaping(): SquareShaping | null {
        const leading = this.leading()
        if (leading === undefined || this.isAPinch()) return null

        return {
            pitch: 1 - (2 * leading.y) / this.size.height,
            vibrato: leading.x / this.size.width
        }
    }

    marks(): FingerMark[] {
        const leading = this.leading()
        return this.contacts.map(contact => ({
            x: contact.x,
            y: contact.y,
            diameter: restingDiameter,
            isTheDecidingFinger: contact === leading
        }))
    }

    private isAPinch(): boolean {
        return this.contacts.length > 1
    }

    private leading(): Contact | undefined {
        let topmost: Contact | undefined
        for (const contact of this.contacts) {
            if (topmost === undefined || contact.y < topmost.y) topmost = contact
        }
        return topmost
    }
}
