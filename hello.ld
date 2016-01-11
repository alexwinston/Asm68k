MEMORY {
  vectors(rw) : ORIGIN = 0x00000000, LENGTH = 0x00000400
  ram(rwx)    : ORIGIN = 0x00000400, LENGTH = 0x01000000
}
SECTIONS {
//seg2000 0x2000 : { *(seg2000) }
seg0 0x0000 : { *(seg0) }
seg64 0x0064 : { *(seg64) }
seg400 0x0400 : { *(seg400) }
}
