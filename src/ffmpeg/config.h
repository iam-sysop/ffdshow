#if defined(__GNUC__) || defined(__INTEL_COMPILER)
 #ifndef __INTEL_COMPILER
  #define ARCH_X86 1
  #ifndef ARCH_X86_64
  	#define ARCH_X86_32 1
  #endif
 #endif
 #ifndef WIN64
  #define HAVE_MMX 1
 #endif
 #define HAVE_BUILTIN_VECTOR 1
 #define __CPU__ 586
#endif


#define HAVE_MALLOC_H 1
#define HAVE_LRINTF 1
#define SIMPLE_IDCT 1
#define CONFIG_ZLIB 1
#define HAVE_W32THREADS 1
#define HAVE_THREADS 1
#define HAVE_MEMALIGN 1


#ifndef DECODERS_ONLY
 /* encoding stuff */
 #define CONFIG_ENCODERS 1
 #define CONFIG_H261_ENCODER 1
#endif

#define CONFIG_DECODERS 1


#ifdef __GNUC__
 #include <stdint.h>
#else
 #ifndef __attribute__
  #define __attribute__(x) /**/
 #endif
 #define lrintf(x) (int)(x)
 #define EMULATE_FAST_INT
#endif


/* CPU related stuff */
//#define HAVE_CMOV
//#define HAVE_FAST_CMOV
