# For zEC12 and above.
# RUN: llvm-mc -triple s390x-linux-gnu -mcpu=zEC12 -show-encoding %s | FileCheck %s
# RUN: llvm-mc -triple s390x-linux-gnu -mcpu=arch10 -show-encoding %s | FileCheck %s

#CHECK: clt	%r0, 12, -524288            # encoding: [0xeb,0x0c,0x00,0x00,0x80,0x23]
#CHECK: clt	%r0, 12, -1                 # encoding: [0xeb,0x0c,0x0f,0xff,0xff,0x23]
#CHECK: clt	%r0, 12, 0                  # encoding: [0xeb,0x0c,0x00,0x00,0x00,0x23]
#CHECK: clt	%r0, 12, 1                  # encoding: [0xeb,0x0c,0x00,0x01,0x00,0x23]
#CHECK: clt	%r0, 12, 524287             # encoding: [0xeb,0x0c,0x0f,0xff,0x7f,0x23]
#CHECK: clt	%r0, 12, 0(%r1)             # encoding: [0xeb,0x0c,0x10,0x00,0x00,0x23]
#CHECK: clt	%r0, 12, 0(%r15)            # encoding: [0xeb,0x0c,0xf0,0x00,0x00,0x23]
#CHECK: clt	%r0, 12, 12345(%r6)         # encoding: [0xeb,0x0c,0x60,0x39,0x03,0x23]
#CHECK: clt	%r15, 12, 0                 # encoding: [0xeb,0xfc,0x00,0x00,0x00,0x23]
#CHECK: clth	%r0, 0(%r15)                # encoding: [0xeb,0x02,0xf0,0x00,0x00,0x23]
#CHECK: cltl	%r0, 0(%r15)                # encoding: [0xeb,0x04,0xf0,0x00,0x00,0x23]
#CHECK: clte	%r0, 0(%r15)                # encoding: [0xeb,0x08,0xf0,0x00,0x00,0x23]
#CHECK: cltne	%r0, 0(%r15)                # encoding: [0xeb,0x06,0xf0,0x00,0x00,0x23]
#CHECK: cltnl	%r0, 0(%r15)                # encoding: [0xeb,0x0a,0xf0,0x00,0x00,0x23]
#CHECK: cltnh	%r0, 0(%r15)                # encoding: [0xeb,0x0c,0xf0,0x00,0x00,0x23]

	clt	%r0, 12, -524288
	clt	%r0, 12, -1
	clt	%r0, 12, 0
	clt	%r0, 12, 1
	clt	%r0, 12, 524287
	clt	%r0, 12, 0(%r1)
	clt	%r0, 12, 0(%r15)
	clt	%r0, 12, 12345(%r6)
	clt	%r15, 12, 0
	clth	%r0, 0(%r15)
	cltl	%r0, 0(%r15)
	clte	%r0, 0(%r15)
	cltne	%r0, 0(%r15)
	cltnl	%r0, 0(%r15)
	cltnh	%r0, 0(%r15)

#CHECK: clgt	%r0, 12, -524288            # encoding: [0xeb,0x0c,0x00,0x00,0x80,0x2b]
#CHECK: clgt	%r0, 12, -1                 # encoding: [0xeb,0x0c,0x0f,0xff,0xff,0x2b]
#CHECK: clgt	%r0, 12, 0                  # encoding: [0xeb,0x0c,0x00,0x00,0x00,0x2b]
#CHECK: clgt	%r0, 12, 1                  # encoding: [0xeb,0x0c,0x00,0x01,0x00,0x2b]
#CHECK: clgt	%r0, 12, 524287             # encoding: [0xeb,0x0c,0x0f,0xff,0x7f,0x2b]
#CHECK: clgt	%r0, 12, 0(%r1)             # encoding: [0xeb,0x0c,0x10,0x00,0x00,0x2b]
#CHECK: clgt	%r0, 12, 0(%r15)            # encoding: [0xeb,0x0c,0xf0,0x00,0x00,0x2b]
#CHECK: clgt	%r0, 12, 12345(%r6)         # encoding: [0xeb,0x0c,0x60,0x39,0x03,0x2b]
#CHECK: clgt	%r15, 12, 0                 # encoding: [0xeb,0xfc,0x00,0x00,0x00,0x2b]
#CHECK: clgth	%r0, 0(%r15)                # encoding: [0xeb,0x02,0xf0,0x00,0x00,0x2b]
#CHECK: clgtl	%r0, 0(%r15)                # encoding: [0xeb,0x04,0xf0,0x00,0x00,0x2b]
#CHECK: clgte	%r0, 0(%r15)                # encoding: [0xeb,0x08,0xf0,0x00,0x00,0x2b]
#CHECK: clgtne	%r0, 0(%r15)                # encoding: [0xeb,0x06,0xf0,0x00,0x00,0x2b]
#CHECK: clgtnl	%r0, 0(%r15)                # encoding: [0xeb,0x0a,0xf0,0x00,0x00,0x2b]
#CHECK: clgtnh	%r0, 0(%r15)                # encoding: [0xeb,0x0c,0xf0,0x00,0x00,0x2b]

	clgt	%r0, 12, -524288
	clgt	%r0, 12, -1
	clgt	%r0, 12, 0
	clgt	%r0, 12, 1
	clgt	%r0, 12, 524287
	clgt	%r0, 12, 0(%r1)
	clgt	%r0, 12, 0(%r15)
	clgt	%r0, 12, 12345(%r6)
	clgt	%r15, 12, 0
	clgth	%r0, 0(%r15)
	clgtl	%r0, 0(%r15)
	clgte	%r0, 0(%r15)
	clgtne	%r0, 0(%r15)
	clgtnl	%r0, 0(%r15)
	clgtnh	%r0, 0(%r15)

