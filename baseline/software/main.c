#include <stdio.h>
#include <unistd.h>           // close
#include <fcntl.h>            // O_RDWR, O_SYNC
#include <sys/mman.h>         // PROT_READ, PROT_WRITE

#include "socal/socal.h"      // alt_write
#include "socal/hps.h"
#include "socal/alt_gpio.h"

#include "hps_0.h"            // definitions for LED_PIO and SWITCH_PIO

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

void mydivider(volatile unsigned *base, unsigned n, unsigned d, unsigned *q, unsigned *r) {
  base[0] = n;
  base[1] = d;
  
  // SYNC1
  base[2] = 1;
  while (base[5] == 0) ;

  // SYNC0
  base[2] = 0;
  while (base[5] == 1) ;
  *q = base[3];
  *r = base[4];  
}

int main(int argc, char **argv) {
  void *virtual_base;
  volatile unsigned *led_pio, *switch_pio;
  volatile unsigned *div_base;
  int fd;

  if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
    printf( "ERROR: could not open \"/dev/mem\"...\n" );
    return( 1 );
  }
  virtual_base = mmap( NULL,
		       HW_REGS_SPAN,
		       ( PROT_READ | PROT_WRITE ),
		       MAP_SHARED,
		       fd,
		       HW_REGS_BASE );	
  if( virtual_base == MAP_FAILED ) {
    printf( "ERROR: mmap() failed...\n" );
    close( fd );
    return(1);
  }
  
  led_pio = virtual_base +
    ( ( unsigned  )( ALT_LWFPGASLVS_OFST + LED_PIO_0_BASE) & ( unsigned)( HW_REGS_MASK ) );
  switch_pio = virtual_base +
    ( ( unsigned )( ALT_LWFPGASLVS_OFST + SWITCH_PIO_1_BASE) & ( unsigned)( HW_REGS_MASK ) );
  div_base = virtual_base +
    ( ( unsigned  )( ALT_LWFPGASLVS_OFST + MYDIVIDER_0_BASE) & ( unsigned)( HW_REGS_MASK ) );

  unsigned n, d, r, q;
  while (1) {
    *led_pio = *switch_pio;
    for (n=3000; n<3050; n++) {
      for (d=n+1000; d<(n+1050); d++) {
	mydivider(div_base, n, d, &q, &r);
	printf("DIV: N %3d D %3d Q %3d R %3d CHK %d = %d\n", n, d, q, r, n * 256, d * q + r);
      }
    }
    if (*switch_pio == 0x2AA)
      break;
  }

  *led_pio = 0x3FF;

  if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
    printf( "ERROR: munmap() failed...\n" );
    close( fd );
    return( 1 );
    
  }
  close( fd );
  return 0;
}
