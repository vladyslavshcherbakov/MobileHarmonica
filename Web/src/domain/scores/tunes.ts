import type { Score } from './score.js'
import { bluesStrain } from './tunes/bluesStrain.js'
import { slowDrag } from './tunes/slowDrag.js'
import { hammerSong } from './tunes/hammerSong.js'
import { foxChase } from './tunes/foxChase.js'
import { neseHaliaVodu } from './tunes/neseHaliaVodu.js'
import { oiPidVyshneiu } from './tunes/oiPidVyshneiu.js'
import { naIvanaNaKupala } from './tunes/naIvanaNaKupala.js'

export const tunes: readonly Score[] = [
    bluesStrain, slowDrag, hammerSong, foxChase,
    neseHaliaVodu, oiPidVyshneiu, naIvanaNaKupala
]