#CHECK: etnd	%r0                     # encoding: [0xb2,0xec,0x00,0x00]
#CHECK: etnd	%r15                    # encoding: [0xb2,0xec,0x00,0xf0]
#CHECK: etnd	%r7                     # encoding: [0xb2,0xec,0x00,0x70]

	etnd	%r0
	etnd	%r15
	etnd	%r7

#CHECK: ntstg	%r0, -524288            # encoding: [0xe3,0x00,0x00,0x00,0x80,0x25]
#CHECK: ntstg	%r0, -1                 # encoding: [0xe3,0x00,0x0f,0xff,0xff,0x25]
#CHECK: ntstg	%r0, 0                  # encoding: [0xe3,0x00,0x00,0x00,0x00,0x25]
#CHECK: ntstg	%r0, 1                  # encoding: [0xe3,0x00,0x00,0x01,0x00,0x25]
#CHECK: ntstg	%r0, 524287             # encoding: [0xe3,0x00,0x0f,0xff,0x7f,0x25]
#CHECK: ntstg	%r0, 0(%r1)             # encoding: [0xe3,0x00,0x10,0x00,0x00,0x25]
#CHECK: ntstg	%r0, 0(%r15)            # encoding: [0xe3,0x00,0xf0,0x00,0x00,0x25]
#CHECK: ntstg	%r0, 524287(%r1,%r15)   # encoding: [0xe3,0x01,0xff,0xff,0x7f,0x25]
#CHECK: ntstg	%r0, 524287(%r15,%r1)   # encoding: [0xe3,0x0f,0x1f,0xff,0x7f,0x25]
#CHECK: ntstg	%r15, 0                 # encoding: [0xe3,0xf0,0x00,0x00,0x00,0x25]

	ntstg	%r0, -524288
	ntstg	%r0, -1
	ntstg	%r0, 0
	ntstg	%r0, 1
	ntstg	%r0, 524287
	ntstg	%r0, 0(%r1)
	ntstg	%r0, 0(%r15)
	ntstg	%r0, 524287(%r1,%r15)
	ntstg	%r0, 524287(%r15,%r1)
	ntstg	%r15, 0

#CHECK: ppa	%r0, %r0, 0             # encoding: [0xb2,0xe8,0x00,0x00]
#CHECK: ppa	%r0, %r0, 15            # encoding: [0xb2,0xe8,0xf0,0x00]
#CHECK: ppa	%r0, %r15, 0            # encoding: [0xb2,0xe8,0x00,0x0f]
#CHECK: ppa	%r4, %r6, 7             # encoding: [0xb2,0xe8,0x70,0x46]
#CHECK: ppa	%r15, %r0, 0            # encoding: [0xb2,0xe8,0x00,0xf0]

	ppa	%r0, %r0, 0
	ppa	%r0, %r0, 15
	ppa	%r0, %r15, 0
	ppa	%r4, %r6, 7
	ppa	%r15, %r0, 0

#CHECK: risbgn	%r0, %r0, 0, 0, 0       # encoding: [0xec,0x00,0x00,0x00,0x00,0x59]
#CHECK: risbgn	%r0, %r0, 0, 0, 63      # encoding: [0xec,0x00,0x00,0x00,0x3f,0x59]
#CHECK: risbgn	%r0, %r0, 0, 255, 0     # encoding: [0xec,0x00,0x00,0xff,0x00,0x59]
#CHECK: risbgn	%r0, %r0, 255, 0, 0     # encoding: [0xec,0x00,0xff,0x00,0x00,0x59]
#CHECK: risbgn	%r0, %r15, 0, 0, 0      # encoding: [0xec,0x0f,0x00,0x00,0x00,0x59]
#CHECK: risbgn	%r15, %r0, 0, 0, 0      # encoding: [0xec,0xf0,0x00,0x00,0x00,0x59]
#CHECK: risbgn	%r4, %r5, 6, 7, 8       # encoding: [0xec,0x45,0x06,0x07,0x08,0x59]

	risbgn	%r0,%r0,0,0,0
	risbgn	%r0,%r0,0,0,63
	risbgn	%r0,%r0,0,255,0
	risbgn	%r0,%r0,255,0,0
	risbgn	%r0,%r15,0,0,0
	risbgn	%r15,%r0,0,0,0
	risbgn	%r4,%r5,6,7,8

