local ccnes = require("/nes/ccnes")

ccnes.start("/mario.nes", ccnes.getCallback(nil, {peripheral.find("speaker")}))
