export interface FingerMark {
    readonly x: number
    readonly y: number
    readonly diameter: number
    readonly decidesBreath: boolean
}

export const restingDiameter = 56

export class FingerCircles {
    private readonly circles: HTMLElement[] = []

    constructor(private readonly container: HTMLElement) {}

    draw(marks: readonly FingerMark[]): void {
        while (this.circles.length < marks.length) this.circles.push(this.added())

        this.circles.forEach((circle, index) => {
            const mark = marks[index]
            if (mark === undefined) {
                circle.style.display = 'none'
                return
            }

            circle.style.display = 'block'
            circle.style.width = `${mark.diameter}px`
            circle.style.height = `${mark.diameter}px`
            circle.style.transform =
                `translate3d(${mark.x - mark.diameter / 2}px, ${mark.y - mark.diameter / 2}px, 0)`
            circle.classList.toggle('deciding', mark.decidesBreath)
        })
    }

    private added(): HTMLElement {
        const circle = document.createElement('div')
        circle.className = 'fingerMark'
        this.container.append(circle)
        return circle
    }
}
