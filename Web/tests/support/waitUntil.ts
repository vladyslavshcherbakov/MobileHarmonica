const pollMilliseconds = 5

export async function waitUntil(condition: () => boolean, withinSeconds = 3): Promise<boolean> {
    const pollsWithinTheLimit = (withinSeconds * 1000) / pollMilliseconds
    for (let poll = 0; poll < pollsWithinTheLimit; poll++) {
        if (condition()) return true

        await new Promise(resolve => setTimeout(resolve, pollMilliseconds))
    }
    return condition()
}