#CHECK: tabort	0                       # encoding: [0xb2,0xfc,0x00,0x00]
#CHECK: tabort	0(%r1)                  # encoding: [0xb2,0xfc,0x10,0x00]
#CHECK: tabort	0(%r15)                 # encoding: [0xb2,0xfc,0xf0,0x00]
#CHECK: tabort	4095                    # encoding: [0xb2,0xfc,0x0f,0xff]
#CHECK: tabort	4095(%r1)               # encoding: [0xb2,0xfc,0x1f,0xff]
#CHECK: tabort	4095(%r15)              # encoding: [0xb2,0xfc,0xff,0xff]

	tabort	0
	tabort	0(%r1)
	tabort	0(%r15)
	tabort	4095
	tabort	4095(%r1)
	tabort	4095(%r15)

#CHECK: tbegin	0, 0                    # encoding: [0xe5,0x60,0x00,0x00,0x00,0x00]
#CHECK: tbegin	4095, 0                 # encoding: [0xe5,0x60,0x0f,0xff,0x00,0x00]
#CHECK: tbegin	0, 0                    # encoding: [0xe5,0x60,0x00,0x00,0x00,0x00]
#CHECK: tbegin	0, 1                    # encoding: [0xe5,0x60,0x00,0x00,0x00,0x01]
#CHECK: tbegin	0, 32767                # encoding: [0xe5,0x60,0x00,0x00,0x7f,0xff]
#CHECK: tbegin	0, 32768                # encoding: [0xe5,0x60,0x00,0x00,0x80,0x00]
#CHECK: tbegin	0, 65535                # encoding: [0xe5,0x60,0x00,0x00,0xff,0xff]
#CHECK: tbegin	0(%r1), 42              # encoding: [0xe5,0x60,0x10,0x00,0x00,0x2a]
#CHECK: tbegin	0(%r15), 42             # encoding: [0xe5,0x60,0xf0,0x00,0x00,0x2a]
#CHECK: tbegin	4095(%r1), 42           # encoding: [0xe5,0x60,0x1f,0xff,0x00,0x2a]
#CHECK: tbegin	4095(%r15), 42          # encoding: [0xe5,0x60,0xff,0xff,0x00,0x2a]

	tbegin	0, 0
	tbegin	4095, 0
	tbegin	0, 0
	tbegin	0, 1
	tbegin	0, 32767
	tbegin	0, 32768
	tbegin	0, 65535
	tbegin	0(%r1), 42
	tbegin	0(%r15), 42
	tbegin	4095(%r1), 42
	tbegin	4095(%r15), 42

#CHECK: tbeginc	0, 0                    # encoding: [0xe5,0x61,0x00,0x00,0x00,0x00]
#CHECK: tbeginc	4095, 0                 # encoding: [0xe5,0x61,0x0f,0xff,0x00,0x00]
#CHECK: tbeginc	0, 0                    # encoding: [0xe5,0x61,0x00,0x00,0x00,0x00]
#CHECK: tbeginc	0, 1                    # encoding: [0xe5,0x61,0x00,0x00,0x00,0x01]
#CHECK: tbeginc	0, 32767                # encoding: [0xe5,0x61,0x00,0x00,0x7f,0xff]
#CHECK: tbeginc	0, 32768                # encoding: [0xe5,0x61,0x00,0x00,0x80,0x00]
#CHECK: tbeginc	0, 65535                # encoding: [0xe5,0x61,0x00,0x00,0xff,0xff]
#CHECK: tbeginc	0(%r1), 42              # encoding: [0xe5,0x61,0x10,0x00,0x00,0x2a]
#CHECK: tbeginc	0(%r15), 42             # encoding: [0xe5,0x61,0xf0,0x00,0x00,0x2a]
#CHECK: tbeginc	4095(%r1), 42           # encoding: [0xe5,0x61,0x1f,0xff,0x00,0x2a]
#CHECK: tbeginc	4095(%r15), 42          # encoding: [0xe5,0x61,0xff,0xff,0x00,0x2a]

	tbeginc	0, 0
	tbeginc	4095, 0
	tbeginc	0, 0
	tbeginc	0, 1
	tbeginc	0, 32767
	tbeginc	0, 32768
	tbeginc	0, 65535
	tbeginc	0(%r1), 42
	tbeginc	0(%r15), 42
	tbeginc	4095(%r1), 42
	tbeginc	4095(%r15), 42

#CHECK: tend                            # encoding: [0xb2,0xf8,0x00,0x00]

	tend
