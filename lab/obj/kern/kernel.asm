
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 e0 11 f0       	mov    $0xf011e000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d c0 9e 20 f0 00 	cmpl   $0x0,0xf0209ec0
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 c0 9e 20 f0    	mov    %esi,0xf0209ec0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 8e 59 00 00       	call   f01059ef <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 c0 60 10 f0       	push   $0xf01060c0
f010006d:	e8 af 37 00 00       	call   f0103821 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 7f 37 00 00       	call   f01037fb <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 ee 78 10 f0 	movl   $0xf01078ee,(%esp)
f0100083:	e8 99 37 00 00       	call   f0103821 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 7e 08 00 00       	call   f0100913 <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 b0 24 f0       	mov    $0xf024b008,%eax
f01000a6:	2d 50 8f 20 f0       	sub    $0xf0208f50,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 50 8f 20 f0       	push   $0xf0208f50
f01000b3:	e8 12 53 00 00       	call   f01053ca <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 86 05 00 00       	call   f0100643 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 2c 61 10 f0       	push   $0xf010612c
f01000ca:	e8 52 37 00 00       	call   f0103821 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 18 13 00 00       	call   f01013ec <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 e7 2f 00 00       	call   f01030c0 <env_init>
	trap_init();
f01000d9:	e8 ec 37 00 00       	call   f01038ca <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 05 56 00 00       	call   f01056e8 <mp_init>
	lapic_init();
f01000e3:	e8 22 59 00 00       	call   f0105a0a <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 70 36 00 00       	call   f010375d <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f01000f4:	e8 61 5b 00 00       	call   f0105c5a <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d c8 9e 20 f0 07 	cmpl   $0x7,0xf0209ec8
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 e4 60 10 f0       	push   $0xf01060e4
f010010f:	6a 63                	push   $0x63
f0100111:	68 47 61 10 f0       	push   $0xf0106147
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 4e 56 10 f0       	mov    $0xf010564e,%eax
f0100123:	2d d4 55 10 f0       	sub    $0xf01055d4,%eax
f0100128:	50                   	push   %eax
f0100129:	68 d4 55 10 f0       	push   $0xf01055d4
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 df 52 00 00       	call   f0105417 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 40 a0 20 f0       	mov    $0xf020a040,%ebx
f0100140:	eb 4e                	jmp    f0100190 <i386_init+0xf6>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 a8 58 00 00       	call   f01059ef <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 40 a0 20 f0       	add    $0xf020a040,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 3a                	je     f010018d <i386_init+0xf3>
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 40 a0 20 f0       	sub    $0xf020a040,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	8d 80 00 30 21 f0    	lea    -0xfded000(%eax),%eax
f010016c:	a3 c4 9e 20 f0       	mov    %eax,0xf0209ec4
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100171:	83 ec 08             	sub    $0x8,%esp
f0100174:	68 00 70 00 00       	push   $0x7000
f0100179:	0f b6 03             	movzbl (%ebx),%eax
f010017c:	50                   	push   %eax
f010017d:	e8 d6 59 00 00       	call   f0105b58 <lapic_startap>
f0100182:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100185:	8b 43 04             	mov    0x4(%ebx),%eax
f0100188:	83 f8 01             	cmp    $0x1,%eax
f010018b:	75 f8                	jne    f0100185 <i386_init+0xeb>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018d:	83 c3 74             	add    $0x74,%ebx
f0100190:	6b 05 e4 a3 20 f0 74 	imul   $0x74,0xf020a3e4,%eax
f0100197:	05 40 a0 20 f0       	add    $0xf020a040,%eax
f010019c:	39 c3                	cmp    %eax,%ebx
f010019e:	72 a2                	jb     f0100142 <i386_init+0xa8>

	// Starting non-boot CPUs
	boot_aps();

	// Start fs.
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f01001a0:	83 ec 08             	sub    $0x8,%esp
f01001a3:	6a 01                	push   $0x1
f01001a5:	68 3c 7d 1c f0       	push   $0xf01c7d3c
f01001aa:	e8 af 30 00 00       	call   f010325e <env_create>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001af:	83 c4 08             	add    $0x8,%esp
f01001b2:	6a 00                	push   $0x0
f01001b4:	68 ac 90 1f f0       	push   $0xf01f90ac
f01001b9:	e8 a0 30 00 00       	call   f010325e <env_create>
	//ENV_CREATE(user_yield, ENV_TYPE_USER);

#endif // TEST*

	// Should not be necessary - drains keyboard because interrupt has given up.
	kbd_intr();
f01001be:	e8 24 04 00 00       	call   f01005e7 <kbd_intr>

	// Schedule and run the first user environment!
	sched_yield();
f01001c3:	e8 0e 40 00 00       	call   f01041d6 <sched_yield>

f01001c8 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001c8:	55                   	push   %ebp
f01001c9:	89 e5                	mov    %esp,%ebp
f01001cb:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001ce:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001d3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001d8:	77 12                	ja     f01001ec <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001da:	50                   	push   %eax
f01001db:	68 08 61 10 f0       	push   $0xf0106108
f01001e0:	6a 7a                	push   $0x7a
f01001e2:	68 47 61 10 f0       	push   $0xf0106147
f01001e7:	e8 54 fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01001ec:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001f1:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001f4:	e8 f6 57 00 00       	call   f01059ef <cpunum>
f01001f9:	83 ec 08             	sub    $0x8,%esp
f01001fc:	50                   	push   %eax
f01001fd:	68 53 61 10 f0       	push   $0xf0106153
f0100202:	e8 1a 36 00 00       	call   f0103821 <cprintf>

	lapic_init();
f0100207:	e8 fe 57 00 00       	call   f0105a0a <lapic_init>
	env_init_percpu();
f010020c:	e8 85 2e 00 00       	call   f0103096 <env_init_percpu>
	trap_init_percpu();
f0100211:	e8 1f 36 00 00       	call   f0103835 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100216:	e8 d4 57 00 00       	call   f01059ef <cpunum>
f010021b:	6b d0 74             	imul   $0x74,%eax,%edx
f010021e:	81 c2 40 a0 20 f0    	add    $0xf020a040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100224:	b8 01 00 00 00       	mov    $0x1,%eax
f0100229:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010022d:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f0100234:	e8 21 5a 00 00       	call   f0105c5a <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f0100239:	e8 98 3f 00 00       	call   f01041d6 <sched_yield>

f010023e <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010023e:	55                   	push   %ebp
f010023f:	89 e5                	mov    %esp,%ebp
f0100241:	53                   	push   %ebx
f0100242:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100245:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100248:	ff 75 0c             	pushl  0xc(%ebp)
f010024b:	ff 75 08             	pushl  0x8(%ebp)
f010024e:	68 69 61 10 f0       	push   $0xf0106169
f0100253:	e8 c9 35 00 00       	call   f0103821 <cprintf>
	vcprintf(fmt, ap);
f0100258:	83 c4 08             	add    $0x8,%esp
f010025b:	53                   	push   %ebx
f010025c:	ff 75 10             	pushl  0x10(%ebp)
f010025f:	e8 97 35 00 00       	call   f01037fb <vcprintf>
	cprintf("\n");
f0100264:	c7 04 24 ee 78 10 f0 	movl   $0xf01078ee,(%esp)
f010026b:	e8 b1 35 00 00       	call   f0103821 <cprintf>
	va_end(ap);
f0100270:	83 c4 10             	add    $0x10,%esp
}
f0100273:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100276:	c9                   	leave  
f0100277:	c3                   	ret    

f0100278 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100278:	55                   	push   %ebp
f0100279:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010027b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100280:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100281:	a8 01                	test   $0x1,%al
f0100283:	74 08                	je     f010028d <serial_proc_data+0x15>
f0100285:	b2 f8                	mov    $0xf8,%dl
f0100287:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100288:	0f b6 c0             	movzbl %al,%eax
f010028b:	eb 05                	jmp    f0100292 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010028d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100292:	5d                   	pop    %ebp
f0100293:	c3                   	ret    

f0100294 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100294:	55                   	push   %ebp
f0100295:	89 e5                	mov    %esp,%ebp
f0100297:	53                   	push   %ebx
f0100298:	83 ec 04             	sub    $0x4,%esp
f010029b:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010029d:	eb 2a                	jmp    f01002c9 <cons_intr+0x35>
		if (c == 0)
f010029f:	85 d2                	test   %edx,%edx
f01002a1:	74 26                	je     f01002c9 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002a3:	a1 44 92 20 f0       	mov    0xf0209244,%eax
f01002a8:	8d 48 01             	lea    0x1(%eax),%ecx
f01002ab:	89 0d 44 92 20 f0    	mov    %ecx,0xf0209244
f01002b1:	88 90 40 90 20 f0    	mov    %dl,-0xfdf6fc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002b7:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002bd:	75 0a                	jne    f01002c9 <cons_intr+0x35>
			cons.wpos = 0;
f01002bf:	c7 05 44 92 20 f0 00 	movl   $0x0,0xf0209244
f01002c6:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002c9:	ff d3                	call   *%ebx
f01002cb:	89 c2                	mov    %eax,%edx
f01002cd:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002d0:	75 cd                	jne    f010029f <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002d2:	83 c4 04             	add    $0x4,%esp
f01002d5:	5b                   	pop    %ebx
f01002d6:	5d                   	pop    %ebp
f01002d7:	c3                   	ret    

f01002d8 <kbd_proc_data>:
f01002d8:	ba 64 00 00 00       	mov    $0x64,%edx
f01002dd:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002de:	a8 01                	test   $0x1,%al
f01002e0:	0f 84 f0 00 00 00    	je     f01003d6 <kbd_proc_data+0xfe>
f01002e6:	b2 60                	mov    $0x60,%dl
f01002e8:	ec                   	in     (%dx),%al
f01002e9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002eb:	3c e0                	cmp    $0xe0,%al
f01002ed:	75 0d                	jne    f01002fc <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01002ef:	83 0d 00 90 20 f0 40 	orl    $0x40,0xf0209000
		return 0;
f01002f6:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002fb:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002fc:	55                   	push   %ebp
f01002fd:	89 e5                	mov    %esp,%ebp
f01002ff:	53                   	push   %ebx
f0100300:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100303:	84 c0                	test   %al,%al
f0100305:	79 36                	jns    f010033d <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100307:	8b 0d 00 90 20 f0    	mov    0xf0209000,%ecx
f010030d:	89 cb                	mov    %ecx,%ebx
f010030f:	83 e3 40             	and    $0x40,%ebx
f0100312:	83 e0 7f             	and    $0x7f,%eax
f0100315:	85 db                	test   %ebx,%ebx
f0100317:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010031a:	0f b6 d2             	movzbl %dl,%edx
f010031d:	0f b6 82 00 63 10 f0 	movzbl -0xfef9d00(%edx),%eax
f0100324:	83 c8 40             	or     $0x40,%eax
f0100327:	0f b6 c0             	movzbl %al,%eax
f010032a:	f7 d0                	not    %eax
f010032c:	21 c8                	and    %ecx,%eax
f010032e:	a3 00 90 20 f0       	mov    %eax,0xf0209000
		return 0;
f0100333:	b8 00 00 00 00       	mov    $0x0,%eax
f0100338:	e9 a1 00 00 00       	jmp    f01003de <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010033d:	8b 0d 00 90 20 f0    	mov    0xf0209000,%ecx
f0100343:	f6 c1 40             	test   $0x40,%cl
f0100346:	74 0e                	je     f0100356 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100348:	83 c8 80             	or     $0xffffff80,%eax
f010034b:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010034d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100350:	89 0d 00 90 20 f0    	mov    %ecx,0xf0209000
	}

	shift |= shiftcode[data];
f0100356:	0f b6 c2             	movzbl %dl,%eax
f0100359:	0f b6 90 00 63 10 f0 	movzbl -0xfef9d00(%eax),%edx
f0100360:	0b 15 00 90 20 f0    	or     0xf0209000,%edx
	shift ^= togglecode[data];
f0100366:	0f b6 88 00 62 10 f0 	movzbl -0xfef9e00(%eax),%ecx
f010036d:	31 ca                	xor    %ecx,%edx
f010036f:	89 15 00 90 20 f0    	mov    %edx,0xf0209000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100375:	89 d1                	mov    %edx,%ecx
f0100377:	83 e1 03             	and    $0x3,%ecx
f010037a:	8b 0c 8d c0 61 10 f0 	mov    -0xfef9e40(,%ecx,4),%ecx
f0100381:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100385:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100388:	f6 c2 08             	test   $0x8,%dl
f010038b:	74 1b                	je     f01003a8 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010038d:	89 d8                	mov    %ebx,%eax
f010038f:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100392:	83 f9 19             	cmp    $0x19,%ecx
f0100395:	77 05                	ja     f010039c <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100397:	83 eb 20             	sub    $0x20,%ebx
f010039a:	eb 0c                	jmp    f01003a8 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f010039c:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010039f:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003a2:	83 f8 19             	cmp    $0x19,%eax
f01003a5:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003a8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003ae:	75 2c                	jne    f01003dc <kbd_proc_data+0x104>
f01003b0:	f7 d2                	not    %edx
f01003b2:	f6 c2 06             	test   $0x6,%dl
f01003b5:	75 25                	jne    f01003dc <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003b7:	83 ec 0c             	sub    $0xc,%esp
f01003ba:	68 83 61 10 f0       	push   $0xf0106183
f01003bf:	e8 5d 34 00 00       	call   f0103821 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003c4:	ba 92 00 00 00       	mov    $0x92,%edx
f01003c9:	b8 03 00 00 00       	mov    $0x3,%eax
f01003ce:	ee                   	out    %al,(%dx)
f01003cf:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003d2:	89 d8                	mov    %ebx,%eax
f01003d4:	eb 08                	jmp    f01003de <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003db:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003dc:	89 d8                	mov    %ebx,%eax
}
f01003de:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003e1:	c9                   	leave  
f01003e2:	c3                   	ret    

f01003e3 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003e3:	55                   	push   %ebp
f01003e4:	89 e5                	mov    %esp,%ebp
f01003e6:	57                   	push   %edi
f01003e7:	56                   	push   %esi
f01003e8:	53                   	push   %ebx
f01003e9:	83 ec 1c             	sub    $0x1c,%esp
f01003ec:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003ee:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f3:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003f8:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003fd:	eb 09                	jmp    f0100408 <cons_putc+0x25>
f01003ff:	89 ca                	mov    %ecx,%edx
f0100401:	ec                   	in     (%dx),%al
f0100402:	ec                   	in     (%dx),%al
f0100403:	ec                   	in     (%dx),%al
f0100404:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100405:	83 c3 01             	add    $0x1,%ebx
f0100408:	89 f2                	mov    %esi,%edx
f010040a:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010040b:	a8 20                	test   $0x20,%al
f010040d:	75 08                	jne    f0100417 <cons_putc+0x34>
f010040f:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100415:	7e e8                	jle    f01003ff <cons_putc+0x1c>
f0100417:	89 f8                	mov    %edi,%eax
f0100419:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010041c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100421:	89 f8                	mov    %edi,%eax
f0100423:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100424:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100429:	be 79 03 00 00       	mov    $0x379,%esi
f010042e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100433:	eb 09                	jmp    f010043e <cons_putc+0x5b>
f0100435:	89 ca                	mov    %ecx,%edx
f0100437:	ec                   	in     (%dx),%al
f0100438:	ec                   	in     (%dx),%al
f0100439:	ec                   	in     (%dx),%al
f010043a:	ec                   	in     (%dx),%al
f010043b:	83 c3 01             	add    $0x1,%ebx
f010043e:	89 f2                	mov    %esi,%edx
f0100440:	ec                   	in     (%dx),%al
f0100441:	84 c0                	test   %al,%al
f0100443:	78 08                	js     f010044d <cons_putc+0x6a>
f0100445:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010044b:	7e e8                	jle    f0100435 <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010044d:	ba 78 03 00 00       	mov    $0x378,%edx
f0100452:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100456:	ee                   	out    %al,(%dx)
f0100457:	b2 7a                	mov    $0x7a,%dl
f0100459:	b8 0d 00 00 00       	mov    $0xd,%eax
f010045e:	ee                   	out    %al,(%dx)
f010045f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100464:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100465:	89 fa                	mov    %edi,%edx
f0100467:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010046d:	89 f8                	mov    %edi,%eax
f010046f:	80 cc 07             	or     $0x7,%ah
f0100472:	85 d2                	test   %edx,%edx
f0100474:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100477:	89 f8                	mov    %edi,%eax
f0100479:	0f b6 c0             	movzbl %al,%eax
f010047c:	83 f8 09             	cmp    $0x9,%eax
f010047f:	74 74                	je     f01004f5 <cons_putc+0x112>
f0100481:	83 f8 09             	cmp    $0x9,%eax
f0100484:	7f 0a                	jg     f0100490 <cons_putc+0xad>
f0100486:	83 f8 08             	cmp    $0x8,%eax
f0100489:	74 14                	je     f010049f <cons_putc+0xbc>
f010048b:	e9 99 00 00 00       	jmp    f0100529 <cons_putc+0x146>
f0100490:	83 f8 0a             	cmp    $0xa,%eax
f0100493:	74 3a                	je     f01004cf <cons_putc+0xec>
f0100495:	83 f8 0d             	cmp    $0xd,%eax
f0100498:	74 3d                	je     f01004d7 <cons_putc+0xf4>
f010049a:	e9 8a 00 00 00       	jmp    f0100529 <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f010049f:	0f b7 05 48 92 20 f0 	movzwl 0xf0209248,%eax
f01004a6:	66 85 c0             	test   %ax,%ax
f01004a9:	0f 84 e6 00 00 00    	je     f0100595 <cons_putc+0x1b2>
			crt_pos--;
f01004af:	83 e8 01             	sub    $0x1,%eax
f01004b2:	66 a3 48 92 20 f0    	mov    %ax,0xf0209248
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b8:	0f b7 c0             	movzwl %ax,%eax
f01004bb:	66 81 e7 00 ff       	and    $0xff00,%di
f01004c0:	83 cf 20             	or     $0x20,%edi
f01004c3:	8b 15 4c 92 20 f0    	mov    0xf020924c,%edx
f01004c9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004cd:	eb 78                	jmp    f0100547 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cf:	66 83 05 48 92 20 f0 	addw   $0x50,0xf0209248
f01004d6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d7:	0f b7 05 48 92 20 f0 	movzwl 0xf0209248,%eax
f01004de:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e4:	c1 e8 16             	shr    $0x16,%eax
f01004e7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004ea:	c1 e0 04             	shl    $0x4,%eax
f01004ed:	66 a3 48 92 20 f0    	mov    %ax,0xf0209248
f01004f3:	eb 52                	jmp    f0100547 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f01004f5:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fa:	e8 e4 fe ff ff       	call   f01003e3 <cons_putc>
		cons_putc(' ');
f01004ff:	b8 20 00 00 00       	mov    $0x20,%eax
f0100504:	e8 da fe ff ff       	call   f01003e3 <cons_putc>
		cons_putc(' ');
f0100509:	b8 20 00 00 00       	mov    $0x20,%eax
f010050e:	e8 d0 fe ff ff       	call   f01003e3 <cons_putc>
		cons_putc(' ');
f0100513:	b8 20 00 00 00       	mov    $0x20,%eax
f0100518:	e8 c6 fe ff ff       	call   f01003e3 <cons_putc>
		cons_putc(' ');
f010051d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100522:	e8 bc fe ff ff       	call   f01003e3 <cons_putc>
f0100527:	eb 1e                	jmp    f0100547 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100529:	0f b7 05 48 92 20 f0 	movzwl 0xf0209248,%eax
f0100530:	8d 50 01             	lea    0x1(%eax),%edx
f0100533:	66 89 15 48 92 20 f0 	mov    %dx,0xf0209248
f010053a:	0f b7 c0             	movzwl %ax,%eax
f010053d:	8b 15 4c 92 20 f0    	mov    0xf020924c,%edx
f0100543:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100547:	66 81 3d 48 92 20 f0 	cmpw   $0x7cf,0xf0209248
f010054e:	cf 07 
f0100550:	76 43                	jbe    f0100595 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100552:	a1 4c 92 20 f0       	mov    0xf020924c,%eax
f0100557:	83 ec 04             	sub    $0x4,%esp
f010055a:	68 00 0f 00 00       	push   $0xf00
f010055f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100565:	52                   	push   %edx
f0100566:	50                   	push   %eax
f0100567:	e8 ab 4e 00 00       	call   f0105417 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010056c:	8b 15 4c 92 20 f0    	mov    0xf020924c,%edx
f0100572:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100578:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010057e:	83 c4 10             	add    $0x10,%esp
f0100581:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100586:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100589:	39 d0                	cmp    %edx,%eax
f010058b:	75 f4                	jne    f0100581 <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010058d:	66 83 2d 48 92 20 f0 	subw   $0x50,0xf0209248
f0100594:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100595:	8b 0d 50 92 20 f0    	mov    0xf0209250,%ecx
f010059b:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005a0:	89 ca                	mov    %ecx,%edx
f01005a2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005a3:	0f b7 1d 48 92 20 f0 	movzwl 0xf0209248,%ebx
f01005aa:	8d 71 01             	lea    0x1(%ecx),%esi
f01005ad:	89 d8                	mov    %ebx,%eax
f01005af:	66 c1 e8 08          	shr    $0x8,%ax
f01005b3:	89 f2                	mov    %esi,%edx
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bb:	89 ca                	mov    %ecx,%edx
f01005bd:	ee                   	out    %al,(%dx)
f01005be:	89 d8                	mov    %ebx,%eax
f01005c0:	89 f2                	mov    %esi,%edx
f01005c2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005c6:	5b                   	pop    %ebx
f01005c7:	5e                   	pop    %esi
f01005c8:	5f                   	pop    %edi
f01005c9:	5d                   	pop    %ebp
f01005ca:	c3                   	ret    

f01005cb <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005cb:	80 3d 54 92 20 f0 00 	cmpb   $0x0,0xf0209254
f01005d2:	74 11                	je     f01005e5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005d4:	55                   	push   %ebp
f01005d5:	89 e5                	mov    %esp,%ebp
f01005d7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005da:	b8 78 02 10 f0       	mov    $0xf0100278,%eax
f01005df:	e8 b0 fc ff ff       	call   f0100294 <cons_intr>
}
f01005e4:	c9                   	leave  
f01005e5:	f3 c3                	repz ret 

f01005e7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005e7:	55                   	push   %ebp
f01005e8:	89 e5                	mov    %esp,%ebp
f01005ea:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005ed:	b8 d8 02 10 f0       	mov    $0xf01002d8,%eax
f01005f2:	e8 9d fc ff ff       	call   f0100294 <cons_intr>
}
f01005f7:	c9                   	leave  
f01005f8:	c3                   	ret    

f01005f9 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005f9:	55                   	push   %ebp
f01005fa:	89 e5                	mov    %esp,%ebp
f01005fc:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005ff:	e8 c7 ff ff ff       	call   f01005cb <serial_intr>
	kbd_intr();
f0100604:	e8 de ff ff ff       	call   f01005e7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100609:	a1 40 92 20 f0       	mov    0xf0209240,%eax
f010060e:	3b 05 44 92 20 f0    	cmp    0xf0209244,%eax
f0100614:	74 26                	je     f010063c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100616:	8d 50 01             	lea    0x1(%eax),%edx
f0100619:	89 15 40 92 20 f0    	mov    %edx,0xf0209240
f010061f:	0f b6 88 40 90 20 f0 	movzbl -0xfdf6fc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100626:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100628:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010062e:	75 11                	jne    f0100641 <cons_getc+0x48>
			cons.rpos = 0;
f0100630:	c7 05 40 92 20 f0 00 	movl   $0x0,0xf0209240
f0100637:	00 00 00 
f010063a:	eb 05                	jmp    f0100641 <cons_getc+0x48>
		return c;
	}
	return 0;
f010063c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100641:	c9                   	leave  
f0100642:	c3                   	ret    

f0100643 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100643:	55                   	push   %ebp
f0100644:	89 e5                	mov    %esp,%ebp
f0100646:	57                   	push   %edi
f0100647:	56                   	push   %esi
f0100648:	53                   	push   %ebx
f0100649:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010064c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100653:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010065a:	5a a5 
	if (*cp != 0xA55A) {
f010065c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100663:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100667:	74 11                	je     f010067a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100669:	c7 05 50 92 20 f0 b4 	movl   $0x3b4,0xf0209250
f0100670:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100673:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100678:	eb 16                	jmp    f0100690 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010067a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100681:	c7 05 50 92 20 f0 d4 	movl   $0x3d4,0xf0209250
f0100688:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010068b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100690:	8b 3d 50 92 20 f0    	mov    0xf0209250,%edi
f0100696:	b8 0e 00 00 00       	mov    $0xe,%eax
f010069b:	89 fa                	mov    %edi,%edx
f010069d:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010069e:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a1:	89 ca                	mov    %ecx,%edx
f01006a3:	ec                   	in     (%dx),%al
f01006a4:	0f b6 c0             	movzbl %al,%eax
f01006a7:	c1 e0 08             	shl    $0x8,%eax
f01006aa:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006b1:	89 fa                	mov    %edi,%edx
f01006b3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006b4:	89 ca                	mov    %ecx,%edx
f01006b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006b7:	89 35 4c 92 20 f0    	mov    %esi,0xf020924c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006bd:	0f b6 c8             	movzbl %al,%ecx
f01006c0:	89 d8                	mov    %ebx,%eax
f01006c2:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006c4:	66 a3 48 92 20 f0    	mov    %ax,0xf0209248

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006ca:	e8 18 ff ff ff       	call   f01005e7 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006cf:	83 ec 0c             	sub    $0xc,%esp
f01006d2:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f01006d9:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006de:	50                   	push   %eax
f01006df:	e8 04 30 00 00       	call   f01036e8 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006e4:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01006e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ee:	89 da                	mov    %ebx,%edx
f01006f0:	ee                   	out    %al,(%dx)
f01006f1:	b2 fb                	mov    $0xfb,%dl
f01006f3:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006f8:	ee                   	out    %al,(%dx)
f01006f9:	be f8 03 00 00       	mov    $0x3f8,%esi
f01006fe:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100703:	89 f2                	mov    %esi,%edx
f0100705:	ee                   	out    %al,(%dx)
f0100706:	b2 f9                	mov    $0xf9,%dl
f0100708:	b8 00 00 00 00       	mov    $0x0,%eax
f010070d:	ee                   	out    %al,(%dx)
f010070e:	b2 fb                	mov    $0xfb,%dl
f0100710:	b8 03 00 00 00       	mov    $0x3,%eax
f0100715:	ee                   	out    %al,(%dx)
f0100716:	b2 fc                	mov    $0xfc,%dl
f0100718:	b8 00 00 00 00       	mov    $0x0,%eax
f010071d:	ee                   	out    %al,(%dx)
f010071e:	b2 f9                	mov    $0xf9,%dl
f0100720:	b8 01 00 00 00       	mov    $0x1,%eax
f0100725:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100726:	b2 fd                	mov    $0xfd,%dl
f0100728:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100729:	83 c4 10             	add    $0x10,%esp
f010072c:	3c ff                	cmp    $0xff,%al
f010072e:	0f 95 c1             	setne  %cl
f0100731:	88 0d 54 92 20 f0    	mov    %cl,0xf0209254
f0100737:	89 da                	mov    %ebx,%edx
f0100739:	ec                   	in     (%dx),%al
f010073a:	89 f2                	mov    %esi,%edx
f010073c:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

	// Enable serial interrupts
	if (serial_exists)
f010073d:	84 c9                	test   %cl,%cl
f010073f:	74 21                	je     f0100762 <cons_init+0x11f>
		irq_setmask_8259A(irq_mask_8259A & ~(1<<4));
f0100741:	83 ec 0c             	sub    $0xc,%esp
f0100744:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f010074b:	25 ef ff 00 00       	and    $0xffef,%eax
f0100750:	50                   	push   %eax
f0100751:	e8 92 2f 00 00       	call   f01036e8 <irq_setmask_8259A>
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100756:	83 c4 10             	add    $0x10,%esp
f0100759:	80 3d 54 92 20 f0 00 	cmpb   $0x0,0xf0209254
f0100760:	75 10                	jne    f0100772 <cons_init+0x12f>
		cprintf("Serial port does not exist!\n");
f0100762:	83 ec 0c             	sub    $0xc,%esp
f0100765:	68 8f 61 10 f0       	push   $0xf010618f
f010076a:	e8 b2 30 00 00       	call   f0103821 <cprintf>
f010076f:	83 c4 10             	add    $0x10,%esp
}
f0100772:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100775:	5b                   	pop    %ebx
f0100776:	5e                   	pop    %esi
f0100777:	5f                   	pop    %edi
f0100778:	5d                   	pop    %ebp
f0100779:	c3                   	ret    

f010077a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010077a:	55                   	push   %ebp
f010077b:	89 e5                	mov    %esp,%ebp
f010077d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100780:	8b 45 08             	mov    0x8(%ebp),%eax
f0100783:	e8 5b fc ff ff       	call   f01003e3 <cons_putc>
}
f0100788:	c9                   	leave  
f0100789:	c3                   	ret    

f010078a <getchar>:

int
getchar(void)
{
f010078a:	55                   	push   %ebp
f010078b:	89 e5                	mov    %esp,%ebp
f010078d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100790:	e8 64 fe ff ff       	call   f01005f9 <cons_getc>
f0100795:	85 c0                	test   %eax,%eax
f0100797:	74 f7                	je     f0100790 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100799:	c9                   	leave  
f010079a:	c3                   	ret    

f010079b <iscons>:

int
iscons(int fdnum)
{
f010079b:	55                   	push   %ebp
f010079c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010079e:	b8 01 00 00 00       	mov    $0x1,%eax
f01007a3:	5d                   	pop    %ebp
f01007a4:	c3                   	ret    

f01007a5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007a5:	55                   	push   %ebp
f01007a6:	89 e5                	mov    %esp,%ebp
f01007a8:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007ab:	68 00 64 10 f0       	push   $0xf0106400
f01007b0:	68 1e 64 10 f0       	push   $0xf010641e
f01007b5:	68 23 64 10 f0       	push   $0xf0106423
f01007ba:	e8 62 30 00 00       	call   f0103821 <cprintf>
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	68 c4 64 10 f0       	push   $0xf01064c4
f01007c7:	68 2c 64 10 f0       	push   $0xf010642c
f01007cc:	68 23 64 10 f0       	push   $0xf0106423
f01007d1:	e8 4b 30 00 00       	call   f0103821 <cprintf>
f01007d6:	83 c4 0c             	add    $0xc,%esp
f01007d9:	68 35 64 10 f0       	push   $0xf0106435
f01007de:	68 52 64 10 f0       	push   $0xf0106452
f01007e3:	68 23 64 10 f0       	push   $0xf0106423
f01007e8:	e8 34 30 00 00       	call   f0103821 <cprintf>
	return 0;
}
f01007ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01007f2:	c9                   	leave  
f01007f3:	c3                   	ret    

f01007f4 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007f4:	55                   	push   %ebp
f01007f5:	89 e5                	mov    %esp,%ebp
f01007f7:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007fa:	68 5d 64 10 f0       	push   $0xf010645d
f01007ff:	e8 1d 30 00 00       	call   f0103821 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100804:	83 c4 08             	add    $0x8,%esp
f0100807:	68 0c 00 10 00       	push   $0x10000c
f010080c:	68 ec 64 10 f0       	push   $0xf01064ec
f0100811:	e8 0b 30 00 00       	call   f0103821 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100816:	83 c4 0c             	add    $0xc,%esp
f0100819:	68 0c 00 10 00       	push   $0x10000c
f010081e:	68 0c 00 10 f0       	push   $0xf010000c
f0100823:	68 14 65 10 f0       	push   $0xf0106514
f0100828:	e8 f4 2f 00 00       	call   f0103821 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010082d:	83 c4 0c             	add    $0xc,%esp
f0100830:	68 95 60 10 00       	push   $0x106095
f0100835:	68 95 60 10 f0       	push   $0xf0106095
f010083a:	68 38 65 10 f0       	push   $0xf0106538
f010083f:	e8 dd 2f 00 00       	call   f0103821 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100844:	83 c4 0c             	add    $0xc,%esp
f0100847:	68 50 8f 20 00       	push   $0x208f50
f010084c:	68 50 8f 20 f0       	push   $0xf0208f50
f0100851:	68 5c 65 10 f0       	push   $0xf010655c
f0100856:	e8 c6 2f 00 00       	call   f0103821 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010085b:	83 c4 0c             	add    $0xc,%esp
f010085e:	68 08 b0 24 00       	push   $0x24b008
f0100863:	68 08 b0 24 f0       	push   $0xf024b008
f0100868:	68 80 65 10 f0       	push   $0xf0106580
f010086d:	e8 af 2f 00 00       	call   f0103821 <cprintf>
f0100872:	b8 07 b4 24 f0       	mov    $0xf024b407,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100877:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010087c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010087f:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100884:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010088a:	85 c0                	test   %eax,%eax
f010088c:	0f 48 c2             	cmovs  %edx,%eax
f010088f:	c1 f8 0a             	sar    $0xa,%eax
f0100892:	50                   	push   %eax
f0100893:	68 a4 65 10 f0       	push   $0xf01065a4
f0100898:	e8 84 2f 00 00       	call   f0103821 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010089d:	b8 00 00 00 00       	mov    $0x0,%eax
f01008a2:	c9                   	leave  
f01008a3:	c3                   	ret    

f01008a4 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008a4:	55                   	push   %ebp
f01008a5:	89 e5                	mov    %esp,%ebp
f01008a7:	57                   	push   %edi
f01008a8:	56                   	push   %esi
f01008a9:	53                   	push   %ebx
f01008aa:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008ad:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01008af:	68 76 64 10 f0       	push   $0xf0106476
f01008b4:	e8 68 2f 00 00       	call   f0103821 <cprintf>
	
	
	while (ebp){
f01008b9:	83 c4 10             	add    $0x10,%esp
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f01008bc:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01008bf:	eb 41                	jmp    f0100902 <mon_backtrace+0x5e>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f01008c1:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f01008c4:	83 ec 08             	sub    $0x8,%esp
f01008c7:	57                   	push   %edi
f01008c8:	56                   	push   %esi
f01008c9:	e8 66 40 00 00       	call   f0104934 <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f01008ce:	89 f0                	mov    %esi,%eax
f01008d0:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008d3:	89 04 24             	mov    %eax,(%esp)
f01008d6:	ff 75 d8             	pushl  -0x28(%ebp)
f01008d9:	ff 75 dc             	pushl  -0x24(%ebp)
f01008dc:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008df:	ff 75 d0             	pushl  -0x30(%ebp)
f01008e2:	ff 73 18             	pushl  0x18(%ebx)
f01008e5:	ff 73 14             	pushl  0x14(%ebx)
f01008e8:	ff 73 10             	pushl  0x10(%ebx)
f01008eb:	ff 73 0c             	pushl  0xc(%ebx)
f01008ee:	ff 73 08             	pushl  0x8(%ebx)
f01008f1:	56                   	push   %esi
f01008f2:	53                   	push   %ebx
f01008f3:	68 d0 65 10 f0       	push   $0xf01065d0
f01008f8:	e8 24 2f 00 00       	call   f0103821 <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f01008fd:	8b 1b                	mov    (%ebx),%ebx
f01008ff:	83 c4 40             	add    $0x40,%esp
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100902:	85 db                	test   %ebx,%ebx
f0100904:	75 bb                	jne    f01008c1 <mon_backtrace+0x1d>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100906:	b8 00 00 00 00       	mov    $0x0,%eax
f010090b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010090e:	5b                   	pop    %ebx
f010090f:	5e                   	pop    %esi
f0100910:	5f                   	pop    %edi
f0100911:	5d                   	pop    %ebp
f0100912:	c3                   	ret    

f0100913 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100913:	55                   	push   %ebp
f0100914:	89 e5                	mov    %esp,%ebp
f0100916:	57                   	push   %edi
f0100917:	56                   	push   %esi
f0100918:	53                   	push   %ebx
f0100919:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010091c:	68 14 66 10 f0       	push   $0xf0106614
f0100921:	e8 fb 2e 00 00       	call   f0103821 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100926:	c7 04 24 38 66 10 f0 	movl   $0xf0106638,(%esp)
f010092d:	e8 ef 2e 00 00       	call   f0103821 <cprintf>

	if (tf != NULL)
f0100932:	83 c4 10             	add    $0x10,%esp
f0100935:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100939:	74 0e                	je     f0100949 <monitor+0x36>
		print_trapframe(tf);
f010093b:	83 ec 0c             	sub    $0xc,%esp
f010093e:	ff 75 08             	pushl  0x8(%ebp)
f0100941:	e8 f7 30 00 00       	call   f0103a3d <print_trapframe>
f0100946:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100949:	83 ec 0c             	sub    $0xc,%esp
f010094c:	68 88 64 10 f0       	push   $0xf0106488
f0100951:	e8 05 48 00 00       	call   f010515b <readline>
f0100956:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100958:	83 c4 10             	add    $0x10,%esp
f010095b:	85 c0                	test   %eax,%eax
f010095d:	74 ea                	je     f0100949 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010095f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100966:	be 00 00 00 00       	mov    $0x0,%esi
f010096b:	eb 0a                	jmp    f0100977 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010096d:	c6 03 00             	movb   $0x0,(%ebx)
f0100970:	89 f7                	mov    %esi,%edi
f0100972:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100975:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100977:	0f b6 03             	movzbl (%ebx),%eax
f010097a:	84 c0                	test   %al,%al
f010097c:	74 63                	je     f01009e1 <monitor+0xce>
f010097e:	83 ec 08             	sub    $0x8,%esp
f0100981:	0f be c0             	movsbl %al,%eax
f0100984:	50                   	push   %eax
f0100985:	68 8c 64 10 f0       	push   $0xf010648c
f010098a:	e8 fe 49 00 00       	call   f010538d <strchr>
f010098f:	83 c4 10             	add    $0x10,%esp
f0100992:	85 c0                	test   %eax,%eax
f0100994:	75 d7                	jne    f010096d <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100996:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100999:	74 46                	je     f01009e1 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010099b:	83 fe 0f             	cmp    $0xf,%esi
f010099e:	75 14                	jne    f01009b4 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009a0:	83 ec 08             	sub    $0x8,%esp
f01009a3:	6a 10                	push   $0x10
f01009a5:	68 91 64 10 f0       	push   $0xf0106491
f01009aa:	e8 72 2e 00 00       	call   f0103821 <cprintf>
f01009af:	83 c4 10             	add    $0x10,%esp
f01009b2:	eb 95                	jmp    f0100949 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009b4:	8d 7e 01             	lea    0x1(%esi),%edi
f01009b7:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009bb:	eb 03                	jmp    f01009c0 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009bd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009c0:	0f b6 03             	movzbl (%ebx),%eax
f01009c3:	84 c0                	test   %al,%al
f01009c5:	74 ae                	je     f0100975 <monitor+0x62>
f01009c7:	83 ec 08             	sub    $0x8,%esp
f01009ca:	0f be c0             	movsbl %al,%eax
f01009cd:	50                   	push   %eax
f01009ce:	68 8c 64 10 f0       	push   $0xf010648c
f01009d3:	e8 b5 49 00 00       	call   f010538d <strchr>
f01009d8:	83 c4 10             	add    $0x10,%esp
f01009db:	85 c0                	test   %eax,%eax
f01009dd:	74 de                	je     f01009bd <monitor+0xaa>
f01009df:	eb 94                	jmp    f0100975 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009e1:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009e8:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009e9:	85 f6                	test   %esi,%esi
f01009eb:	0f 84 58 ff ff ff    	je     f0100949 <monitor+0x36>
f01009f1:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009f6:	83 ec 08             	sub    $0x8,%esp
f01009f9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009fc:	ff 34 85 60 66 10 f0 	pushl  -0xfef99a0(,%eax,4)
f0100a03:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a06:	e8 24 49 00 00       	call   f010532f <strcmp>
f0100a0b:	83 c4 10             	add    $0x10,%esp
f0100a0e:	85 c0                	test   %eax,%eax
f0100a10:	75 22                	jne    f0100a34 <monitor+0x121>
			return commands[i].func(argc, argv, tf);
f0100a12:	83 ec 04             	sub    $0x4,%esp
f0100a15:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a18:	ff 75 08             	pushl  0x8(%ebp)
f0100a1b:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a1e:	52                   	push   %edx
f0100a1f:	56                   	push   %esi
f0100a20:	ff 14 85 68 66 10 f0 	call   *-0xfef9998(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a27:	83 c4 10             	add    $0x10,%esp
f0100a2a:	85 c0                	test   %eax,%eax
f0100a2c:	0f 89 17 ff ff ff    	jns    f0100949 <monitor+0x36>
f0100a32:	eb 20                	jmp    f0100a54 <monitor+0x141>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a34:	83 c3 01             	add    $0x1,%ebx
f0100a37:	83 fb 03             	cmp    $0x3,%ebx
f0100a3a:	75 ba                	jne    f01009f6 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a3c:	83 ec 08             	sub    $0x8,%esp
f0100a3f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a42:	68 ae 64 10 f0       	push   $0xf01064ae
f0100a47:	e8 d5 2d 00 00       	call   f0103821 <cprintf>
f0100a4c:	83 c4 10             	add    $0x10,%esp
f0100a4f:	e9 f5 fe ff ff       	jmp    f0100949 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a54:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a57:	5b                   	pop    %ebx
f0100a58:	5e                   	pop    %esi
f0100a59:	5f                   	pop    %edi
f0100a5a:	5d                   	pop    %ebp
f0100a5b:	c3                   	ret    

f0100a5c <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a5c:	89 d1                	mov    %edx,%ecx
f0100a5e:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a61:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a64:	a8 01                	test   $0x1,%al
f0100a66:	74 52                	je     f0100aba <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a68:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a6d:	89 c1                	mov    %eax,%ecx
f0100a6f:	c1 e9 0c             	shr    $0xc,%ecx
f0100a72:	3b 0d c8 9e 20 f0    	cmp    0xf0209ec8,%ecx
f0100a78:	72 1b                	jb     f0100a95 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a7a:	55                   	push   %ebp
f0100a7b:	89 e5                	mov    %esp,%ebp
f0100a7d:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a80:	50                   	push   %eax
f0100a81:	68 e4 60 10 f0       	push   $0xf01060e4
f0100a86:	68 10 04 00 00       	push   $0x410
f0100a8b:	68 75 70 10 f0       	push   $0xf0107075
f0100a90:	e8 ab f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a95:	c1 ea 0c             	shr    $0xc,%edx
f0100a98:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a9e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100aa5:	89 c2                	mov    %eax,%edx
f0100aa7:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aaa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aaf:	85 d2                	test   %edx,%edx
f0100ab1:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ab6:	0f 44 c2             	cmove  %edx,%eax
f0100ab9:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100aba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100abf:	c3                   	ret    

f0100ac0 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ac0:	83 3d 5c 92 20 f0 00 	cmpl   $0x0,0xf020925c
f0100ac7:	75 11                	jne    f0100ada <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100ac9:	ba 07 c0 24 f0       	mov    $0xf024c007,%edx
f0100ace:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ad4:	89 15 5c 92 20 f0    	mov    %edx,0xf020925c
	}
	
	if (n==0){
f0100ada:	85 c0                	test   %eax,%eax
f0100adc:	75 06                	jne    f0100ae4 <boot_alloc+0x24>
	return nextfree;
f0100ade:	a1 5c 92 20 f0       	mov    0xf020925c,%eax
f0100ae3:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100ae4:	8b 0d 5c 92 20 f0    	mov    0xf020925c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100aea:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100aef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100af4:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100af7:	89 15 5c 92 20 f0    	mov    %edx,0xf020925c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100afd:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100b03:	77 18                	ja     f0100b1d <boot_alloc+0x5d>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b05:	55                   	push   %ebp
f0100b06:	89 e5                	mov    %esp,%ebp
f0100b08:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b0b:	52                   	push   %edx
f0100b0c:	68 08 61 10 f0       	push   $0xf0106108
f0100b11:	6a 71                	push   $0x71
f0100b13:	68 75 70 10 f0       	push   $0xf0107075
f0100b18:	e8 23 f5 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100b1d:	a1 c8 9e 20 f0       	mov    0xf0209ec8,%eax
f0100b22:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100b25:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
	}
	return result;
f0100b2b:	39 c2                	cmp    %eax,%edx
f0100b2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b32:	0f 46 c1             	cmovbe %ecx,%eax
}
f0100b35:	c3                   	ret    

f0100b36 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b36:	55                   	push   %ebp
f0100b37:	89 e5                	mov    %esp,%ebp
f0100b39:	57                   	push   %edi
f0100b3a:	56                   	push   %esi
f0100b3b:	53                   	push   %ebx
f0100b3c:	83 ec 3c             	sub    $0x3c,%esp
f0100b3f:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b42:	84 c0                	test   %al,%al
f0100b44:	0f 85 af 02 00 00    	jne    f0100df9 <check_page_free_list+0x2c3>
f0100b4a:	e9 bc 02 00 00       	jmp    f0100e0b <check_page_free_list+0x2d5>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b4f:	83 ec 04             	sub    $0x4,%esp
f0100b52:	68 84 66 10 f0       	push   $0xf0106684
f0100b57:	68 44 03 00 00       	push   $0x344
f0100b5c:	68 75 70 10 f0       	push   $0xf0107075
f0100b61:	e8 da f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b66:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b69:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b6c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b6f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b72:	89 c2                	mov    %eax,%edx
f0100b74:	2b 15 d0 9e 20 f0    	sub    0xf0209ed0,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b7a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b80:	0f 95 c2             	setne  %dl
f0100b83:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b86:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b8a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b8c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b90:	8b 00                	mov    (%eax),%eax
f0100b92:	85 c0                	test   %eax,%eax
f0100b94:	75 dc                	jne    f0100b72 <check_page_free_list+0x3c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b96:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b99:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ba2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ba5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ba7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100baa:	a3 64 92 20 f0       	mov    %eax,0xf0209264
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100baf:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bb4:	8b 1d 64 92 20 f0    	mov    0xf0209264,%ebx
f0100bba:	eb 53                	jmp    f0100c0f <check_page_free_list+0xd9>
f0100bbc:	89 d8                	mov    %ebx,%eax
f0100bbe:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0100bc4:	c1 f8 03             	sar    $0x3,%eax
f0100bc7:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bca:	89 c2                	mov    %eax,%edx
f0100bcc:	c1 ea 16             	shr    $0x16,%edx
f0100bcf:	39 f2                	cmp    %esi,%edx
f0100bd1:	73 3a                	jae    f0100c0d <check_page_free_list+0xd7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bd3:	89 c2                	mov    %eax,%edx
f0100bd5:	c1 ea 0c             	shr    $0xc,%edx
f0100bd8:	3b 15 c8 9e 20 f0    	cmp    0xf0209ec8,%edx
f0100bde:	72 12                	jb     f0100bf2 <check_page_free_list+0xbc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100be0:	50                   	push   %eax
f0100be1:	68 e4 60 10 f0       	push   $0xf01060e4
f0100be6:	6a 58                	push   $0x58
f0100be8:	68 81 70 10 f0       	push   $0xf0107081
f0100bed:	e8 4e f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bf2:	83 ec 04             	sub    $0x4,%esp
f0100bf5:	68 80 00 00 00       	push   $0x80
f0100bfa:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100bff:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c04:	50                   	push   %eax
f0100c05:	e8 c0 47 00 00       	call   f01053ca <memset>
f0100c0a:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c0d:	8b 1b                	mov    (%ebx),%ebx
f0100c0f:	85 db                	test   %ebx,%ebx
f0100c11:	75 a9                	jne    f0100bbc <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c13:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c18:	e8 a3 fe ff ff       	call   f0100ac0 <boot_alloc>
f0100c1d:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c20:	8b 15 64 92 20 f0    	mov    0xf0209264,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c26:	8b 0d d0 9e 20 f0    	mov    0xf0209ed0,%ecx
		assert(pp < pages + npages);
f0100c2c:	a1 c8 9e 20 f0       	mov    0xf0209ec8,%eax
f0100c31:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c34:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c37:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c3a:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c3f:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0100c42:	89 f0                	mov    %esi,%eax
f0100c44:	89 ce                	mov    %ecx,%esi
f0100c46:	89 c1                	mov    %eax,%ecx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c48:	e9 55 01 00 00       	jmp    f0100da2 <check_page_free_list+0x26c>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c4d:	39 f2                	cmp    %esi,%edx
f0100c4f:	73 19                	jae    f0100c6a <check_page_free_list+0x134>
f0100c51:	68 8f 70 10 f0       	push   $0xf010708f
f0100c56:	68 9b 70 10 f0       	push   $0xf010709b
f0100c5b:	68 5e 03 00 00       	push   $0x35e
f0100c60:	68 75 70 10 f0       	push   $0xf0107075
f0100c65:	e8 d6 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c6a:	39 ca                	cmp    %ecx,%edx
f0100c6c:	72 19                	jb     f0100c87 <check_page_free_list+0x151>
f0100c6e:	68 b0 70 10 f0       	push   $0xf01070b0
f0100c73:	68 9b 70 10 f0       	push   $0xf010709b
f0100c78:	68 5f 03 00 00       	push   $0x35f
f0100c7d:	68 75 70 10 f0       	push   $0xf0107075
f0100c82:	e8 b9 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c87:	89 d0                	mov    %edx,%eax
f0100c89:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c8c:	a8 07                	test   $0x7,%al
f0100c8e:	74 19                	je     f0100ca9 <check_page_free_list+0x173>
f0100c90:	68 a8 66 10 f0       	push   $0xf01066a8
f0100c95:	68 9b 70 10 f0       	push   $0xf010709b
f0100c9a:	68 60 03 00 00       	push   $0x360
f0100c9f:	68 75 70 10 f0       	push   $0xf0107075
f0100ca4:	e8 97 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ca9:	c1 f8 03             	sar    $0x3,%eax
f0100cac:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100caf:	85 c0                	test   %eax,%eax
f0100cb1:	75 19                	jne    f0100ccc <check_page_free_list+0x196>
f0100cb3:	68 c4 70 10 f0       	push   $0xf01070c4
f0100cb8:	68 9b 70 10 f0       	push   $0xf010709b
f0100cbd:	68 63 03 00 00       	push   $0x363
f0100cc2:	68 75 70 10 f0       	push   $0xf0107075
f0100cc7:	e8 74 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ccc:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cd1:	75 19                	jne    f0100cec <check_page_free_list+0x1b6>
f0100cd3:	68 d5 70 10 f0       	push   $0xf01070d5
f0100cd8:	68 9b 70 10 f0       	push   $0xf010709b
f0100cdd:	68 64 03 00 00       	push   $0x364
f0100ce2:	68 75 70 10 f0       	push   $0xf0107075
f0100ce7:	e8 54 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cec:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cf1:	75 19                	jne    f0100d0c <check_page_free_list+0x1d6>
f0100cf3:	68 dc 66 10 f0       	push   $0xf01066dc
f0100cf8:	68 9b 70 10 f0       	push   $0xf010709b
f0100cfd:	68 65 03 00 00       	push   $0x365
f0100d02:	68 75 70 10 f0       	push   $0xf0107075
f0100d07:	e8 34 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d0c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d11:	75 19                	jne    f0100d2c <check_page_free_list+0x1f6>
f0100d13:	68 ee 70 10 f0       	push   $0xf01070ee
f0100d18:	68 9b 70 10 f0       	push   $0xf010709b
f0100d1d:	68 66 03 00 00       	push   $0x366
f0100d22:	68 75 70 10 f0       	push   $0xf0107075
f0100d27:	e8 14 f3 ff ff       	call   f0100040 <_panic>
f0100d2c:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d2f:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d34:	0f 86 e8 00 00 00    	jbe    f0100e22 <check_page_free_list+0x2ec>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d3a:	89 c3                	mov    %eax,%ebx
f0100d3c:	c1 eb 0c             	shr    $0xc,%ebx
f0100d3f:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d42:	77 12                	ja     f0100d56 <check_page_free_list+0x220>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d44:	50                   	push   %eax
f0100d45:	68 e4 60 10 f0       	push   $0xf01060e4
f0100d4a:	6a 58                	push   $0x58
f0100d4c:	68 81 70 10 f0       	push   $0xf0107081
f0100d51:	e8 ea f2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100d56:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0100d5c:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d5f:	0f 86 cd 00 00 00    	jbe    f0100e32 <check_page_free_list+0x2fc>
f0100d65:	68 00 67 10 f0       	push   $0xf0106700
f0100d6a:	68 9b 70 10 f0       	push   $0xf010709b
f0100d6f:	68 67 03 00 00       	push   $0x367
f0100d74:	68 75 70 10 f0       	push   $0xf0107075
f0100d79:	e8 c2 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d7e:	68 08 71 10 f0       	push   $0xf0107108
f0100d83:	68 9b 70 10 f0       	push   $0xf010709b
f0100d88:	68 69 03 00 00       	push   $0x369
f0100d8d:	68 75 70 10 f0       	push   $0xf0107075
f0100d92:	e8 a9 f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d97:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d9b:	eb 03                	jmp    f0100da0 <check_page_free_list+0x26a>
		else
			++nfree_extmem;
f0100d9d:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100da0:	8b 12                	mov    (%edx),%edx
f0100da2:	85 d2                	test   %edx,%edx
f0100da4:	0f 85 a3 fe ff ff    	jne    f0100c4d <check_page_free_list+0x117>
f0100daa:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100dad:	85 db                	test   %ebx,%ebx
f0100daf:	7f 19                	jg     f0100dca <check_page_free_list+0x294>
f0100db1:	68 25 71 10 f0       	push   $0xf0107125
f0100db6:	68 9b 70 10 f0       	push   $0xf010709b
f0100dbb:	68 71 03 00 00       	push   $0x371
f0100dc0:	68 75 70 10 f0       	push   $0xf0107075
f0100dc5:	e8 76 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100dca:	85 ff                	test   %edi,%edi
f0100dcc:	7f 19                	jg     f0100de7 <check_page_free_list+0x2b1>
f0100dce:	68 37 71 10 f0       	push   $0xf0107137
f0100dd3:	68 9b 70 10 f0       	push   $0xf010709b
f0100dd8:	68 72 03 00 00       	push   $0x372
f0100ddd:	68 75 70 10 f0       	push   $0xf0107075
f0100de2:	e8 59 f2 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100de7:	83 ec 08             	sub    $0x8,%esp
f0100dea:	ff 75 c0             	pushl  -0x40(%ebp)
f0100ded:	68 48 67 10 f0       	push   $0xf0106748
f0100df2:	e8 2a 2a 00 00       	call   f0103821 <cprintf>
f0100df7:	eb 49                	jmp    f0100e42 <check_page_free_list+0x30c>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100df9:	a1 64 92 20 f0       	mov    0xf0209264,%eax
f0100dfe:	85 c0                	test   %eax,%eax
f0100e00:	0f 85 60 fd ff ff    	jne    f0100b66 <check_page_free_list+0x30>
f0100e06:	e9 44 fd ff ff       	jmp    f0100b4f <check_page_free_list+0x19>
f0100e0b:	83 3d 64 92 20 f0 00 	cmpl   $0x0,0xf0209264
f0100e12:	0f 84 37 fd ff ff    	je     f0100b4f <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e18:	be 00 04 00 00       	mov    $0x400,%esi
f0100e1d:	e9 92 fd ff ff       	jmp    f0100bb4 <check_page_free_list+0x7e>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e22:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e27:	0f 85 6a ff ff ff    	jne    f0100d97 <check_page_free_list+0x261>
f0100e2d:	e9 4c ff ff ff       	jmp    f0100d7e <check_page_free_list+0x248>
f0100e32:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e37:	0f 85 60 ff ff ff    	jne    f0100d9d <check_page_free_list+0x267>
f0100e3d:	e9 3c ff ff ff       	jmp    f0100d7e <check_page_free_list+0x248>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100e42:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e45:	5b                   	pop    %ebx
f0100e46:	5e                   	pop    %esi
f0100e47:	5f                   	pop    %edi
f0100e48:	5d                   	pop    %ebp
f0100e49:	c3                   	ret    

f0100e4a <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e4a:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e4f:	eb 18                	jmp    f0100e69 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100e51:	8b 15 d0 9e 20 f0    	mov    0xf0209ed0,%edx
f0100e57:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100e5a:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e60:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e66:	83 c0 01             	add    $0x1,%eax
f0100e69:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f0100e6f:	72 e0                	jb     f0100e51 <page_init+0x7>
//


void
page_init(void)
{
f0100e71:	55                   	push   %ebp
f0100e72:	89 e5                	mov    %esp,%ebp
f0100e74:	57                   	push   %edi
f0100e75:	56                   	push   %esi
f0100e76:	53                   	push   %ebx
f0100e77:	83 ec 0c             	sub    $0xc,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0100e7a:	c7 05 64 92 20 f0 00 	movl   $0x0,0xf0209264
f0100e81:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100e84:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0100e89:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0100e8e:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e93:	eb 71                	jmp    f0100f06 <page_init+0xbc>
		if (i == mpentyPg) {
f0100e95:	83 fb 07             	cmp    $0x7,%ebx
f0100e98:	75 14                	jne    f0100eae <page_init+0x64>
			cprintf("Skipped this page %d\n", i);
f0100e9a:	83 ec 08             	sub    $0x8,%esp
f0100e9d:	6a 07                	push   $0x7
f0100e9f:	68 48 71 10 f0       	push   $0xf0107148
f0100ea4:	e8 78 29 00 00       	call   f0103821 <cprintf>
			continue;	
f0100ea9:	83 c4 10             	add    $0x10,%esp
f0100eac:	eb 52                	jmp    f0100f00 <page_init+0xb6>
f0100eae:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0100eb5:	8b 15 d0 9e 20 f0    	mov    0xf0209ed0,%edx
f0100ebb:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100ec2:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0100ec9:	83 3d 64 92 20 f0 00 	cmpl   $0x0,0xf0209264
f0100ed0:	75 10                	jne    f0100ee2 <page_init+0x98>
			page_free_list = &pages[i];
f0100ed2:	89 c2                	mov    %eax,%edx
f0100ed4:	03 15 d0 9e 20 f0    	add    0xf0209ed0,%edx
f0100eda:	89 15 64 92 20 f0    	mov    %edx,0xf0209264
f0100ee0:	eb 16                	jmp    f0100ef8 <page_init+0xae>
		} else {
			prev->pp_link = &pages[i];
f0100ee2:	89 c2                	mov    %eax,%edx
f0100ee4:	03 15 d0 9e 20 f0    	add    0xf0209ed0,%edx
f0100eea:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0100eec:	8b 15 d0 9e 20 f0    	mov    0xf0209ed0,%edx
f0100ef2:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0100ef5:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0100ef8:	03 05 d0 9e 20 f0    	add    0xf0209ed0,%eax
f0100efe:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100f00:	83 c3 01             	add    $0x1,%ebx
f0100f03:	83 c6 08             	add    $0x8,%esi
f0100f06:	3b 1d 68 92 20 f0    	cmp    0xf0209268,%ebx
f0100f0c:	72 87                	jb     f0100e95 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100f0e:	a1 d0 9e 20 f0       	mov    0xf0209ed0,%eax
f0100f13:	8d 44 d8 f8          	lea    -0x8(%eax,%ebx,8),%eax
f0100f17:	a3 58 92 20 f0       	mov    %eax,0xf0209258
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f21:	e8 9a fb ff ff       	call   f0100ac0 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f26:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f2b:	77 15                	ja     f0100f42 <page_init+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f2d:	50                   	push   %eax
f0100f2e:	68 08 61 10 f0       	push   $0xf0106108
f0100f33:	68 75 01 00 00       	push   $0x175
f0100f38:	68 75 70 10 f0       	push   $0xf0107075
f0100f3d:	e8 fe f0 ff ff       	call   f0100040 <_panic>
f0100f42:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100f47:	c1 e8 0c             	shr    $0xc,%eax
f0100f4a:	8b 1d 58 92 20 f0    	mov    0xf0209258,%ebx
f0100f50:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f57:	eb 2c                	jmp    f0100f85 <page_init+0x13b>
		pages[i].pp_ref = 0;
f0100f59:	89 d1                	mov    %edx,%ecx
f0100f5b:	03 0d d0 9e 20 f0    	add    0xf0209ed0,%ecx
f0100f61:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100f67:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100f6d:	89 d1                	mov    %edx,%ecx
f0100f6f:	03 0d d0 9e 20 f0    	add    0xf0209ed0,%ecx
f0100f75:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100f77:	89 d3                	mov    %edx,%ebx
f0100f79:	03 1d d0 9e 20 f0    	add    0xf0209ed0,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f7f:	83 c0 01             	add    $0x1,%eax
f0100f82:	83 c2 08             	add    $0x8,%edx
f0100f85:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f0100f8b:	72 cc                	jb     f0100f59 <page_init+0x10f>
f0100f8d:	89 1d 58 92 20 f0    	mov    %ebx,0xf0209258
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f93:	83 ec 08             	sub    $0x8,%esp
f0100f96:	ff 35 d0 9e 20 f0    	pushl  0xf0209ed0
f0100f9c:	68 70 67 10 f0       	push   $0xf0106770
f0100fa1:	e8 7b 28 00 00       	call   f0103821 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100fa6:	83 c4 08             	add    $0x8,%esp
f0100fa9:	a1 d0 9e 20 f0       	mov    0xf0209ed0,%eax
f0100fae:	8b 15 c8 9e 20 f0    	mov    0xf0209ec8,%edx
f0100fb4:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100fb8:	50                   	push   %eax
f0100fb9:	68 5e 71 10 f0       	push   $0xf010715e
f0100fbe:	e8 5e 28 00 00       	call   f0103821 <cprintf>
f0100fc3:	83 c4 10             	add    $0x10,%esp
}
f0100fc6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc9:	5b                   	pop    %ebx
f0100fca:	5e                   	pop    %esi
f0100fcb:	5f                   	pop    %edi
f0100fcc:	5d                   	pop    %ebp
f0100fcd:	c3                   	ret    

f0100fce <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100fce:	55                   	push   %ebp
f0100fcf:	89 e5                	mov    %esp,%ebp
f0100fd1:	53                   	push   %ebx
f0100fd2:	83 ec 04             	sub    $0x4,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100fd5:	8b 1d 64 92 20 f0    	mov    0xf0209264,%ebx
f0100fdb:	85 db                	test   %ebx,%ebx
f0100fdd:	74 5e                	je     f010103d <page_alloc+0x6f>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100fdf:	8b 03                	mov    (%ebx),%eax
f0100fe1:	a3 64 92 20 f0       	mov    %eax,0xf0209264
	allocPage->pp_link = NULL;	//Break the link 
f0100fe6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100fec:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100ff0:	74 45                	je     f0101037 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ff2:	89 d8                	mov    %ebx,%eax
f0100ff4:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0100ffa:	c1 f8 03             	sar    $0x3,%eax
f0100ffd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101000:	89 c2                	mov    %eax,%edx
f0101002:	c1 ea 0c             	shr    $0xc,%edx
f0101005:	3b 15 c8 9e 20 f0    	cmp    0xf0209ec8,%edx
f010100b:	72 12                	jb     f010101f <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010100d:	50                   	push   %eax
f010100e:	68 e4 60 10 f0       	push   $0xf01060e4
f0101013:	6a 58                	push   $0x58
f0101015:	68 81 70 10 f0       	push   $0xf0107081
f010101a:	e8 21 f0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f010101f:	83 ec 04             	sub    $0x4,%esp
f0101022:	68 00 10 00 00       	push   $0x1000
f0101027:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101029:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010102e:	50                   	push   %eax
f010102f:	e8 96 43 00 00       	call   f01053ca <memset>
f0101034:	83 c4 10             	add    $0x10,%esp
	}
	
	allocPage->pp_ref = 0;
f0101037:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
}
f010103d:	89 d8                	mov    %ebx,%eax
f010103f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101042:	c9                   	leave  
f0101043:	c3                   	ret    

f0101044 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101044:	55                   	push   %ebp
f0101045:	89 e5                	mov    %esp,%ebp
f0101047:	83 ec 08             	sub    $0x8,%esp
f010104a:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f010104d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101052:	74 17                	je     f010106b <page_free+0x27>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0101054:	83 ec 04             	sub    $0x4,%esp
f0101057:	68 9c 67 10 f0       	push   $0xf010679c
f010105c:	68 ad 01 00 00       	push   $0x1ad
f0101061:	68 75 70 10 f0       	push   $0xf0107075
f0101066:	e8 d5 ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f010106b:	85 c0                	test   %eax,%eax
f010106d:	75 17                	jne    f0101086 <page_free+0x42>
	{
	panic("Page cannot be returned to free list as it is Null");
f010106f:	83 ec 04             	sub    $0x4,%esp
f0101072:	68 dc 67 10 f0       	push   $0xf01067dc
f0101077:	68 b4 01 00 00       	push   $0x1b4
f010107c:	68 75 70 10 f0       	push   $0xf0107075
f0101081:	e8 ba ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0101086:	8b 15 64 92 20 f0    	mov    0xf0209264,%edx
f010108c:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010108e:	a3 64 92 20 f0       	mov    %eax,0xf0209264
	}


}
f0101093:	c9                   	leave  
f0101094:	c3                   	ret    

f0101095 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101095:	55                   	push   %ebp
f0101096:	89 e5                	mov    %esp,%ebp
f0101098:	83 ec 08             	sub    $0x8,%esp
f010109b:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010109e:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01010a2:	83 e8 01             	sub    $0x1,%eax
f01010a5:	66 89 42 04          	mov    %ax,0x4(%edx)
f01010a9:	66 85 c0             	test   %ax,%ax
f01010ac:	75 0c                	jne    f01010ba <page_decref+0x25>
		page_free(pp);
f01010ae:	83 ec 0c             	sub    $0xc,%esp
f01010b1:	52                   	push   %edx
f01010b2:	e8 8d ff ff ff       	call   f0101044 <page_free>
f01010b7:	83 c4 10             	add    $0x10,%esp
}
f01010ba:	c9                   	leave  
f01010bb:	c3                   	ret    

f01010bc <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01010bc:	55                   	push   %ebp
f01010bd:	89 e5                	mov    %esp,%ebp
f01010bf:	57                   	push   %edi
f01010c0:	56                   	push   %esi
f01010c1:	53                   	push   %ebx
f01010c2:	83 ec 0c             	sub    $0xc,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f01010c5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010c8:	c1 ee 16             	shr    $0x16,%esi
f01010cb:	c1 e6 02             	shl    $0x2,%esi
f01010ce:	03 75 08             	add    0x8(%ebp),%esi

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f01010d1:	8b 1e                	mov    (%esi),%ebx
f01010d3:	f6 c3 01             	test   $0x1,%bl
f01010d6:	74 30                	je     f0101108 <pgdir_walk+0x4c>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f01010d8:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010de:	89 d8                	mov    %ebx,%eax
f01010e0:	c1 e8 0c             	shr    $0xc,%eax
f01010e3:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f01010e9:	72 15                	jb     f0101100 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010eb:	53                   	push   %ebx
f01010ec:	68 e4 60 10 f0       	push   $0xf01060e4
f01010f1:	68 f5 01 00 00       	push   $0x1f5
f01010f6:	68 75 70 10 f0       	push   $0xf0107075
f01010fb:	e8 40 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101100:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f0101106:	eb 7c                	jmp    f0101184 <pgdir_walk+0xc8>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f0101108:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010110c:	0f 84 81 00 00 00    	je     f0101193 <pgdir_walk+0xd7>
f0101112:	83 ec 0c             	sub    $0xc,%esp
f0101115:	68 00 10 00 00       	push   $0x1000
f010111a:	e8 af fe ff ff       	call   f0100fce <page_alloc>
f010111f:	89 c7                	mov    %eax,%edi
f0101121:	83 c4 10             	add    $0x10,%esp
f0101124:	85 c0                	test   %eax,%eax
f0101126:	74 72                	je     f010119a <pgdir_walk+0xde>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f0101128:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010112d:	89 c3                	mov    %eax,%ebx
f010112f:	2b 1d d0 9e 20 f0    	sub    0xf0209ed0,%ebx
f0101135:	c1 fb 03             	sar    $0x3,%ebx
f0101138:	c1 e3 0c             	shl    $0xc,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010113b:	89 d8                	mov    %ebx,%eax
f010113d:	c1 e8 0c             	shr    $0xc,%eax
f0101140:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f0101146:	72 12                	jb     f010115a <pgdir_walk+0x9e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101148:	53                   	push   %ebx
f0101149:	68 e4 60 10 f0       	push   $0xf01060e4
f010114e:	6a 58                	push   $0x58
f0101150:	68 81 70 10 f0       	push   $0xf0107081
f0101155:	e8 e6 ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010115a:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f0101160:	83 ec 04             	sub    $0x4,%esp
f0101163:	68 00 10 00 00       	push   $0x1000
f0101168:	6a 00                	push   $0x0
f010116a:	53                   	push   %ebx
f010116b:	e8 5a 42 00 00       	call   f01053ca <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101170:	2b 3d d0 9e 20 f0    	sub    0xf0209ed0,%edi
f0101176:	c1 ff 03             	sar    $0x3,%edi
f0101179:	c1 e7 0c             	shl    $0xc,%edi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f010117c:	83 cf 07             	or     $0x7,%edi
f010117f:	89 3e                	mov    %edi,(%esi)
f0101181:	83 c4 10             	add    $0x10,%esp
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f0101184:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101187:	c1 e8 0a             	shr    $0xa,%eax
f010118a:	25 fc 0f 00 00       	and    $0xffc,%eax
f010118f:	01 d8                	add    %ebx,%eax
f0101191:	eb 0c                	jmp    f010119f <pgdir_walk+0xe3>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0101193:	b8 00 00 00 00       	mov    $0x0,%eax
f0101198:	eb 05                	jmp    f010119f <pgdir_walk+0xe3>
f010119a:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f010119f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a2:	5b                   	pop    %ebx
f01011a3:	5e                   	pop    %esi
f01011a4:	5f                   	pop    %edi
f01011a5:	5d                   	pop    %ebp
f01011a6:	c3                   	ret    

f01011a7 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01011a7:	55                   	push   %ebp
f01011a8:	89 e5                	mov    %esp,%ebp
f01011aa:	57                   	push   %edi
f01011ab:	56                   	push   %esi
f01011ac:	53                   	push   %ebx
f01011ad:	83 ec 1c             	sub    $0x1c,%esp
f01011b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011b3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f01011b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01011bc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f01011c1:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f01011c7:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011cd:	89 d3                	mov    %edx,%ebx
f01011cf:	29 d0                	sub    %edx,%eax
f01011d1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011d7:	83 c8 01             	or     $0x1,%eax
f01011da:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01011dd:	eb 3d                	jmp    f010121c <boot_map_region+0x75>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f01011df:	83 ec 04             	sub    $0x4,%esp
f01011e2:	6a 01                	push   $0x1
f01011e4:	53                   	push   %ebx
f01011e5:	ff 75 e0             	pushl  -0x20(%ebp)
f01011e8:	e8 cf fe ff ff       	call   f01010bc <pgdir_walk>
f01011ed:	83 c4 10             	add    $0x10,%esp
f01011f0:	85 c0                	test   %eax,%eax
f01011f2:	75 17                	jne    f010120b <boot_map_region+0x64>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f01011f4:	83 ec 04             	sub    $0x4,%esp
f01011f7:	68 10 68 10 f0       	push   $0xf0106810
f01011fc:	68 2b 02 00 00       	push   $0x22b
f0101201:	68 75 70 10 f0       	push   $0xf0107075
f0101206:	e8 35 ee ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f010120b:	0b 75 dc             	or     -0x24(%ebp),%esi
f010120e:	89 30                	mov    %esi,(%eax)
		vaBegin += PGSIZE;
f0101210:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f0101216:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f010121c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010121f:	8d 34 18             	lea    (%eax,%ebx,1),%esi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f0101222:	85 ff                	test   %edi,%edi
f0101224:	75 b9                	jne    f01011df <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f0101226:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101229:	5b                   	pop    %ebx
f010122a:	5e                   	pop    %esi
f010122b:	5f                   	pop    %edi
f010122c:	5d                   	pop    %ebp
f010122d:	c3                   	ret    

f010122e <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010122e:	55                   	push   %ebp
f010122f:	89 e5                	mov    %esp,%ebp
f0101231:	53                   	push   %ebx
f0101232:	83 ec 08             	sub    $0x8,%esp
f0101235:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0101238:	6a 00                	push   $0x0
f010123a:	ff 75 0c             	pushl  0xc(%ebp)
f010123d:	ff 75 08             	pushl  0x8(%ebp)
f0101240:	e8 77 fe ff ff       	call   f01010bc <pgdir_walk>
f0101245:	89 c1                	mov    %eax,%ecx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f0101247:	83 c4 10             	add    $0x10,%esp
f010124a:	85 c0                	test   %eax,%eax
f010124c:	74 1a                	je     f0101268 <page_lookup+0x3a>
f010124e:	8b 10                	mov    (%eax),%edx
f0101250:	f6 c2 01             	test   $0x1,%dl
f0101253:	74 1a                	je     f010126f <page_lookup+0x41>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f0101255:	c1 ea 0c             	shr    $0xc,%edx
f0101258:	a1 d0 9e 20 f0       	mov    0xf0209ed0,%eax
f010125d:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		if (pte_store) {
f0101260:	85 db                	test   %ebx,%ebx
f0101262:	74 10                	je     f0101274 <page_lookup+0x46>
			*pte_store = pgTbEty;
f0101264:	89 0b                	mov    %ecx,(%ebx)
f0101266:	eb 0c                	jmp    f0101274 <page_lookup+0x46>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f0101268:	b8 00 00 00 00       	mov    $0x0,%eax
f010126d:	eb 05                	jmp    f0101274 <page_lookup+0x46>
f010126f:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f0101274:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101277:	c9                   	leave  
f0101278:	c3                   	ret    

f0101279 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101279:	55                   	push   %ebp
f010127a:	89 e5                	mov    %esp,%ebp
f010127c:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f010127f:	e8 6b 47 00 00       	call   f01059ef <cpunum>
f0101284:	6b c0 74             	imul   $0x74,%eax,%eax
f0101287:	83 b8 48 a0 20 f0 00 	cmpl   $0x0,-0xfdf5fb8(%eax)
f010128e:	74 16                	je     f01012a6 <tlb_invalidate+0x2d>
f0101290:	e8 5a 47 00 00       	call   f01059ef <cpunum>
f0101295:	6b c0 74             	imul   $0x74,%eax,%eax
f0101298:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f010129e:	8b 55 08             	mov    0x8(%ebp),%edx
f01012a1:	39 50 60             	cmp    %edx,0x60(%eax)
f01012a4:	75 06                	jne    f01012ac <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012a6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012a9:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01012ac:	c9                   	leave  
f01012ad:	c3                   	ret    

f01012ae <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f01012ae:	55                   	push   %ebp
f01012af:	89 e5                	mov    %esp,%ebp
f01012b1:	56                   	push   %esi
f01012b2:	53                   	push   %ebx
f01012b3:	83 ec 14             	sub    $0x14,%esp
f01012b6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01012b9:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f01012bc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012bf:	50                   	push   %eax
f01012c0:	56                   	push   %esi
f01012c1:	53                   	push   %ebx
f01012c2:	e8 67 ff ff ff       	call   f010122e <page_lookup>
f01012c7:	83 c4 10             	add    $0x10,%esp
f01012ca:	85 c0                	test   %eax,%eax
f01012cc:	74 1f                	je     f01012ed <page_remove+0x3f>
		return;
	}
	page_decref(remPage);
f01012ce:	83 ec 0c             	sub    $0xc,%esp
f01012d1:	50                   	push   %eax
f01012d2:	e8 be fd ff ff       	call   f0101095 <page_decref>
	*pte = 0;
f01012d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012da:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01012e0:	83 c4 08             	add    $0x8,%esp
f01012e3:	56                   	push   %esi
f01012e4:	53                   	push   %ebx
f01012e5:	e8 8f ff ff ff       	call   f0101279 <tlb_invalidate>
f01012ea:	83 c4 10             	add    $0x10,%esp
}
f01012ed:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012f0:	5b                   	pop    %ebx
f01012f1:	5e                   	pop    %esi
f01012f2:	5d                   	pop    %ebp
f01012f3:	c3                   	ret    

f01012f4 <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01012f4:	55                   	push   %ebp
f01012f5:	89 e5                	mov    %esp,%ebp
f01012f7:	57                   	push   %edi
f01012f8:	56                   	push   %esi
f01012f9:	53                   	push   %ebx
f01012fa:	83 ec 10             	sub    $0x10,%esp
f01012fd:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101300:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f0101303:	6a 01                	push   $0x1
f0101305:	57                   	push   %edi
f0101306:	ff 75 08             	pushl  0x8(%ebp)
f0101309:	e8 ae fd ff ff       	call   f01010bc <pgdir_walk>
f010130e:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f0101310:	83 c4 10             	add    $0x10,%esp
f0101313:	85 c0                	test   %eax,%eax
f0101315:	0f 84 85 00 00 00    	je     f01013a0 <page_insert+0xac>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f010131b:	8b 00                	mov    (%eax),%eax
f010131d:	a8 01                	test   $0x1,%al
f010131f:	74 5b                	je     f010137c <page_insert+0x88>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f0101321:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101326:	89 f2                	mov    %esi,%edx
f0101328:	2b 15 d0 9e 20 f0    	sub    0xf0209ed0,%edx
f010132e:	c1 fa 03             	sar    $0x3,%edx
f0101331:	c1 e2 0c             	shl    $0xc,%edx
f0101334:	39 d0                	cmp    %edx,%eax
f0101336:	75 11                	jne    f0101349 <page_insert+0x55>
f0101338:	8b 55 14             	mov    0x14(%ebp),%edx
f010133b:	83 ca 01             	or     $0x1,%edx
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f010133e:	09 d0                	or     %edx,%eax
f0101340:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101342:	b8 00 00 00 00       	mov    $0x0,%eax
f0101347:	eb 5c                	jmp    f01013a5 <page_insert+0xb1>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f0101349:	83 ec 08             	sub    $0x8,%esp
f010134c:	57                   	push   %edi
f010134d:	ff 75 08             	pushl  0x8(%ebp)
f0101350:	e8 59 ff ff ff       	call   f01012ae <page_remove>
f0101355:	8b 55 14             	mov    0x14(%ebp),%edx
f0101358:	83 ca 01             	or     $0x1,%edx
f010135b:	89 f0                	mov    %esi,%eax
f010135d:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0101363:	c1 f8 03             	sar    $0x3,%eax
f0101366:	c1 e0 0c             	shl    $0xc,%eax
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f0101369:	09 d0                	or     %edx,%eax
f010136b:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f010136d:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f0101372:	83 c4 10             	add    $0x10,%esp
		}
		return 0;
f0101375:	b8 00 00 00 00       	mov    $0x0,%eax
f010137a:	eb 29                	jmp    f01013a5 <page_insert+0xb1>
f010137c:	8b 55 14             	mov    0x14(%ebp),%edx
f010137f:	83 ca 01             	or     $0x1,%edx
f0101382:	89 f0                	mov    %esi,%eax
f0101384:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f010138a:	c1 f8 03             	sar    $0x3,%eax
f010138d:	c1 e0 0c             	shl    $0xc,%eax
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f0101390:	09 d0                	or     %edx,%eax
f0101392:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f0101394:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f0101399:	b8 00 00 00 00       	mov    $0x0,%eax
f010139e:	eb 05                	jmp    f01013a5 <page_insert+0xb1>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f01013a0:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f01013a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013a8:	5b                   	pop    %ebx
f01013a9:	5e                   	pop    %esi
f01013aa:	5f                   	pop    %edi
f01013ab:	5d                   	pop    %ebp
f01013ac:	c3                   	ret    

f01013ad <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01013ad:	55                   	push   %ebp
f01013ae:	89 e5                	mov    %esp,%ebp
f01013b0:	56                   	push   %esi
f01013b1:	53                   	push   %ebx
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f01013b2:	8b 35 00 03 12 f0    	mov    0xf0120300,%esi
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f01013b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013bb:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01013c1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f01013c7:	83 ec 08             	sub    $0x8,%esp
f01013ca:	6a 1b                	push   $0x1b
f01013cc:	ff 75 08             	pushl  0x8(%ebp)
f01013cf:	89 d9                	mov    %ebx,%ecx
f01013d1:	89 f2                	mov    %esi,%edx
f01013d3:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f01013d8:	e8 ca fd ff ff       	call   f01011a7 <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f01013dd:	01 1d 00 03 12 f0    	add    %ebx,0xf0120300
	
	return save; 
	
}
f01013e3:	89 f0                	mov    %esi,%eax
f01013e5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013e8:	5b                   	pop    %ebx
f01013e9:	5e                   	pop    %esi
f01013ea:	5d                   	pop    %ebp
f01013eb:	c3                   	ret    

f01013ec <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01013ec:	55                   	push   %ebp
f01013ed:	89 e5                	mov    %esp,%ebp
f01013ef:	57                   	push   %edi
f01013f0:	56                   	push   %esi
f01013f1:	53                   	push   %ebx
f01013f2:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013f5:	6a 15                	push   $0x15
f01013f7:	e8 c4 22 00 00       	call   f01036c0 <mc146818_read>
f01013fc:	89 c3                	mov    %eax,%ebx
f01013fe:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101405:	e8 b6 22 00 00       	call   f01036c0 <mc146818_read>
f010140a:	c1 e0 08             	shl    $0x8,%eax
f010140d:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010140f:	c1 e0 0a             	shl    $0xa,%eax
f0101412:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101418:	85 c0                	test   %eax,%eax
f010141a:	0f 48 c2             	cmovs  %edx,%eax
f010141d:	c1 f8 0c             	sar    $0xc,%eax
f0101420:	a3 68 92 20 f0       	mov    %eax,0xf0209268
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101425:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010142c:	e8 8f 22 00 00       	call   f01036c0 <mc146818_read>
f0101431:	89 c3                	mov    %eax,%ebx
f0101433:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010143a:	e8 81 22 00 00       	call   f01036c0 <mc146818_read>
f010143f:	c1 e0 08             	shl    $0x8,%eax
f0101442:	09 d8                	or     %ebx,%eax
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101444:	c1 e0 0a             	shl    $0xa,%eax
f0101447:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010144d:	83 c4 10             	add    $0x10,%esp
f0101450:	85 c0                	test   %eax,%eax
f0101452:	0f 48 c2             	cmovs  %edx,%eax
f0101455:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101458:	85 c0                	test   %eax,%eax
f010145a:	74 0e                	je     f010146a <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010145c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101462:	89 15 c8 9e 20 f0    	mov    %edx,0xf0209ec8
f0101468:	eb 0c                	jmp    f0101476 <mem_init+0x8a>
	else
		npages = npages_basemem;
f010146a:	8b 15 68 92 20 f0    	mov    0xf0209268,%edx
f0101470:	89 15 c8 9e 20 f0    	mov    %edx,0xf0209ec8

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101476:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101479:	c1 e8 0a             	shr    $0xa,%eax
f010147c:	50                   	push   %eax
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010147d:	a1 68 92 20 f0       	mov    0xf0209268,%eax
f0101482:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101485:	c1 e8 0a             	shr    $0xa,%eax
f0101488:	50                   	push   %eax
		npages * PGSIZE / 1024,
f0101489:	a1 c8 9e 20 f0       	mov    0xf0209ec8,%eax
f010148e:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101491:	c1 e8 0a             	shr    $0xa,%eax
f0101494:	50                   	push   %eax
f0101495:	68 5c 68 10 f0       	push   $0xf010685c
f010149a:	e8 82 23 00 00       	call   f0103821 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010149f:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014a4:	e8 17 f6 ff ff       	call   f0100ac0 <boot_alloc>
f01014a9:	a3 cc 9e 20 f0       	mov    %eax,0xf0209ecc
	memset(kern_pgdir, 0, PGSIZE);
f01014ae:	83 c4 0c             	add    $0xc,%esp
f01014b1:	68 00 10 00 00       	push   $0x1000
f01014b6:	6a 00                	push   $0x0
f01014b8:	50                   	push   %eax
f01014b9:	e8 0c 3f 00 00       	call   f01053ca <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014be:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01014c3:	83 c4 10             	add    $0x10,%esp
f01014c6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014cb:	77 15                	ja     f01014e2 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014cd:	50                   	push   %eax
f01014ce:	68 08 61 10 f0       	push   $0xf0106108
f01014d3:	68 98 00 00 00       	push   $0x98
f01014d8:	68 75 70 10 f0       	push   $0xf0107075
f01014dd:	e8 5e eb ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01014e2:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014e8:	83 ca 05             	or     $0x5,%edx
f01014eb:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f01014f1:	a1 c8 9e 20 f0       	mov    0xf0209ec8,%eax
f01014f6:	c1 e0 03             	shl    $0x3,%eax
f01014f9:	e8 c2 f5 ff ff       	call   f0100ac0 <boot_alloc>
f01014fe:	a3 d0 9e 20 f0       	mov    %eax,0xf0209ed0
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f0101503:	83 ec 04             	sub    $0x4,%esp
f0101506:	8b 0d c8 9e 20 f0    	mov    0xf0209ec8,%ecx
f010150c:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101513:	52                   	push   %edx
f0101514:	6a 00                	push   $0x0
f0101516:	50                   	push   %eax
f0101517:	e8 ae 3e 00 00       	call   f01053ca <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f010151c:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101521:	e8 9a f5 ff ff       	call   f0100ac0 <boot_alloc>
f0101526:	a3 6c 92 20 f0       	mov    %eax,0xf020926c
	memset(envs,0,sizeof(struct Env)*NENV);
f010152b:	83 c4 0c             	add    $0xc,%esp
f010152e:	68 00 f0 01 00       	push   $0x1f000
f0101533:	6a 00                	push   $0x0
f0101535:	50                   	push   %eax
f0101536:	e8 8f 3e 00 00       	call   f01053ca <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010153b:	e8 0a f9 ff ff       	call   f0100e4a <page_init>

	check_page_free_list(1);
f0101540:	b8 01 00 00 00       	mov    $0x1,%eax
f0101545:	e8 ec f5 ff ff       	call   f0100b36 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010154a:	83 c4 10             	add    $0x10,%esp
f010154d:	83 3d d0 9e 20 f0 00 	cmpl   $0x0,0xf0209ed0
f0101554:	75 17                	jne    f010156d <mem_init+0x181>
		panic("'pages' is a null pointer!");
f0101556:	83 ec 04             	sub    $0x4,%esp
f0101559:	68 75 71 10 f0       	push   $0xf0107175
f010155e:	68 84 03 00 00       	push   $0x384
f0101563:	68 75 70 10 f0       	push   $0xf0107075
f0101568:	e8 d3 ea ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010156d:	a1 64 92 20 f0       	mov    0xf0209264,%eax
f0101572:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101577:	eb 05                	jmp    f010157e <mem_init+0x192>
		++nfree;
f0101579:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010157c:	8b 00                	mov    (%eax),%eax
f010157e:	85 c0                	test   %eax,%eax
f0101580:	75 f7                	jne    f0101579 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101582:	83 ec 0c             	sub    $0xc,%esp
f0101585:	6a 00                	push   $0x0
f0101587:	e8 42 fa ff ff       	call   f0100fce <page_alloc>
f010158c:	89 c7                	mov    %eax,%edi
f010158e:	83 c4 10             	add    $0x10,%esp
f0101591:	85 c0                	test   %eax,%eax
f0101593:	75 19                	jne    f01015ae <mem_init+0x1c2>
f0101595:	68 90 71 10 f0       	push   $0xf0107190
f010159a:	68 9b 70 10 f0       	push   $0xf010709b
f010159f:	68 8c 03 00 00       	push   $0x38c
f01015a4:	68 75 70 10 f0       	push   $0xf0107075
f01015a9:	e8 92 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015ae:	83 ec 0c             	sub    $0xc,%esp
f01015b1:	6a 00                	push   $0x0
f01015b3:	e8 16 fa ff ff       	call   f0100fce <page_alloc>
f01015b8:	89 c6                	mov    %eax,%esi
f01015ba:	83 c4 10             	add    $0x10,%esp
f01015bd:	85 c0                	test   %eax,%eax
f01015bf:	75 19                	jne    f01015da <mem_init+0x1ee>
f01015c1:	68 a6 71 10 f0       	push   $0xf01071a6
f01015c6:	68 9b 70 10 f0       	push   $0xf010709b
f01015cb:	68 8d 03 00 00       	push   $0x38d
f01015d0:	68 75 70 10 f0       	push   $0xf0107075
f01015d5:	e8 66 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015da:	83 ec 0c             	sub    $0xc,%esp
f01015dd:	6a 00                	push   $0x0
f01015df:	e8 ea f9 ff ff       	call   f0100fce <page_alloc>
f01015e4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015e7:	83 c4 10             	add    $0x10,%esp
f01015ea:	85 c0                	test   %eax,%eax
f01015ec:	75 19                	jne    f0101607 <mem_init+0x21b>
f01015ee:	68 bc 71 10 f0       	push   $0xf01071bc
f01015f3:	68 9b 70 10 f0       	push   $0xf010709b
f01015f8:	68 8e 03 00 00       	push   $0x38e
f01015fd:	68 75 70 10 f0       	push   $0xf0107075
f0101602:	e8 39 ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101607:	39 f7                	cmp    %esi,%edi
f0101609:	75 19                	jne    f0101624 <mem_init+0x238>
f010160b:	68 d2 71 10 f0       	push   $0xf01071d2
f0101610:	68 9b 70 10 f0       	push   $0xf010709b
f0101615:	68 91 03 00 00       	push   $0x391
f010161a:	68 75 70 10 f0       	push   $0xf0107075
f010161f:	e8 1c ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101624:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101627:	39 c7                	cmp    %eax,%edi
f0101629:	74 04                	je     f010162f <mem_init+0x243>
f010162b:	39 c6                	cmp    %eax,%esi
f010162d:	75 19                	jne    f0101648 <mem_init+0x25c>
f010162f:	68 98 68 10 f0       	push   $0xf0106898
f0101634:	68 9b 70 10 f0       	push   $0xf010709b
f0101639:	68 92 03 00 00       	push   $0x392
f010163e:	68 75 70 10 f0       	push   $0xf0107075
f0101643:	e8 f8 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101648:	8b 0d d0 9e 20 f0    	mov    0xf0209ed0,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010164e:	8b 15 c8 9e 20 f0    	mov    0xf0209ec8,%edx
f0101654:	c1 e2 0c             	shl    $0xc,%edx
f0101657:	89 f8                	mov    %edi,%eax
f0101659:	29 c8                	sub    %ecx,%eax
f010165b:	c1 f8 03             	sar    $0x3,%eax
f010165e:	c1 e0 0c             	shl    $0xc,%eax
f0101661:	39 d0                	cmp    %edx,%eax
f0101663:	72 19                	jb     f010167e <mem_init+0x292>
f0101665:	68 e4 71 10 f0       	push   $0xf01071e4
f010166a:	68 9b 70 10 f0       	push   $0xf010709b
f010166f:	68 93 03 00 00       	push   $0x393
f0101674:	68 75 70 10 f0       	push   $0xf0107075
f0101679:	e8 c2 e9 ff ff       	call   f0100040 <_panic>
f010167e:	89 f0                	mov    %esi,%eax
f0101680:	29 c8                	sub    %ecx,%eax
f0101682:	c1 f8 03             	sar    $0x3,%eax
f0101685:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101688:	39 c2                	cmp    %eax,%edx
f010168a:	77 19                	ja     f01016a5 <mem_init+0x2b9>
f010168c:	68 01 72 10 f0       	push   $0xf0107201
f0101691:	68 9b 70 10 f0       	push   $0xf010709b
f0101696:	68 94 03 00 00       	push   $0x394
f010169b:	68 75 70 10 f0       	push   $0xf0107075
f01016a0:	e8 9b e9 ff ff       	call   f0100040 <_panic>
f01016a5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016a8:	29 c8                	sub    %ecx,%eax
f01016aa:	c1 f8 03             	sar    $0x3,%eax
f01016ad:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01016b0:	39 c2                	cmp    %eax,%edx
f01016b2:	77 19                	ja     f01016cd <mem_init+0x2e1>
f01016b4:	68 1e 72 10 f0       	push   $0xf010721e
f01016b9:	68 9b 70 10 f0       	push   $0xf010709b
f01016be:	68 95 03 00 00       	push   $0x395
f01016c3:	68 75 70 10 f0       	push   $0xf0107075
f01016c8:	e8 73 e9 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016cd:	a1 64 92 20 f0       	mov    0xf0209264,%eax
f01016d2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016d5:	c7 05 64 92 20 f0 00 	movl   $0x0,0xf0209264
f01016dc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016df:	83 ec 0c             	sub    $0xc,%esp
f01016e2:	6a 00                	push   $0x0
f01016e4:	e8 e5 f8 ff ff       	call   f0100fce <page_alloc>
f01016e9:	83 c4 10             	add    $0x10,%esp
f01016ec:	85 c0                	test   %eax,%eax
f01016ee:	74 19                	je     f0101709 <mem_init+0x31d>
f01016f0:	68 3b 72 10 f0       	push   $0xf010723b
f01016f5:	68 9b 70 10 f0       	push   $0xf010709b
f01016fa:	68 9c 03 00 00       	push   $0x39c
f01016ff:	68 75 70 10 f0       	push   $0xf0107075
f0101704:	e8 37 e9 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101709:	83 ec 0c             	sub    $0xc,%esp
f010170c:	57                   	push   %edi
f010170d:	e8 32 f9 ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f0101712:	89 34 24             	mov    %esi,(%esp)
f0101715:	e8 2a f9 ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f010171a:	83 c4 04             	add    $0x4,%esp
f010171d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101720:	e8 1f f9 ff ff       	call   f0101044 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101725:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010172c:	e8 9d f8 ff ff       	call   f0100fce <page_alloc>
f0101731:	89 c6                	mov    %eax,%esi
f0101733:	83 c4 10             	add    $0x10,%esp
f0101736:	85 c0                	test   %eax,%eax
f0101738:	75 19                	jne    f0101753 <mem_init+0x367>
f010173a:	68 90 71 10 f0       	push   $0xf0107190
f010173f:	68 9b 70 10 f0       	push   $0xf010709b
f0101744:	68 a3 03 00 00       	push   $0x3a3
f0101749:	68 75 70 10 f0       	push   $0xf0107075
f010174e:	e8 ed e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101753:	83 ec 0c             	sub    $0xc,%esp
f0101756:	6a 00                	push   $0x0
f0101758:	e8 71 f8 ff ff       	call   f0100fce <page_alloc>
f010175d:	89 c7                	mov    %eax,%edi
f010175f:	83 c4 10             	add    $0x10,%esp
f0101762:	85 c0                	test   %eax,%eax
f0101764:	75 19                	jne    f010177f <mem_init+0x393>
f0101766:	68 a6 71 10 f0       	push   $0xf01071a6
f010176b:	68 9b 70 10 f0       	push   $0xf010709b
f0101770:	68 a4 03 00 00       	push   $0x3a4
f0101775:	68 75 70 10 f0       	push   $0xf0107075
f010177a:	e8 c1 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010177f:	83 ec 0c             	sub    $0xc,%esp
f0101782:	6a 00                	push   $0x0
f0101784:	e8 45 f8 ff ff       	call   f0100fce <page_alloc>
f0101789:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010178c:	83 c4 10             	add    $0x10,%esp
f010178f:	85 c0                	test   %eax,%eax
f0101791:	75 19                	jne    f01017ac <mem_init+0x3c0>
f0101793:	68 bc 71 10 f0       	push   $0xf01071bc
f0101798:	68 9b 70 10 f0       	push   $0xf010709b
f010179d:	68 a5 03 00 00       	push   $0x3a5
f01017a2:	68 75 70 10 f0       	push   $0xf0107075
f01017a7:	e8 94 e8 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017ac:	39 fe                	cmp    %edi,%esi
f01017ae:	75 19                	jne    f01017c9 <mem_init+0x3dd>
f01017b0:	68 d2 71 10 f0       	push   $0xf01071d2
f01017b5:	68 9b 70 10 f0       	push   $0xf010709b
f01017ba:	68 a7 03 00 00       	push   $0x3a7
f01017bf:	68 75 70 10 f0       	push   $0xf0107075
f01017c4:	e8 77 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017c9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017cc:	39 c6                	cmp    %eax,%esi
f01017ce:	74 04                	je     f01017d4 <mem_init+0x3e8>
f01017d0:	39 c7                	cmp    %eax,%edi
f01017d2:	75 19                	jne    f01017ed <mem_init+0x401>
f01017d4:	68 98 68 10 f0       	push   $0xf0106898
f01017d9:	68 9b 70 10 f0       	push   $0xf010709b
f01017de:	68 a8 03 00 00       	push   $0x3a8
f01017e3:	68 75 70 10 f0       	push   $0xf0107075
f01017e8:	e8 53 e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01017ed:	83 ec 0c             	sub    $0xc,%esp
f01017f0:	6a 00                	push   $0x0
f01017f2:	e8 d7 f7 ff ff       	call   f0100fce <page_alloc>
f01017f7:	83 c4 10             	add    $0x10,%esp
f01017fa:	85 c0                	test   %eax,%eax
f01017fc:	74 19                	je     f0101817 <mem_init+0x42b>
f01017fe:	68 3b 72 10 f0       	push   $0xf010723b
f0101803:	68 9b 70 10 f0       	push   $0xf010709b
f0101808:	68 a9 03 00 00       	push   $0x3a9
f010180d:	68 75 70 10 f0       	push   $0xf0107075
f0101812:	e8 29 e8 ff ff       	call   f0100040 <_panic>
f0101817:	89 f0                	mov    %esi,%eax
f0101819:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f010181f:	c1 f8 03             	sar    $0x3,%eax
f0101822:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101825:	89 c2                	mov    %eax,%edx
f0101827:	c1 ea 0c             	shr    $0xc,%edx
f010182a:	3b 15 c8 9e 20 f0    	cmp    0xf0209ec8,%edx
f0101830:	72 12                	jb     f0101844 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101832:	50                   	push   %eax
f0101833:	68 e4 60 10 f0       	push   $0xf01060e4
f0101838:	6a 58                	push   $0x58
f010183a:	68 81 70 10 f0       	push   $0xf0107081
f010183f:	e8 fc e7 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101844:	83 ec 04             	sub    $0x4,%esp
f0101847:	68 00 10 00 00       	push   $0x1000
f010184c:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010184e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101853:	50                   	push   %eax
f0101854:	e8 71 3b 00 00       	call   f01053ca <memset>
	page_free(pp0);
f0101859:	89 34 24             	mov    %esi,(%esp)
f010185c:	e8 e3 f7 ff ff       	call   f0101044 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101861:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101868:	e8 61 f7 ff ff       	call   f0100fce <page_alloc>
f010186d:	83 c4 10             	add    $0x10,%esp
f0101870:	85 c0                	test   %eax,%eax
f0101872:	75 19                	jne    f010188d <mem_init+0x4a1>
f0101874:	68 4a 72 10 f0       	push   $0xf010724a
f0101879:	68 9b 70 10 f0       	push   $0xf010709b
f010187e:	68 ae 03 00 00       	push   $0x3ae
f0101883:	68 75 70 10 f0       	push   $0xf0107075
f0101888:	e8 b3 e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f010188d:	39 c6                	cmp    %eax,%esi
f010188f:	74 19                	je     f01018aa <mem_init+0x4be>
f0101891:	68 68 72 10 f0       	push   $0xf0107268
f0101896:	68 9b 70 10 f0       	push   $0xf010709b
f010189b:	68 af 03 00 00       	push   $0x3af
f01018a0:	68 75 70 10 f0       	push   $0xf0107075
f01018a5:	e8 96 e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018aa:	89 f0                	mov    %esi,%eax
f01018ac:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f01018b2:	c1 f8 03             	sar    $0x3,%eax
f01018b5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018b8:	89 c2                	mov    %eax,%edx
f01018ba:	c1 ea 0c             	shr    $0xc,%edx
f01018bd:	3b 15 c8 9e 20 f0    	cmp    0xf0209ec8,%edx
f01018c3:	72 12                	jb     f01018d7 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018c5:	50                   	push   %eax
f01018c6:	68 e4 60 10 f0       	push   $0xf01060e4
f01018cb:	6a 58                	push   $0x58
f01018cd:	68 81 70 10 f0       	push   $0xf0107081
f01018d2:	e8 69 e7 ff ff       	call   f0100040 <_panic>
f01018d7:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01018dd:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018e3:	80 38 00             	cmpb   $0x0,(%eax)
f01018e6:	74 19                	je     f0101901 <mem_init+0x515>
f01018e8:	68 78 72 10 f0       	push   $0xf0107278
f01018ed:	68 9b 70 10 f0       	push   $0xf010709b
f01018f2:	68 b2 03 00 00       	push   $0x3b2
f01018f7:	68 75 70 10 f0       	push   $0xf0107075
f01018fc:	e8 3f e7 ff ff       	call   f0100040 <_panic>
f0101901:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101904:	39 d0                	cmp    %edx,%eax
f0101906:	75 db                	jne    f01018e3 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101908:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010190b:	a3 64 92 20 f0       	mov    %eax,0xf0209264

	// free the pages we took
	page_free(pp0);
f0101910:	83 ec 0c             	sub    $0xc,%esp
f0101913:	56                   	push   %esi
f0101914:	e8 2b f7 ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f0101919:	89 3c 24             	mov    %edi,(%esp)
f010191c:	e8 23 f7 ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f0101921:	83 c4 04             	add    $0x4,%esp
f0101924:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101927:	e8 18 f7 ff ff       	call   f0101044 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010192c:	a1 64 92 20 f0       	mov    0xf0209264,%eax
f0101931:	83 c4 10             	add    $0x10,%esp
f0101934:	eb 05                	jmp    f010193b <mem_init+0x54f>
		--nfree;
f0101936:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101939:	8b 00                	mov    (%eax),%eax
f010193b:	85 c0                	test   %eax,%eax
f010193d:	75 f7                	jne    f0101936 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f010193f:	85 db                	test   %ebx,%ebx
f0101941:	74 19                	je     f010195c <mem_init+0x570>
f0101943:	68 82 72 10 f0       	push   $0xf0107282
f0101948:	68 9b 70 10 f0       	push   $0xf010709b
f010194d:	68 bf 03 00 00       	push   $0x3bf
f0101952:	68 75 70 10 f0       	push   $0xf0107075
f0101957:	e8 e4 e6 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010195c:	83 ec 0c             	sub    $0xc,%esp
f010195f:	68 b8 68 10 f0       	push   $0xf01068b8
f0101964:	e8 b8 1e 00 00       	call   f0103821 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101969:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101970:	e8 59 f6 ff ff       	call   f0100fce <page_alloc>
f0101975:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101978:	83 c4 10             	add    $0x10,%esp
f010197b:	85 c0                	test   %eax,%eax
f010197d:	75 19                	jne    f0101998 <mem_init+0x5ac>
f010197f:	68 90 71 10 f0       	push   $0xf0107190
f0101984:	68 9b 70 10 f0       	push   $0xf010709b
f0101989:	68 25 04 00 00       	push   $0x425
f010198e:	68 75 70 10 f0       	push   $0xf0107075
f0101993:	e8 a8 e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101998:	83 ec 0c             	sub    $0xc,%esp
f010199b:	6a 00                	push   $0x0
f010199d:	e8 2c f6 ff ff       	call   f0100fce <page_alloc>
f01019a2:	89 c3                	mov    %eax,%ebx
f01019a4:	83 c4 10             	add    $0x10,%esp
f01019a7:	85 c0                	test   %eax,%eax
f01019a9:	75 19                	jne    f01019c4 <mem_init+0x5d8>
f01019ab:	68 a6 71 10 f0       	push   $0xf01071a6
f01019b0:	68 9b 70 10 f0       	push   $0xf010709b
f01019b5:	68 26 04 00 00       	push   $0x426
f01019ba:	68 75 70 10 f0       	push   $0xf0107075
f01019bf:	e8 7c e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01019c4:	83 ec 0c             	sub    $0xc,%esp
f01019c7:	6a 00                	push   $0x0
f01019c9:	e8 00 f6 ff ff       	call   f0100fce <page_alloc>
f01019ce:	89 c6                	mov    %eax,%esi
f01019d0:	83 c4 10             	add    $0x10,%esp
f01019d3:	85 c0                	test   %eax,%eax
f01019d5:	75 19                	jne    f01019f0 <mem_init+0x604>
f01019d7:	68 bc 71 10 f0       	push   $0xf01071bc
f01019dc:	68 9b 70 10 f0       	push   $0xf010709b
f01019e1:	68 27 04 00 00       	push   $0x427
f01019e6:	68 75 70 10 f0       	push   $0xf0107075
f01019eb:	e8 50 e6 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019f0:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01019f3:	75 19                	jne    f0101a0e <mem_init+0x622>
f01019f5:	68 d2 71 10 f0       	push   $0xf01071d2
f01019fa:	68 9b 70 10 f0       	push   $0xf010709b
f01019ff:	68 2a 04 00 00       	push   $0x42a
f0101a04:	68 75 70 10 f0       	push   $0xf0107075
f0101a09:	e8 32 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a0e:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a11:	74 04                	je     f0101a17 <mem_init+0x62b>
f0101a13:	39 c3                	cmp    %eax,%ebx
f0101a15:	75 19                	jne    f0101a30 <mem_init+0x644>
f0101a17:	68 98 68 10 f0       	push   $0xf0106898
f0101a1c:	68 9b 70 10 f0       	push   $0xf010709b
f0101a21:	68 2b 04 00 00       	push   $0x42b
f0101a26:	68 75 70 10 f0       	push   $0xf0107075
f0101a2b:	e8 10 e6 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a30:	a1 64 92 20 f0       	mov    0xf0209264,%eax
f0101a35:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a38:	c7 05 64 92 20 f0 00 	movl   $0x0,0xf0209264
f0101a3f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a42:	83 ec 0c             	sub    $0xc,%esp
f0101a45:	6a 00                	push   $0x0
f0101a47:	e8 82 f5 ff ff       	call   f0100fce <page_alloc>
f0101a4c:	83 c4 10             	add    $0x10,%esp
f0101a4f:	85 c0                	test   %eax,%eax
f0101a51:	74 19                	je     f0101a6c <mem_init+0x680>
f0101a53:	68 3b 72 10 f0       	push   $0xf010723b
f0101a58:	68 9b 70 10 f0       	push   $0xf010709b
f0101a5d:	68 33 04 00 00       	push   $0x433
f0101a62:	68 75 70 10 f0       	push   $0xf0107075
f0101a67:	e8 d4 e5 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a6c:	83 ec 04             	sub    $0x4,%esp
f0101a6f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a72:	50                   	push   %eax
f0101a73:	6a 00                	push   $0x0
f0101a75:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101a7b:	e8 ae f7 ff ff       	call   f010122e <page_lookup>
f0101a80:	83 c4 10             	add    $0x10,%esp
f0101a83:	85 c0                	test   %eax,%eax
f0101a85:	74 19                	je     f0101aa0 <mem_init+0x6b4>
f0101a87:	68 d8 68 10 f0       	push   $0xf01068d8
f0101a8c:	68 9b 70 10 f0       	push   $0xf010709b
f0101a91:	68 37 04 00 00       	push   $0x437
f0101a96:	68 75 70 10 f0       	push   $0xf0107075
f0101a9b:	e8 a0 e5 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101aa0:	6a 02                	push   $0x2
f0101aa2:	6a 00                	push   $0x0
f0101aa4:	53                   	push   %ebx
f0101aa5:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101aab:	e8 44 f8 ff ff       	call   f01012f4 <page_insert>
f0101ab0:	83 c4 10             	add    $0x10,%esp
f0101ab3:	85 c0                	test   %eax,%eax
f0101ab5:	78 19                	js     f0101ad0 <mem_init+0x6e4>
f0101ab7:	68 10 69 10 f0       	push   $0xf0106910
f0101abc:	68 9b 70 10 f0       	push   $0xf010709b
f0101ac1:	68 3a 04 00 00       	push   $0x43a
f0101ac6:	68 75 70 10 f0       	push   $0xf0107075
f0101acb:	e8 70 e5 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101ad0:	83 ec 0c             	sub    $0xc,%esp
f0101ad3:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ad6:	e8 69 f5 ff ff       	call   f0101044 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101adb:	6a 02                	push   $0x2
f0101add:	6a 00                	push   $0x0
f0101adf:	53                   	push   %ebx
f0101ae0:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101ae6:	e8 09 f8 ff ff       	call   f01012f4 <page_insert>
f0101aeb:	83 c4 20             	add    $0x20,%esp
f0101aee:	85 c0                	test   %eax,%eax
f0101af0:	74 19                	je     f0101b0b <mem_init+0x71f>
f0101af2:	68 40 69 10 f0       	push   $0xf0106940
f0101af7:	68 9b 70 10 f0       	push   $0xf010709b
f0101afc:	68 3e 04 00 00       	push   $0x43e
f0101b01:	68 75 70 10 f0       	push   $0xf0107075
f0101b06:	e8 35 e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b0b:	8b 3d cc 9e 20 f0    	mov    0xf0209ecc,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b11:	a1 d0 9e 20 f0       	mov    0xf0209ed0,%eax
f0101b16:	89 c1                	mov    %eax,%ecx
f0101b18:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b1b:	8b 17                	mov    (%edi),%edx
f0101b1d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b23:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b26:	29 c8                	sub    %ecx,%eax
f0101b28:	c1 f8 03             	sar    $0x3,%eax
f0101b2b:	c1 e0 0c             	shl    $0xc,%eax
f0101b2e:	39 c2                	cmp    %eax,%edx
f0101b30:	74 19                	je     f0101b4b <mem_init+0x75f>
f0101b32:	68 70 69 10 f0       	push   $0xf0106970
f0101b37:	68 9b 70 10 f0       	push   $0xf010709b
f0101b3c:	68 3f 04 00 00       	push   $0x43f
f0101b41:	68 75 70 10 f0       	push   $0xf0107075
f0101b46:	e8 f5 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b4b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b50:	89 f8                	mov    %edi,%eax
f0101b52:	e8 05 ef ff ff       	call   f0100a5c <check_va2pa>
f0101b57:	89 da                	mov    %ebx,%edx
f0101b59:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b5c:	c1 fa 03             	sar    $0x3,%edx
f0101b5f:	c1 e2 0c             	shl    $0xc,%edx
f0101b62:	39 d0                	cmp    %edx,%eax
f0101b64:	74 19                	je     f0101b7f <mem_init+0x793>
f0101b66:	68 98 69 10 f0       	push   $0xf0106998
f0101b6b:	68 9b 70 10 f0       	push   $0xf010709b
f0101b70:	68 40 04 00 00       	push   $0x440
f0101b75:	68 75 70 10 f0       	push   $0xf0107075
f0101b7a:	e8 c1 e4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101b7f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b84:	74 19                	je     f0101b9f <mem_init+0x7b3>
f0101b86:	68 8d 72 10 f0       	push   $0xf010728d
f0101b8b:	68 9b 70 10 f0       	push   $0xf010709b
f0101b90:	68 41 04 00 00       	push   $0x441
f0101b95:	68 75 70 10 f0       	push   $0xf0107075
f0101b9a:	e8 a1 e4 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101b9f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ba2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ba7:	74 19                	je     f0101bc2 <mem_init+0x7d6>
f0101ba9:	68 9e 72 10 f0       	push   $0xf010729e
f0101bae:	68 9b 70 10 f0       	push   $0xf010709b
f0101bb3:	68 42 04 00 00       	push   $0x442
f0101bb8:	68 75 70 10 f0       	push   $0xf0107075
f0101bbd:	e8 7e e4 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bc2:	6a 02                	push   $0x2
f0101bc4:	68 00 10 00 00       	push   $0x1000
f0101bc9:	56                   	push   %esi
f0101bca:	57                   	push   %edi
f0101bcb:	e8 24 f7 ff ff       	call   f01012f4 <page_insert>
f0101bd0:	83 c4 10             	add    $0x10,%esp
f0101bd3:	85 c0                	test   %eax,%eax
f0101bd5:	74 19                	je     f0101bf0 <mem_init+0x804>
f0101bd7:	68 c8 69 10 f0       	push   $0xf01069c8
f0101bdc:	68 9b 70 10 f0       	push   $0xf010709b
f0101be1:	68 45 04 00 00       	push   $0x445
f0101be6:	68 75 70 10 f0       	push   $0xf0107075
f0101beb:	e8 50 e4 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bf0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bf5:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f0101bfa:	e8 5d ee ff ff       	call   f0100a5c <check_va2pa>
f0101bff:	89 f2                	mov    %esi,%edx
f0101c01:	2b 15 d0 9e 20 f0    	sub    0xf0209ed0,%edx
f0101c07:	c1 fa 03             	sar    $0x3,%edx
f0101c0a:	c1 e2 0c             	shl    $0xc,%edx
f0101c0d:	39 d0                	cmp    %edx,%eax
f0101c0f:	74 19                	je     f0101c2a <mem_init+0x83e>
f0101c11:	68 04 6a 10 f0       	push   $0xf0106a04
f0101c16:	68 9b 70 10 f0       	push   $0xf010709b
f0101c1b:	68 47 04 00 00       	push   $0x447
f0101c20:	68 75 70 10 f0       	push   $0xf0107075
f0101c25:	e8 16 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c2a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c2f:	74 19                	je     f0101c4a <mem_init+0x85e>
f0101c31:	68 af 72 10 f0       	push   $0xf01072af
f0101c36:	68 9b 70 10 f0       	push   $0xf010709b
f0101c3b:	68 48 04 00 00       	push   $0x448
f0101c40:	68 75 70 10 f0       	push   $0xf0107075
f0101c45:	e8 f6 e3 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101c4a:	83 ec 0c             	sub    $0xc,%esp
f0101c4d:	6a 00                	push   $0x0
f0101c4f:	e8 7a f3 ff ff       	call   f0100fce <page_alloc>
f0101c54:	83 c4 10             	add    $0x10,%esp
f0101c57:	85 c0                	test   %eax,%eax
f0101c59:	74 19                	je     f0101c74 <mem_init+0x888>
f0101c5b:	68 3b 72 10 f0       	push   $0xf010723b
f0101c60:	68 9b 70 10 f0       	push   $0xf010709b
f0101c65:	68 4b 04 00 00       	push   $0x44b
f0101c6a:	68 75 70 10 f0       	push   $0xf0107075
f0101c6f:	e8 cc e3 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c74:	6a 02                	push   $0x2
f0101c76:	68 00 10 00 00       	push   $0x1000
f0101c7b:	56                   	push   %esi
f0101c7c:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101c82:	e8 6d f6 ff ff       	call   f01012f4 <page_insert>
f0101c87:	83 c4 10             	add    $0x10,%esp
f0101c8a:	85 c0                	test   %eax,%eax
f0101c8c:	74 19                	je     f0101ca7 <mem_init+0x8bb>
f0101c8e:	68 c8 69 10 f0       	push   $0xf01069c8
f0101c93:	68 9b 70 10 f0       	push   $0xf010709b
f0101c98:	68 4e 04 00 00       	push   $0x44e
f0101c9d:	68 75 70 10 f0       	push   $0xf0107075
f0101ca2:	e8 99 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ca7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cac:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f0101cb1:	e8 a6 ed ff ff       	call   f0100a5c <check_va2pa>
f0101cb6:	89 f2                	mov    %esi,%edx
f0101cb8:	2b 15 d0 9e 20 f0    	sub    0xf0209ed0,%edx
f0101cbe:	c1 fa 03             	sar    $0x3,%edx
f0101cc1:	c1 e2 0c             	shl    $0xc,%edx
f0101cc4:	39 d0                	cmp    %edx,%eax
f0101cc6:	74 19                	je     f0101ce1 <mem_init+0x8f5>
f0101cc8:	68 04 6a 10 f0       	push   $0xf0106a04
f0101ccd:	68 9b 70 10 f0       	push   $0xf010709b
f0101cd2:	68 4f 04 00 00       	push   $0x44f
f0101cd7:	68 75 70 10 f0       	push   $0xf0107075
f0101cdc:	e8 5f e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ce1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ce6:	74 19                	je     f0101d01 <mem_init+0x915>
f0101ce8:	68 af 72 10 f0       	push   $0xf01072af
f0101ced:	68 9b 70 10 f0       	push   $0xf010709b
f0101cf2:	68 50 04 00 00       	push   $0x450
f0101cf7:	68 75 70 10 f0       	push   $0xf0107075
f0101cfc:	e8 3f e3 ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d01:	83 ec 0c             	sub    $0xc,%esp
f0101d04:	6a 00                	push   $0x0
f0101d06:	e8 c3 f2 ff ff       	call   f0100fce <page_alloc>
f0101d0b:	83 c4 10             	add    $0x10,%esp
f0101d0e:	85 c0                	test   %eax,%eax
f0101d10:	74 19                	je     f0101d2b <mem_init+0x93f>
f0101d12:	68 3b 72 10 f0       	push   $0xf010723b
f0101d17:	68 9b 70 10 f0       	push   $0xf010709b
f0101d1c:	68 54 04 00 00       	push   $0x454
f0101d21:	68 75 70 10 f0       	push   $0xf0107075
f0101d26:	e8 15 e3 ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d2b:	8b 15 cc 9e 20 f0    	mov    0xf0209ecc,%edx
f0101d31:	8b 02                	mov    (%edx),%eax
f0101d33:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d38:	89 c1                	mov    %eax,%ecx
f0101d3a:	c1 e9 0c             	shr    $0xc,%ecx
f0101d3d:	3b 0d c8 9e 20 f0    	cmp    0xf0209ec8,%ecx
f0101d43:	72 15                	jb     f0101d5a <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d45:	50                   	push   %eax
f0101d46:	68 e4 60 10 f0       	push   $0xf01060e4
f0101d4b:	68 57 04 00 00       	push   $0x457
f0101d50:	68 75 70 10 f0       	push   $0xf0107075
f0101d55:	e8 e6 e2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101d5a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d62:	83 ec 04             	sub    $0x4,%esp
f0101d65:	6a 00                	push   $0x0
f0101d67:	68 00 10 00 00       	push   $0x1000
f0101d6c:	52                   	push   %edx
f0101d6d:	e8 4a f3 ff ff       	call   f01010bc <pgdir_walk>
f0101d72:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d75:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d78:	83 c4 10             	add    $0x10,%esp
f0101d7b:	39 d0                	cmp    %edx,%eax
f0101d7d:	74 19                	je     f0101d98 <mem_init+0x9ac>
f0101d7f:	68 34 6a 10 f0       	push   $0xf0106a34
f0101d84:	68 9b 70 10 f0       	push   $0xf010709b
f0101d89:	68 58 04 00 00       	push   $0x458
f0101d8e:	68 75 70 10 f0       	push   $0xf0107075
f0101d93:	e8 a8 e2 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d98:	6a 06                	push   $0x6
f0101d9a:	68 00 10 00 00       	push   $0x1000
f0101d9f:	56                   	push   %esi
f0101da0:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101da6:	e8 49 f5 ff ff       	call   f01012f4 <page_insert>
f0101dab:	83 c4 10             	add    $0x10,%esp
f0101dae:	85 c0                	test   %eax,%eax
f0101db0:	74 19                	je     f0101dcb <mem_init+0x9df>
f0101db2:	68 74 6a 10 f0       	push   $0xf0106a74
f0101db7:	68 9b 70 10 f0       	push   $0xf010709b
f0101dbc:	68 5b 04 00 00       	push   $0x45b
f0101dc1:	68 75 70 10 f0       	push   $0xf0107075
f0101dc6:	e8 75 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dcb:	8b 3d cc 9e 20 f0    	mov    0xf0209ecc,%edi
f0101dd1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dd6:	89 f8                	mov    %edi,%eax
f0101dd8:	e8 7f ec ff ff       	call   f0100a5c <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ddd:	89 f2                	mov    %esi,%edx
f0101ddf:	2b 15 d0 9e 20 f0    	sub    0xf0209ed0,%edx
f0101de5:	c1 fa 03             	sar    $0x3,%edx
f0101de8:	c1 e2 0c             	shl    $0xc,%edx
f0101deb:	39 d0                	cmp    %edx,%eax
f0101ded:	74 19                	je     f0101e08 <mem_init+0xa1c>
f0101def:	68 04 6a 10 f0       	push   $0xf0106a04
f0101df4:	68 9b 70 10 f0       	push   $0xf010709b
f0101df9:	68 5c 04 00 00       	push   $0x45c
f0101dfe:	68 75 70 10 f0       	push   $0xf0107075
f0101e03:	e8 38 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101e08:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e0d:	74 19                	je     f0101e28 <mem_init+0xa3c>
f0101e0f:	68 af 72 10 f0       	push   $0xf01072af
f0101e14:	68 9b 70 10 f0       	push   $0xf010709b
f0101e19:	68 5d 04 00 00       	push   $0x45d
f0101e1e:	68 75 70 10 f0       	push   $0xf0107075
f0101e23:	e8 18 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e28:	83 ec 04             	sub    $0x4,%esp
f0101e2b:	6a 00                	push   $0x0
f0101e2d:	68 00 10 00 00       	push   $0x1000
f0101e32:	57                   	push   %edi
f0101e33:	e8 84 f2 ff ff       	call   f01010bc <pgdir_walk>
f0101e38:	83 c4 10             	add    $0x10,%esp
f0101e3b:	f6 00 04             	testb  $0x4,(%eax)
f0101e3e:	75 19                	jne    f0101e59 <mem_init+0xa6d>
f0101e40:	68 b4 6a 10 f0       	push   $0xf0106ab4
f0101e45:	68 9b 70 10 f0       	push   $0xf010709b
f0101e4a:	68 5e 04 00 00       	push   $0x45e
f0101e4f:	68 75 70 10 f0       	push   $0xf0107075
f0101e54:	e8 e7 e1 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e59:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f0101e5e:	f6 00 04             	testb  $0x4,(%eax)
f0101e61:	75 19                	jne    f0101e7c <mem_init+0xa90>
f0101e63:	68 c0 72 10 f0       	push   $0xf01072c0
f0101e68:	68 9b 70 10 f0       	push   $0xf010709b
f0101e6d:	68 5f 04 00 00       	push   $0x45f
f0101e72:	68 75 70 10 f0       	push   $0xf0107075
f0101e77:	e8 c4 e1 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e7c:	6a 02                	push   $0x2
f0101e7e:	68 00 10 00 00       	push   $0x1000
f0101e83:	56                   	push   %esi
f0101e84:	50                   	push   %eax
f0101e85:	e8 6a f4 ff ff       	call   f01012f4 <page_insert>
f0101e8a:	83 c4 10             	add    $0x10,%esp
f0101e8d:	85 c0                	test   %eax,%eax
f0101e8f:	74 19                	je     f0101eaa <mem_init+0xabe>
f0101e91:	68 c8 69 10 f0       	push   $0xf01069c8
f0101e96:	68 9b 70 10 f0       	push   $0xf010709b
f0101e9b:	68 62 04 00 00       	push   $0x462
f0101ea0:	68 75 70 10 f0       	push   $0xf0107075
f0101ea5:	e8 96 e1 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101eaa:	83 ec 04             	sub    $0x4,%esp
f0101ead:	6a 00                	push   $0x0
f0101eaf:	68 00 10 00 00       	push   $0x1000
f0101eb4:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101eba:	e8 fd f1 ff ff       	call   f01010bc <pgdir_walk>
f0101ebf:	83 c4 10             	add    $0x10,%esp
f0101ec2:	f6 00 02             	testb  $0x2,(%eax)
f0101ec5:	75 19                	jne    f0101ee0 <mem_init+0xaf4>
f0101ec7:	68 e8 6a 10 f0       	push   $0xf0106ae8
f0101ecc:	68 9b 70 10 f0       	push   $0xf010709b
f0101ed1:	68 63 04 00 00       	push   $0x463
f0101ed6:	68 75 70 10 f0       	push   $0xf0107075
f0101edb:	e8 60 e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ee0:	83 ec 04             	sub    $0x4,%esp
f0101ee3:	6a 00                	push   $0x0
f0101ee5:	68 00 10 00 00       	push   $0x1000
f0101eea:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101ef0:	e8 c7 f1 ff ff       	call   f01010bc <pgdir_walk>
f0101ef5:	83 c4 10             	add    $0x10,%esp
f0101ef8:	f6 00 04             	testb  $0x4,(%eax)
f0101efb:	74 19                	je     f0101f16 <mem_init+0xb2a>
f0101efd:	68 1c 6b 10 f0       	push   $0xf0106b1c
f0101f02:	68 9b 70 10 f0       	push   $0xf010709b
f0101f07:	68 64 04 00 00       	push   $0x464
f0101f0c:	68 75 70 10 f0       	push   $0xf0107075
f0101f11:	e8 2a e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f16:	6a 02                	push   $0x2
f0101f18:	68 00 00 40 00       	push   $0x400000
f0101f1d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101f20:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101f26:	e8 c9 f3 ff ff       	call   f01012f4 <page_insert>
f0101f2b:	83 c4 10             	add    $0x10,%esp
f0101f2e:	85 c0                	test   %eax,%eax
f0101f30:	78 19                	js     f0101f4b <mem_init+0xb5f>
f0101f32:	68 54 6b 10 f0       	push   $0xf0106b54
f0101f37:	68 9b 70 10 f0       	push   $0xf010709b
f0101f3c:	68 67 04 00 00       	push   $0x467
f0101f41:	68 75 70 10 f0       	push   $0xf0107075
f0101f46:	e8 f5 e0 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f4b:	6a 02                	push   $0x2
f0101f4d:	68 00 10 00 00       	push   $0x1000
f0101f52:	53                   	push   %ebx
f0101f53:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101f59:	e8 96 f3 ff ff       	call   f01012f4 <page_insert>
f0101f5e:	83 c4 10             	add    $0x10,%esp
f0101f61:	85 c0                	test   %eax,%eax
f0101f63:	74 19                	je     f0101f7e <mem_init+0xb92>
f0101f65:	68 8c 6b 10 f0       	push   $0xf0106b8c
f0101f6a:	68 9b 70 10 f0       	push   $0xf010709b
f0101f6f:	68 6a 04 00 00       	push   $0x46a
f0101f74:	68 75 70 10 f0       	push   $0xf0107075
f0101f79:	e8 c2 e0 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f7e:	83 ec 04             	sub    $0x4,%esp
f0101f81:	6a 00                	push   $0x0
f0101f83:	68 00 10 00 00       	push   $0x1000
f0101f88:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0101f8e:	e8 29 f1 ff ff       	call   f01010bc <pgdir_walk>
f0101f93:	83 c4 10             	add    $0x10,%esp
f0101f96:	f6 00 04             	testb  $0x4,(%eax)
f0101f99:	74 19                	je     f0101fb4 <mem_init+0xbc8>
f0101f9b:	68 1c 6b 10 f0       	push   $0xf0106b1c
f0101fa0:	68 9b 70 10 f0       	push   $0xf010709b
f0101fa5:	68 6b 04 00 00       	push   $0x46b
f0101faa:	68 75 70 10 f0       	push   $0xf0107075
f0101faf:	e8 8c e0 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fb4:	8b 3d cc 9e 20 f0    	mov    0xf0209ecc,%edi
f0101fba:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fbf:	89 f8                	mov    %edi,%eax
f0101fc1:	e8 96 ea ff ff       	call   f0100a5c <check_va2pa>
f0101fc6:	89 c1                	mov    %eax,%ecx
f0101fc8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fcb:	89 d8                	mov    %ebx,%eax
f0101fcd:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0101fd3:	c1 f8 03             	sar    $0x3,%eax
f0101fd6:	c1 e0 0c             	shl    $0xc,%eax
f0101fd9:	39 c1                	cmp    %eax,%ecx
f0101fdb:	74 19                	je     f0101ff6 <mem_init+0xc0a>
f0101fdd:	68 c8 6b 10 f0       	push   $0xf0106bc8
f0101fe2:	68 9b 70 10 f0       	push   $0xf010709b
f0101fe7:	68 6e 04 00 00       	push   $0x46e
f0101fec:	68 75 70 10 f0       	push   $0xf0107075
f0101ff1:	e8 4a e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ff6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ffb:	89 f8                	mov    %edi,%eax
f0101ffd:	e8 5a ea ff ff       	call   f0100a5c <check_va2pa>
f0102002:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102005:	74 19                	je     f0102020 <mem_init+0xc34>
f0102007:	68 f4 6b 10 f0       	push   $0xf0106bf4
f010200c:	68 9b 70 10 f0       	push   $0xf010709b
f0102011:	68 6f 04 00 00       	push   $0x46f
f0102016:	68 75 70 10 f0       	push   $0xf0107075
f010201b:	e8 20 e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102020:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102025:	74 19                	je     f0102040 <mem_init+0xc54>
f0102027:	68 d6 72 10 f0       	push   $0xf01072d6
f010202c:	68 9b 70 10 f0       	push   $0xf010709b
f0102031:	68 71 04 00 00       	push   $0x471
f0102036:	68 75 70 10 f0       	push   $0xf0107075
f010203b:	e8 00 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102040:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102045:	74 19                	je     f0102060 <mem_init+0xc74>
f0102047:	68 e7 72 10 f0       	push   $0xf01072e7
f010204c:	68 9b 70 10 f0       	push   $0xf010709b
f0102051:	68 72 04 00 00       	push   $0x472
f0102056:	68 75 70 10 f0       	push   $0xf0107075
f010205b:	e8 e0 df ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102060:	83 ec 0c             	sub    $0xc,%esp
f0102063:	6a 00                	push   $0x0
f0102065:	e8 64 ef ff ff       	call   f0100fce <page_alloc>
f010206a:	83 c4 10             	add    $0x10,%esp
f010206d:	85 c0                	test   %eax,%eax
f010206f:	74 04                	je     f0102075 <mem_init+0xc89>
f0102071:	39 c6                	cmp    %eax,%esi
f0102073:	74 19                	je     f010208e <mem_init+0xca2>
f0102075:	68 24 6c 10 f0       	push   $0xf0106c24
f010207a:	68 9b 70 10 f0       	push   $0xf010709b
f010207f:	68 75 04 00 00       	push   $0x475
f0102084:	68 75 70 10 f0       	push   $0xf0107075
f0102089:	e8 b2 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010208e:	83 ec 08             	sub    $0x8,%esp
f0102091:	6a 00                	push   $0x0
f0102093:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0102099:	e8 10 f2 ff ff       	call   f01012ae <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010209e:	8b 3d cc 9e 20 f0    	mov    0xf0209ecc,%edi
f01020a4:	ba 00 00 00 00       	mov    $0x0,%edx
f01020a9:	89 f8                	mov    %edi,%eax
f01020ab:	e8 ac e9 ff ff       	call   f0100a5c <check_va2pa>
f01020b0:	83 c4 10             	add    $0x10,%esp
f01020b3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020b6:	74 19                	je     f01020d1 <mem_init+0xce5>
f01020b8:	68 48 6c 10 f0       	push   $0xf0106c48
f01020bd:	68 9b 70 10 f0       	push   $0xf010709b
f01020c2:	68 79 04 00 00       	push   $0x479
f01020c7:	68 75 70 10 f0       	push   $0xf0107075
f01020cc:	e8 6f df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020d1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020d6:	89 f8                	mov    %edi,%eax
f01020d8:	e8 7f e9 ff ff       	call   f0100a5c <check_va2pa>
f01020dd:	89 da                	mov    %ebx,%edx
f01020df:	2b 15 d0 9e 20 f0    	sub    0xf0209ed0,%edx
f01020e5:	c1 fa 03             	sar    $0x3,%edx
f01020e8:	c1 e2 0c             	shl    $0xc,%edx
f01020eb:	39 d0                	cmp    %edx,%eax
f01020ed:	74 19                	je     f0102108 <mem_init+0xd1c>
f01020ef:	68 f4 6b 10 f0       	push   $0xf0106bf4
f01020f4:	68 9b 70 10 f0       	push   $0xf010709b
f01020f9:	68 7a 04 00 00       	push   $0x47a
f01020fe:	68 75 70 10 f0       	push   $0xf0107075
f0102103:	e8 38 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102108:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010210d:	74 19                	je     f0102128 <mem_init+0xd3c>
f010210f:	68 8d 72 10 f0       	push   $0xf010728d
f0102114:	68 9b 70 10 f0       	push   $0xf010709b
f0102119:	68 7b 04 00 00       	push   $0x47b
f010211e:	68 75 70 10 f0       	push   $0xf0107075
f0102123:	e8 18 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102128:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010212d:	74 19                	je     f0102148 <mem_init+0xd5c>
f010212f:	68 e7 72 10 f0       	push   $0xf01072e7
f0102134:	68 9b 70 10 f0       	push   $0xf010709b
f0102139:	68 7c 04 00 00       	push   $0x47c
f010213e:	68 75 70 10 f0       	push   $0xf0107075
f0102143:	e8 f8 de ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102148:	6a 00                	push   $0x0
f010214a:	68 00 10 00 00       	push   $0x1000
f010214f:	53                   	push   %ebx
f0102150:	57                   	push   %edi
f0102151:	e8 9e f1 ff ff       	call   f01012f4 <page_insert>
f0102156:	83 c4 10             	add    $0x10,%esp
f0102159:	85 c0                	test   %eax,%eax
f010215b:	74 19                	je     f0102176 <mem_init+0xd8a>
f010215d:	68 6c 6c 10 f0       	push   $0xf0106c6c
f0102162:	68 9b 70 10 f0       	push   $0xf010709b
f0102167:	68 7f 04 00 00       	push   $0x47f
f010216c:	68 75 70 10 f0       	push   $0xf0107075
f0102171:	e8 ca de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0102176:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010217b:	75 19                	jne    f0102196 <mem_init+0xdaa>
f010217d:	68 f8 72 10 f0       	push   $0xf01072f8
f0102182:	68 9b 70 10 f0       	push   $0xf010709b
f0102187:	68 80 04 00 00       	push   $0x480
f010218c:	68 75 70 10 f0       	push   $0xf0107075
f0102191:	e8 aa de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102196:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102199:	74 19                	je     f01021b4 <mem_init+0xdc8>
f010219b:	68 04 73 10 f0       	push   $0xf0107304
f01021a0:	68 9b 70 10 f0       	push   $0xf010709b
f01021a5:	68 81 04 00 00       	push   $0x481
f01021aa:	68 75 70 10 f0       	push   $0xf0107075
f01021af:	e8 8c de ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021b4:	83 ec 08             	sub    $0x8,%esp
f01021b7:	68 00 10 00 00       	push   $0x1000
f01021bc:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f01021c2:	e8 e7 f0 ff ff       	call   f01012ae <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021c7:	8b 3d cc 9e 20 f0    	mov    0xf0209ecc,%edi
f01021cd:	ba 00 00 00 00       	mov    $0x0,%edx
f01021d2:	89 f8                	mov    %edi,%eax
f01021d4:	e8 83 e8 ff ff       	call   f0100a5c <check_va2pa>
f01021d9:	83 c4 10             	add    $0x10,%esp
f01021dc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021df:	74 19                	je     f01021fa <mem_init+0xe0e>
f01021e1:	68 48 6c 10 f0       	push   $0xf0106c48
f01021e6:	68 9b 70 10 f0       	push   $0xf010709b
f01021eb:	68 85 04 00 00       	push   $0x485
f01021f0:	68 75 70 10 f0       	push   $0xf0107075
f01021f5:	e8 46 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021fa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021ff:	89 f8                	mov    %edi,%eax
f0102201:	e8 56 e8 ff ff       	call   f0100a5c <check_va2pa>
f0102206:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102209:	74 19                	je     f0102224 <mem_init+0xe38>
f010220b:	68 a4 6c 10 f0       	push   $0xf0106ca4
f0102210:	68 9b 70 10 f0       	push   $0xf010709b
f0102215:	68 86 04 00 00       	push   $0x486
f010221a:	68 75 70 10 f0       	push   $0xf0107075
f010221f:	e8 1c de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102224:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102229:	74 19                	je     f0102244 <mem_init+0xe58>
f010222b:	68 19 73 10 f0       	push   $0xf0107319
f0102230:	68 9b 70 10 f0       	push   $0xf010709b
f0102235:	68 87 04 00 00       	push   $0x487
f010223a:	68 75 70 10 f0       	push   $0xf0107075
f010223f:	e8 fc dd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102244:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102249:	74 19                	je     f0102264 <mem_init+0xe78>
f010224b:	68 e7 72 10 f0       	push   $0xf01072e7
f0102250:	68 9b 70 10 f0       	push   $0xf010709b
f0102255:	68 88 04 00 00       	push   $0x488
f010225a:	68 75 70 10 f0       	push   $0xf0107075
f010225f:	e8 dc dd ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102264:	83 ec 0c             	sub    $0xc,%esp
f0102267:	6a 00                	push   $0x0
f0102269:	e8 60 ed ff ff       	call   f0100fce <page_alloc>
f010226e:	83 c4 10             	add    $0x10,%esp
f0102271:	85 c0                	test   %eax,%eax
f0102273:	74 04                	je     f0102279 <mem_init+0xe8d>
f0102275:	39 c3                	cmp    %eax,%ebx
f0102277:	74 19                	je     f0102292 <mem_init+0xea6>
f0102279:	68 cc 6c 10 f0       	push   $0xf0106ccc
f010227e:	68 9b 70 10 f0       	push   $0xf010709b
f0102283:	68 8b 04 00 00       	push   $0x48b
f0102288:	68 75 70 10 f0       	push   $0xf0107075
f010228d:	e8 ae dd ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102292:	83 ec 0c             	sub    $0xc,%esp
f0102295:	6a 00                	push   $0x0
f0102297:	e8 32 ed ff ff       	call   f0100fce <page_alloc>
f010229c:	83 c4 10             	add    $0x10,%esp
f010229f:	85 c0                	test   %eax,%eax
f01022a1:	74 19                	je     f01022bc <mem_init+0xed0>
f01022a3:	68 3b 72 10 f0       	push   $0xf010723b
f01022a8:	68 9b 70 10 f0       	push   $0xf010709b
f01022ad:	68 8e 04 00 00       	push   $0x48e
f01022b2:	68 75 70 10 f0       	push   $0xf0107075
f01022b7:	e8 84 dd ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022bc:	8b 0d cc 9e 20 f0    	mov    0xf0209ecc,%ecx
f01022c2:	8b 11                	mov    (%ecx),%edx
f01022c4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01022ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022cd:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f01022d3:	c1 f8 03             	sar    $0x3,%eax
f01022d6:	c1 e0 0c             	shl    $0xc,%eax
f01022d9:	39 c2                	cmp    %eax,%edx
f01022db:	74 19                	je     f01022f6 <mem_init+0xf0a>
f01022dd:	68 70 69 10 f0       	push   $0xf0106970
f01022e2:	68 9b 70 10 f0       	push   $0xf010709b
f01022e7:	68 91 04 00 00       	push   $0x491
f01022ec:	68 75 70 10 f0       	push   $0xf0107075
f01022f1:	e8 4a dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01022f6:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01022fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022ff:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102304:	74 19                	je     f010231f <mem_init+0xf33>
f0102306:	68 9e 72 10 f0       	push   $0xf010729e
f010230b:	68 9b 70 10 f0       	push   $0xf010709b
f0102310:	68 93 04 00 00       	push   $0x493
f0102315:	68 75 70 10 f0       	push   $0xf0107075
f010231a:	e8 21 dd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010231f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102322:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102328:	83 ec 0c             	sub    $0xc,%esp
f010232b:	50                   	push   %eax
f010232c:	e8 13 ed ff ff       	call   f0101044 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102331:	83 c4 0c             	add    $0xc,%esp
f0102334:	6a 01                	push   $0x1
f0102336:	68 00 10 40 00       	push   $0x401000
f010233b:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0102341:	e8 76 ed ff ff       	call   f01010bc <pgdir_walk>
f0102346:	89 c7                	mov    %eax,%edi
f0102348:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010234b:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f0102350:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102353:	8b 40 04             	mov    0x4(%eax),%eax
f0102356:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010235b:	8b 0d c8 9e 20 f0    	mov    0xf0209ec8,%ecx
f0102361:	89 c2                	mov    %eax,%edx
f0102363:	c1 ea 0c             	shr    $0xc,%edx
f0102366:	83 c4 10             	add    $0x10,%esp
f0102369:	39 ca                	cmp    %ecx,%edx
f010236b:	72 15                	jb     f0102382 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010236d:	50                   	push   %eax
f010236e:	68 e4 60 10 f0       	push   $0xf01060e4
f0102373:	68 9a 04 00 00       	push   $0x49a
f0102378:	68 75 70 10 f0       	push   $0xf0107075
f010237d:	e8 be dc ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102382:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102387:	39 c7                	cmp    %eax,%edi
f0102389:	74 19                	je     f01023a4 <mem_init+0xfb8>
f010238b:	68 2a 73 10 f0       	push   $0xf010732a
f0102390:	68 9b 70 10 f0       	push   $0xf010709b
f0102395:	68 9b 04 00 00       	push   $0x49b
f010239a:	68 75 70 10 f0       	push   $0xf0107075
f010239f:	e8 9c dc ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01023a4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01023a7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01023ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023b1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023b7:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f01023bd:	c1 f8 03             	sar    $0x3,%eax
f01023c0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023c3:	89 c2                	mov    %eax,%edx
f01023c5:	c1 ea 0c             	shr    $0xc,%edx
f01023c8:	39 d1                	cmp    %edx,%ecx
f01023ca:	77 12                	ja     f01023de <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023cc:	50                   	push   %eax
f01023cd:	68 e4 60 10 f0       	push   $0xf01060e4
f01023d2:	6a 58                	push   $0x58
f01023d4:	68 81 70 10 f0       	push   $0xf0107081
f01023d9:	e8 62 dc ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01023de:	83 ec 04             	sub    $0x4,%esp
f01023e1:	68 00 10 00 00       	push   $0x1000
f01023e6:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01023eb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023f0:	50                   	push   %eax
f01023f1:	e8 d4 2f 00 00       	call   f01053ca <memset>
	page_free(pp0);
f01023f6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01023f9:	89 3c 24             	mov    %edi,(%esp)
f01023fc:	e8 43 ec ff ff       	call   f0101044 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102401:	83 c4 0c             	add    $0xc,%esp
f0102404:	6a 01                	push   $0x1
f0102406:	6a 00                	push   $0x0
f0102408:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f010240e:	e8 a9 ec ff ff       	call   f01010bc <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102413:	89 fa                	mov    %edi,%edx
f0102415:	2b 15 d0 9e 20 f0    	sub    0xf0209ed0,%edx
f010241b:	c1 fa 03             	sar    $0x3,%edx
f010241e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102421:	89 d0                	mov    %edx,%eax
f0102423:	c1 e8 0c             	shr    $0xc,%eax
f0102426:	83 c4 10             	add    $0x10,%esp
f0102429:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f010242f:	72 12                	jb     f0102443 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102431:	52                   	push   %edx
f0102432:	68 e4 60 10 f0       	push   $0xf01060e4
f0102437:	6a 58                	push   $0x58
f0102439:	68 81 70 10 f0       	push   $0xf0107081
f010243e:	e8 fd db ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102443:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102449:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010244c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102452:	f6 00 01             	testb  $0x1,(%eax)
f0102455:	74 19                	je     f0102470 <mem_init+0x1084>
f0102457:	68 42 73 10 f0       	push   $0xf0107342
f010245c:	68 9b 70 10 f0       	push   $0xf010709b
f0102461:	68 a5 04 00 00       	push   $0x4a5
f0102466:	68 75 70 10 f0       	push   $0xf0107075
f010246b:	e8 d0 db ff ff       	call   f0100040 <_panic>
f0102470:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102473:	39 d0                	cmp    %edx,%eax
f0102475:	75 db                	jne    f0102452 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102477:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f010247c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102482:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102485:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010248b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010248e:	89 0d 64 92 20 f0    	mov    %ecx,0xf0209264

	// free the pages we took
	page_free(pp0);
f0102494:	83 ec 0c             	sub    $0xc,%esp
f0102497:	50                   	push   %eax
f0102498:	e8 a7 eb ff ff       	call   f0101044 <page_free>
	page_free(pp1);
f010249d:	89 1c 24             	mov    %ebx,(%esp)
f01024a0:	e8 9f eb ff ff       	call   f0101044 <page_free>
	page_free(pp2);
f01024a5:	89 34 24             	mov    %esi,(%esp)
f01024a8:	e8 97 eb ff ff       	call   f0101044 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01024ad:	83 c4 08             	add    $0x8,%esp
f01024b0:	68 01 10 00 00       	push   $0x1001
f01024b5:	6a 00                	push   $0x0
f01024b7:	e8 f1 ee ff ff       	call   f01013ad <mmio_map_region>
f01024bc:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01024be:	83 c4 08             	add    $0x8,%esp
f01024c1:	68 00 10 00 00       	push   $0x1000
f01024c6:	6a 00                	push   $0x0
f01024c8:	e8 e0 ee ff ff       	call   f01013ad <mmio_map_region>
f01024cd:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01024cf:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01024d5:	83 c4 10             	add    $0x10,%esp
f01024d8:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01024dd:	77 08                	ja     f01024e7 <mem_init+0x10fb>
f01024df:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01024e5:	77 19                	ja     f0102500 <mem_init+0x1114>
f01024e7:	68 f0 6c 10 f0       	push   $0xf0106cf0
f01024ec:	68 9b 70 10 f0       	push   $0xf010709b
f01024f1:	68 b5 04 00 00       	push   $0x4b5
f01024f6:	68 75 70 10 f0       	push   $0xf0107075
f01024fb:	e8 40 db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102500:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102506:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f010250c:	77 08                	ja     f0102516 <mem_init+0x112a>
f010250e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102514:	77 19                	ja     f010252f <mem_init+0x1143>
f0102516:	68 18 6d 10 f0       	push   $0xf0106d18
f010251b:	68 9b 70 10 f0       	push   $0xf010709b
f0102520:	68 b6 04 00 00       	push   $0x4b6
f0102525:	68 75 70 10 f0       	push   $0xf0107075
f010252a:	e8 11 db ff ff       	call   f0100040 <_panic>
f010252f:	89 da                	mov    %ebx,%edx
f0102531:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102533:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102539:	74 19                	je     f0102554 <mem_init+0x1168>
f010253b:	68 40 6d 10 f0       	push   $0xf0106d40
f0102540:	68 9b 70 10 f0       	push   $0xf010709b
f0102545:	68 b8 04 00 00       	push   $0x4b8
f010254a:	68 75 70 10 f0       	push   $0xf0107075
f010254f:	e8 ec da ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102554:	39 c6                	cmp    %eax,%esi
f0102556:	73 19                	jae    f0102571 <mem_init+0x1185>
f0102558:	68 59 73 10 f0       	push   $0xf0107359
f010255d:	68 9b 70 10 f0       	push   $0xf010709b
f0102562:	68 ba 04 00 00       	push   $0x4ba
f0102567:	68 75 70 10 f0       	push   $0xf0107075
f010256c:	e8 cf da ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102571:	8b 3d cc 9e 20 f0    	mov    0xf0209ecc,%edi
f0102577:	89 da                	mov    %ebx,%edx
f0102579:	89 f8                	mov    %edi,%eax
f010257b:	e8 dc e4 ff ff       	call   f0100a5c <check_va2pa>
f0102580:	85 c0                	test   %eax,%eax
f0102582:	74 19                	je     f010259d <mem_init+0x11b1>
f0102584:	68 68 6d 10 f0       	push   $0xf0106d68
f0102589:	68 9b 70 10 f0       	push   $0xf010709b
f010258e:	68 bc 04 00 00       	push   $0x4bc
f0102593:	68 75 70 10 f0       	push   $0xf0107075
f0102598:	e8 a3 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010259d:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01025a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01025a6:	89 c2                	mov    %eax,%edx
f01025a8:	89 f8                	mov    %edi,%eax
f01025aa:	e8 ad e4 ff ff       	call   f0100a5c <check_va2pa>
f01025af:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01025b4:	74 19                	je     f01025cf <mem_init+0x11e3>
f01025b6:	68 8c 6d 10 f0       	push   $0xf0106d8c
f01025bb:	68 9b 70 10 f0       	push   $0xf010709b
f01025c0:	68 bd 04 00 00       	push   $0x4bd
f01025c5:	68 75 70 10 f0       	push   $0xf0107075
f01025ca:	e8 71 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01025cf:	89 f2                	mov    %esi,%edx
f01025d1:	89 f8                	mov    %edi,%eax
f01025d3:	e8 84 e4 ff ff       	call   f0100a5c <check_va2pa>
f01025d8:	85 c0                	test   %eax,%eax
f01025da:	74 19                	je     f01025f5 <mem_init+0x1209>
f01025dc:	68 bc 6d 10 f0       	push   $0xf0106dbc
f01025e1:	68 9b 70 10 f0       	push   $0xf010709b
f01025e6:	68 be 04 00 00       	push   $0x4be
f01025eb:	68 75 70 10 f0       	push   $0xf0107075
f01025f0:	e8 4b da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01025f5:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01025fb:	89 f8                	mov    %edi,%eax
f01025fd:	e8 5a e4 ff ff       	call   f0100a5c <check_va2pa>
f0102602:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102605:	74 19                	je     f0102620 <mem_init+0x1234>
f0102607:	68 e0 6d 10 f0       	push   $0xf0106de0
f010260c:	68 9b 70 10 f0       	push   $0xf010709b
f0102611:	68 bf 04 00 00       	push   $0x4bf
f0102616:	68 75 70 10 f0       	push   $0xf0107075
f010261b:	e8 20 da ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102620:	83 ec 04             	sub    $0x4,%esp
f0102623:	6a 00                	push   $0x0
f0102625:	53                   	push   %ebx
f0102626:	57                   	push   %edi
f0102627:	e8 90 ea ff ff       	call   f01010bc <pgdir_walk>
f010262c:	83 c4 10             	add    $0x10,%esp
f010262f:	f6 00 1a             	testb  $0x1a,(%eax)
f0102632:	75 19                	jne    f010264d <mem_init+0x1261>
f0102634:	68 0c 6e 10 f0       	push   $0xf0106e0c
f0102639:	68 9b 70 10 f0       	push   $0xf010709b
f010263e:	68 c1 04 00 00       	push   $0x4c1
f0102643:	68 75 70 10 f0       	push   $0xf0107075
f0102648:	e8 f3 d9 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f010264d:	83 ec 04             	sub    $0x4,%esp
f0102650:	6a 00                	push   $0x0
f0102652:	53                   	push   %ebx
f0102653:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0102659:	e8 5e ea ff ff       	call   f01010bc <pgdir_walk>
f010265e:	83 c4 10             	add    $0x10,%esp
f0102661:	f6 00 04             	testb  $0x4,(%eax)
f0102664:	74 19                	je     f010267f <mem_init+0x1293>
f0102666:	68 50 6e 10 f0       	push   $0xf0106e50
f010266b:	68 9b 70 10 f0       	push   $0xf010709b
f0102670:	68 c2 04 00 00       	push   $0x4c2
f0102675:	68 75 70 10 f0       	push   $0xf0107075
f010267a:	e8 c1 d9 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010267f:	83 ec 04             	sub    $0x4,%esp
f0102682:	6a 00                	push   $0x0
f0102684:	53                   	push   %ebx
f0102685:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f010268b:	e8 2c ea ff ff       	call   f01010bc <pgdir_walk>
f0102690:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102696:	83 c4 0c             	add    $0xc,%esp
f0102699:	6a 00                	push   $0x0
f010269b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010269e:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f01026a4:	e8 13 ea ff ff       	call   f01010bc <pgdir_walk>
f01026a9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01026af:	83 c4 0c             	add    $0xc,%esp
f01026b2:	6a 00                	push   $0x0
f01026b4:	56                   	push   %esi
f01026b5:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f01026bb:	e8 fc e9 ff ff       	call   f01010bc <pgdir_walk>
f01026c0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01026c6:	c7 04 24 6b 73 10 f0 	movl   $0xf010736b,(%esp)
f01026cd:	e8 4f 11 00 00       	call   f0103821 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f01026d2:	a1 d0 9e 20 f0       	mov    0xf0209ed0,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026d7:	83 c4 10             	add    $0x10,%esp
f01026da:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026df:	77 15                	ja     f01026f6 <mem_init+0x130a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026e1:	50                   	push   %eax
f01026e2:	68 08 61 10 f0       	push   $0xf0106108
f01026e7:	68 c5 00 00 00       	push   $0xc5
f01026ec:	68 75 70 10 f0       	push   $0xf0107075
f01026f1:	e8 4a d9 ff ff       	call   f0100040 <_panic>
f01026f6:	8b 15 c8 9e 20 f0    	mov    0xf0209ec8,%edx
f01026fc:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102703:	83 ec 08             	sub    $0x8,%esp
f0102706:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010270c:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f010270e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102713:	50                   	push   %eax
f0102714:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102719:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f010271e:	e8 84 ea ff ff       	call   f01011a7 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f0102723:	a1 6c 92 20 f0       	mov    0xf020926c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102728:	83 c4 10             	add    $0x10,%esp
f010272b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102730:	77 15                	ja     f0102747 <mem_init+0x135b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102732:	50                   	push   %eax
f0102733:	68 08 61 10 f0       	push   $0xf0106108
f0102738:	68 cd 00 00 00       	push   $0xcd
f010273d:	68 75 70 10 f0       	push   $0xf0107075
f0102742:	e8 f9 d8 ff ff       	call   f0100040 <_panic>
f0102747:	83 ec 08             	sub    $0x8,%esp
f010274a:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010274c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102751:	50                   	push   %eax
f0102752:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102757:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010275c:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f0102761:	e8 41 ea ff ff       	call   f01011a7 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102766:	83 c4 10             	add    $0x10,%esp
f0102769:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f010276e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102773:	77 15                	ja     f010278a <mem_init+0x139e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102775:	50                   	push   %eax
f0102776:	68 08 61 10 f0       	push   $0xf0106108
f010277b:	68 d9 00 00 00       	push   $0xd9
f0102780:	68 75 70 10 f0       	push   $0xf0107075
f0102785:	e8 b6 d8 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f010278a:	83 ec 08             	sub    $0x8,%esp
f010278d:	6a 03                	push   $0x3
f010278f:	68 00 60 11 00       	push   $0x116000
f0102794:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102799:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010279e:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f01027a3:	e8 ff e9 ff ff       	call   f01011a7 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f01027a8:	83 c4 08             	add    $0x8,%esp
f01027ab:	6a 03                	push   $0x3
f01027ad:	6a 00                	push   $0x0
f01027af:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027b4:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027b9:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f01027be:	e8 e4 e9 ff ff       	call   f01011a7 <boot_map_region>
f01027c3:	c7 45 c4 00 b0 20 f0 	movl   $0xf020b000,-0x3c(%ebp)
f01027ca:	83 c4 10             	add    $0x10,%esp
f01027cd:	bb 00 b0 20 f0       	mov    $0xf020b000,%ebx
f01027d2:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027d7:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01027dd:	77 15                	ja     f01027f4 <mem_init+0x1408>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027df:	53                   	push   %ebx
f01027e0:	68 08 61 10 f0       	push   $0xf0106108
f01027e5:	68 20 01 00 00       	push   $0x120
f01027ea:	68 75 70 10 f0       	push   $0xf0107075
f01027ef:	e8 4c d8 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f01027f4:	83 ec 08             	sub    $0x8,%esp
f01027f7:	6a 03                	push   $0x3
f01027f9:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01027ff:	50                   	push   %eax
f0102800:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102805:	89 f2                	mov    %esi,%edx
f0102807:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
f010280c:	e8 96 e9 ff ff       	call   f01011a7 <boot_map_region>
f0102811:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102817:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f010281d:	83 c4 10             	add    $0x10,%esp
f0102820:	81 fb 00 b0 24 f0    	cmp    $0xf024b000,%ebx
f0102826:	75 af                	jne    f01027d7 <mem_init+0x13eb>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102828:	8b 3d cc 9e 20 f0    	mov    0xf0209ecc,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010282e:	a1 c8 9e 20 f0       	mov    0xf0209ec8,%eax
f0102833:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102836:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010283d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102842:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102845:	8b 35 d0 9e 20 f0    	mov    0xf0209ed0,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010284b:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010284e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102853:	eb 55                	jmp    f01028aa <mem_init+0x14be>
f0102855:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010285b:	89 f8                	mov    %edi,%eax
f010285d:	e8 fa e1 ff ff       	call   f0100a5c <check_va2pa>
f0102862:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102869:	77 15                	ja     f0102880 <mem_init+0x1494>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010286b:	56                   	push   %esi
f010286c:	68 08 61 10 f0       	push   $0xf0106108
f0102871:	68 d7 03 00 00       	push   $0x3d7
f0102876:	68 75 70 10 f0       	push   $0xf0107075
f010287b:	e8 c0 d7 ff ff       	call   f0100040 <_panic>
f0102880:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102887:	39 d0                	cmp    %edx,%eax
f0102889:	74 19                	je     f01028a4 <mem_init+0x14b8>
f010288b:	68 84 6e 10 f0       	push   $0xf0106e84
f0102890:	68 9b 70 10 f0       	push   $0xf010709b
f0102895:	68 d7 03 00 00       	push   $0x3d7
f010289a:	68 75 70 10 f0       	push   $0xf0107075
f010289f:	e8 9c d7 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028a4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028aa:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01028ad:	77 a6                	ja     f0102855 <mem_init+0x1469>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01028af:	8b 35 6c 92 20 f0    	mov    0xf020926c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028b5:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028b8:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01028bd:	89 da                	mov    %ebx,%edx
f01028bf:	89 f8                	mov    %edi,%eax
f01028c1:	e8 96 e1 ff ff       	call   f0100a5c <check_va2pa>
f01028c6:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01028cd:	77 15                	ja     f01028e4 <mem_init+0x14f8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028cf:	56                   	push   %esi
f01028d0:	68 08 61 10 f0       	push   $0xf0106108
f01028d5:	68 dc 03 00 00       	push   $0x3dc
f01028da:	68 75 70 10 f0       	push   $0xf0107075
f01028df:	e8 5c d7 ff ff       	call   f0100040 <_panic>
f01028e4:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01028eb:	39 d0                	cmp    %edx,%eax
f01028ed:	74 19                	je     f0102908 <mem_init+0x151c>
f01028ef:	68 b8 6e 10 f0       	push   $0xf0106eb8
f01028f4:	68 9b 70 10 f0       	push   $0xf010709b
f01028f9:	68 dc 03 00 00       	push   $0x3dc
f01028fe:	68 75 70 10 f0       	push   $0xf0107075
f0102903:	e8 38 d7 ff ff       	call   f0100040 <_panic>
f0102908:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010290e:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102914:	75 a7                	jne    f01028bd <mem_init+0x14d1>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102916:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102919:	c1 e6 0c             	shl    $0xc,%esi
f010291c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102921:	eb 30                	jmp    f0102953 <mem_init+0x1567>
f0102923:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102929:	89 f8                	mov    %edi,%eax
f010292b:	e8 2c e1 ff ff       	call   f0100a5c <check_va2pa>
f0102930:	39 c3                	cmp    %eax,%ebx
f0102932:	74 19                	je     f010294d <mem_init+0x1561>
f0102934:	68 ec 6e 10 f0       	push   $0xf0106eec
f0102939:	68 9b 70 10 f0       	push   $0xf010709b
f010293e:	68 e0 03 00 00       	push   $0x3e0
f0102943:	68 75 70 10 f0       	push   $0xf0107075
f0102948:	e8 f3 d6 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010294d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102953:	39 f3                	cmp    %esi,%ebx
f0102955:	72 cc                	jb     f0102923 <mem_init+0x1537>
f0102957:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f010295e:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102963:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102966:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102969:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010296c:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102972:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102975:	89 c3                	mov    %eax,%ebx
f0102977:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010297a:	05 00 80 00 20       	add    $0x20008000,%eax
f010297f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102982:	89 da                	mov    %ebx,%edx
f0102984:	89 f8                	mov    %edi,%eax
f0102986:	e8 d1 e0 ff ff       	call   f0100a5c <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010298b:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102991:	77 15                	ja     f01029a8 <mem_init+0x15bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102993:	56                   	push   %esi
f0102994:	68 08 61 10 f0       	push   $0xf0106108
f0102999:	68 e8 03 00 00       	push   $0x3e8
f010299e:	68 75 70 10 f0       	push   $0xf0107075
f01029a3:	e8 98 d6 ff ff       	call   f0100040 <_panic>
f01029a8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01029ab:	8d 94 0b 00 b0 20 f0 	lea    -0xfdf5000(%ebx,%ecx,1),%edx
f01029b2:	39 d0                	cmp    %edx,%eax
f01029b4:	74 19                	je     f01029cf <mem_init+0x15e3>
f01029b6:	68 14 6f 10 f0       	push   $0xf0106f14
f01029bb:	68 9b 70 10 f0       	push   $0xf010709b
f01029c0:	68 e8 03 00 00       	push   $0x3e8
f01029c5:	68 75 70 10 f0       	push   $0xf0107075
f01029ca:	e8 71 d6 ff ff       	call   f0100040 <_panic>
f01029cf:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029d5:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01029d8:	75 a8                	jne    f0102982 <mem_init+0x1596>
f01029da:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01029dd:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01029e3:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01029e6:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01029e8:	89 da                	mov    %ebx,%edx
f01029ea:	89 f8                	mov    %edi,%eax
f01029ec:	e8 6b e0 ff ff       	call   f0100a5c <check_va2pa>
f01029f1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029f4:	74 19                	je     f0102a0f <mem_init+0x1623>
f01029f6:	68 5c 6f 10 f0       	push   $0xf0106f5c
f01029fb:	68 9b 70 10 f0       	push   $0xf010709b
f0102a00:	68 ea 03 00 00       	push   $0x3ea
f0102a05:	68 75 70 10 f0       	push   $0xf0107075
f0102a0a:	e8 31 d6 ff ff       	call   f0100040 <_panic>
f0102a0f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102a15:	39 de                	cmp    %ebx,%esi
f0102a17:	75 cf                	jne    f01029e8 <mem_init+0x15fc>
f0102a19:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102a1c:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102a23:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102a2a:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102a30:	81 fe 00 b0 24 f0    	cmp    $0xf024b000,%esi
f0102a36:	0f 85 2d ff ff ff    	jne    f0102969 <mem_init+0x157d>
f0102a3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a41:	eb 2a                	jmp    f0102a6d <mem_init+0x1681>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a43:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102a49:	83 fa 04             	cmp    $0x4,%edx
f0102a4c:	77 1f                	ja     f0102a6d <mem_init+0x1681>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102a4e:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102a52:	75 7e                	jne    f0102ad2 <mem_init+0x16e6>
f0102a54:	68 84 73 10 f0       	push   $0xf0107384
f0102a59:	68 9b 70 10 f0       	push   $0xf010709b
f0102a5e:	68 f5 03 00 00       	push   $0x3f5
f0102a63:	68 75 70 10 f0       	push   $0xf0107075
f0102a68:	e8 d3 d5 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a6d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a72:	76 3f                	jbe    f0102ab3 <mem_init+0x16c7>
				assert(pgdir[i] & PTE_P);
f0102a74:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102a77:	f6 c2 01             	test   $0x1,%dl
f0102a7a:	75 19                	jne    f0102a95 <mem_init+0x16a9>
f0102a7c:	68 84 73 10 f0       	push   $0xf0107384
f0102a81:	68 9b 70 10 f0       	push   $0xf010709b
f0102a86:	68 f9 03 00 00       	push   $0x3f9
f0102a8b:	68 75 70 10 f0       	push   $0xf0107075
f0102a90:	e8 ab d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a95:	f6 c2 02             	test   $0x2,%dl
f0102a98:	75 38                	jne    f0102ad2 <mem_init+0x16e6>
f0102a9a:	68 95 73 10 f0       	push   $0xf0107395
f0102a9f:	68 9b 70 10 f0       	push   $0xf010709b
f0102aa4:	68 fa 03 00 00       	push   $0x3fa
f0102aa9:	68 75 70 10 f0       	push   $0xf0107075
f0102aae:	e8 8d d5 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102ab3:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102ab7:	74 19                	je     f0102ad2 <mem_init+0x16e6>
f0102ab9:	68 a6 73 10 f0       	push   $0xf01073a6
f0102abe:	68 9b 70 10 f0       	push   $0xf010709b
f0102ac3:	68 fc 03 00 00       	push   $0x3fc
f0102ac8:	68 75 70 10 f0       	push   $0xf0107075
f0102acd:	e8 6e d5 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102ad2:	83 c0 01             	add    $0x1,%eax
f0102ad5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102ada:	0f 86 63 ff ff ff    	jbe    f0102a43 <mem_init+0x1657>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ae0:	83 ec 0c             	sub    $0xc,%esp
f0102ae3:	68 80 6f 10 f0       	push   $0xf0106f80
f0102ae8:	e8 34 0d 00 00       	call   f0103821 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102aed:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102af2:	83 c4 10             	add    $0x10,%esp
f0102af5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102afa:	77 15                	ja     f0102b11 <mem_init+0x1725>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102afc:	50                   	push   %eax
f0102afd:	68 08 61 10 f0       	push   $0xf0106108
f0102b02:	68 f2 00 00 00       	push   $0xf2
f0102b07:	68 75 70 10 f0       	push   $0xf0107075
f0102b0c:	e8 2f d5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b11:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b16:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102b19:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b1e:	e8 13 e0 ff ff       	call   f0100b36 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b23:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b26:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b29:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b2e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b31:	83 ec 0c             	sub    $0xc,%esp
f0102b34:	6a 00                	push   $0x0
f0102b36:	e8 93 e4 ff ff       	call   f0100fce <page_alloc>
f0102b3b:	89 c3                	mov    %eax,%ebx
f0102b3d:	83 c4 10             	add    $0x10,%esp
f0102b40:	85 c0                	test   %eax,%eax
f0102b42:	75 19                	jne    f0102b5d <mem_init+0x1771>
f0102b44:	68 90 71 10 f0       	push   $0xf0107190
f0102b49:	68 9b 70 10 f0       	push   $0xf010709b
f0102b4e:	68 d7 04 00 00       	push   $0x4d7
f0102b53:	68 75 70 10 f0       	push   $0xf0107075
f0102b58:	e8 e3 d4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b5d:	83 ec 0c             	sub    $0xc,%esp
f0102b60:	6a 00                	push   $0x0
f0102b62:	e8 67 e4 ff ff       	call   f0100fce <page_alloc>
f0102b67:	89 c7                	mov    %eax,%edi
f0102b69:	83 c4 10             	add    $0x10,%esp
f0102b6c:	85 c0                	test   %eax,%eax
f0102b6e:	75 19                	jne    f0102b89 <mem_init+0x179d>
f0102b70:	68 a6 71 10 f0       	push   $0xf01071a6
f0102b75:	68 9b 70 10 f0       	push   $0xf010709b
f0102b7a:	68 d8 04 00 00       	push   $0x4d8
f0102b7f:	68 75 70 10 f0       	push   $0xf0107075
f0102b84:	e8 b7 d4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b89:	83 ec 0c             	sub    $0xc,%esp
f0102b8c:	6a 00                	push   $0x0
f0102b8e:	e8 3b e4 ff ff       	call   f0100fce <page_alloc>
f0102b93:	89 c6                	mov    %eax,%esi
f0102b95:	83 c4 10             	add    $0x10,%esp
f0102b98:	85 c0                	test   %eax,%eax
f0102b9a:	75 19                	jne    f0102bb5 <mem_init+0x17c9>
f0102b9c:	68 bc 71 10 f0       	push   $0xf01071bc
f0102ba1:	68 9b 70 10 f0       	push   $0xf010709b
f0102ba6:	68 d9 04 00 00       	push   $0x4d9
f0102bab:	68 75 70 10 f0       	push   $0xf0107075
f0102bb0:	e8 8b d4 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102bb5:	83 ec 0c             	sub    $0xc,%esp
f0102bb8:	53                   	push   %ebx
f0102bb9:	e8 86 e4 ff ff       	call   f0101044 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bbe:	89 f8                	mov    %edi,%eax
f0102bc0:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0102bc6:	c1 f8 03             	sar    $0x3,%eax
f0102bc9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bcc:	89 c2                	mov    %eax,%edx
f0102bce:	c1 ea 0c             	shr    $0xc,%edx
f0102bd1:	83 c4 10             	add    $0x10,%esp
f0102bd4:	3b 15 c8 9e 20 f0    	cmp    0xf0209ec8,%edx
f0102bda:	72 12                	jb     f0102bee <mem_init+0x1802>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bdc:	50                   	push   %eax
f0102bdd:	68 e4 60 10 f0       	push   $0xf01060e4
f0102be2:	6a 58                	push   $0x58
f0102be4:	68 81 70 10 f0       	push   $0xf0107081
f0102be9:	e8 52 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102bee:	83 ec 04             	sub    $0x4,%esp
f0102bf1:	68 00 10 00 00       	push   $0x1000
f0102bf6:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102bf8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bfd:	50                   	push   %eax
f0102bfe:	e8 c7 27 00 00       	call   f01053ca <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c03:	89 f0                	mov    %esi,%eax
f0102c05:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0102c0b:	c1 f8 03             	sar    $0x3,%eax
f0102c0e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c11:	89 c2                	mov    %eax,%edx
f0102c13:	c1 ea 0c             	shr    $0xc,%edx
f0102c16:	83 c4 10             	add    $0x10,%esp
f0102c19:	3b 15 c8 9e 20 f0    	cmp    0xf0209ec8,%edx
f0102c1f:	72 12                	jb     f0102c33 <mem_init+0x1847>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c21:	50                   	push   %eax
f0102c22:	68 e4 60 10 f0       	push   $0xf01060e4
f0102c27:	6a 58                	push   $0x58
f0102c29:	68 81 70 10 f0       	push   $0xf0107081
f0102c2e:	e8 0d d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c33:	83 ec 04             	sub    $0x4,%esp
f0102c36:	68 00 10 00 00       	push   $0x1000
f0102c3b:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c3d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c42:	50                   	push   %eax
f0102c43:	e8 82 27 00 00       	call   f01053ca <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c48:	6a 02                	push   $0x2
f0102c4a:	68 00 10 00 00       	push   $0x1000
f0102c4f:	57                   	push   %edi
f0102c50:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0102c56:	e8 99 e6 ff ff       	call   f01012f4 <page_insert>
	assert(pp1->pp_ref == 1);
f0102c5b:	83 c4 20             	add    $0x20,%esp
f0102c5e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c63:	74 19                	je     f0102c7e <mem_init+0x1892>
f0102c65:	68 8d 72 10 f0       	push   $0xf010728d
f0102c6a:	68 9b 70 10 f0       	push   $0xf010709b
f0102c6f:	68 de 04 00 00       	push   $0x4de
f0102c74:	68 75 70 10 f0       	push   $0xf0107075
f0102c79:	e8 c2 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c7e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c85:	01 01 01 
f0102c88:	74 19                	je     f0102ca3 <mem_init+0x18b7>
f0102c8a:	68 a0 6f 10 f0       	push   $0xf0106fa0
f0102c8f:	68 9b 70 10 f0       	push   $0xf010709b
f0102c94:	68 df 04 00 00       	push   $0x4df
f0102c99:	68 75 70 10 f0       	push   $0xf0107075
f0102c9e:	e8 9d d3 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ca3:	6a 02                	push   $0x2
f0102ca5:	68 00 10 00 00       	push   $0x1000
f0102caa:	56                   	push   %esi
f0102cab:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0102cb1:	e8 3e e6 ff ff       	call   f01012f4 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102cb6:	83 c4 10             	add    $0x10,%esp
f0102cb9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102cc0:	02 02 02 
f0102cc3:	74 19                	je     f0102cde <mem_init+0x18f2>
f0102cc5:	68 c4 6f 10 f0       	push   $0xf0106fc4
f0102cca:	68 9b 70 10 f0       	push   $0xf010709b
f0102ccf:	68 e1 04 00 00       	push   $0x4e1
f0102cd4:	68 75 70 10 f0       	push   $0xf0107075
f0102cd9:	e8 62 d3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102cde:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ce3:	74 19                	je     f0102cfe <mem_init+0x1912>
f0102ce5:	68 af 72 10 f0       	push   $0xf01072af
f0102cea:	68 9b 70 10 f0       	push   $0xf010709b
f0102cef:	68 e2 04 00 00       	push   $0x4e2
f0102cf4:	68 75 70 10 f0       	push   $0xf0107075
f0102cf9:	e8 42 d3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102cfe:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d03:	74 19                	je     f0102d1e <mem_init+0x1932>
f0102d05:	68 19 73 10 f0       	push   $0xf0107319
f0102d0a:	68 9b 70 10 f0       	push   $0xf010709b
f0102d0f:	68 e3 04 00 00       	push   $0x4e3
f0102d14:	68 75 70 10 f0       	push   $0xf0107075
f0102d19:	e8 22 d3 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d1e:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d25:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d28:	89 f0                	mov    %esi,%eax
f0102d2a:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0102d30:	c1 f8 03             	sar    $0x3,%eax
f0102d33:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d36:	89 c2                	mov    %eax,%edx
f0102d38:	c1 ea 0c             	shr    $0xc,%edx
f0102d3b:	3b 15 c8 9e 20 f0    	cmp    0xf0209ec8,%edx
f0102d41:	72 12                	jb     f0102d55 <mem_init+0x1969>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d43:	50                   	push   %eax
f0102d44:	68 e4 60 10 f0       	push   $0xf01060e4
f0102d49:	6a 58                	push   $0x58
f0102d4b:	68 81 70 10 f0       	push   $0xf0107081
f0102d50:	e8 eb d2 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d55:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d5c:	03 03 03 
f0102d5f:	74 19                	je     f0102d7a <mem_init+0x198e>
f0102d61:	68 e8 6f 10 f0       	push   $0xf0106fe8
f0102d66:	68 9b 70 10 f0       	push   $0xf010709b
f0102d6b:	68 e5 04 00 00       	push   $0x4e5
f0102d70:	68 75 70 10 f0       	push   $0xf0107075
f0102d75:	e8 c6 d2 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d7a:	83 ec 08             	sub    $0x8,%esp
f0102d7d:	68 00 10 00 00       	push   $0x1000
f0102d82:	ff 35 cc 9e 20 f0    	pushl  0xf0209ecc
f0102d88:	e8 21 e5 ff ff       	call   f01012ae <page_remove>
	assert(pp2->pp_ref == 0);
f0102d8d:	83 c4 10             	add    $0x10,%esp
f0102d90:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d95:	74 19                	je     f0102db0 <mem_init+0x19c4>
f0102d97:	68 e7 72 10 f0       	push   $0xf01072e7
f0102d9c:	68 9b 70 10 f0       	push   $0xf010709b
f0102da1:	68 e7 04 00 00       	push   $0x4e7
f0102da6:	68 75 70 10 f0       	push   $0xf0107075
f0102dab:	e8 90 d2 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102db0:	8b 0d cc 9e 20 f0    	mov    0xf0209ecc,%ecx
f0102db6:	8b 11                	mov    (%ecx),%edx
f0102db8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102dbe:	89 d8                	mov    %ebx,%eax
f0102dc0:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0102dc6:	c1 f8 03             	sar    $0x3,%eax
f0102dc9:	c1 e0 0c             	shl    $0xc,%eax
f0102dcc:	39 c2                	cmp    %eax,%edx
f0102dce:	74 19                	je     f0102de9 <mem_init+0x19fd>
f0102dd0:	68 70 69 10 f0       	push   $0xf0106970
f0102dd5:	68 9b 70 10 f0       	push   $0xf010709b
f0102dda:	68 ea 04 00 00       	push   $0x4ea
f0102ddf:	68 75 70 10 f0       	push   $0xf0107075
f0102de4:	e8 57 d2 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102de9:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102def:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102df4:	74 19                	je     f0102e0f <mem_init+0x1a23>
f0102df6:	68 9e 72 10 f0       	push   $0xf010729e
f0102dfb:	68 9b 70 10 f0       	push   $0xf010709b
f0102e00:	68 ec 04 00 00       	push   $0x4ec
f0102e05:	68 75 70 10 f0       	push   $0xf0107075
f0102e0a:	e8 31 d2 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102e0f:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e15:	83 ec 0c             	sub    $0xc,%esp
f0102e18:	53                   	push   %ebx
f0102e19:	e8 26 e2 ff ff       	call   f0101044 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e1e:	c7 04 24 14 70 10 f0 	movl   $0xf0107014,(%esp)
f0102e25:	e8 f7 09 00 00       	call   f0103821 <cprintf>
f0102e2a:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e2d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e30:	5b                   	pop    %ebx
f0102e31:	5e                   	pop    %esi
f0102e32:	5f                   	pop    %edi
f0102e33:	5d                   	pop    %ebp
f0102e34:	c3                   	ret    

f0102e35 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e35:	55                   	push   %ebp
f0102e36:	89 e5                	mov    %esp,%ebp
f0102e38:	57                   	push   %edi
f0102e39:	56                   	push   %esi
f0102e3a:	53                   	push   %ebx
f0102e3b:	83 ec 1c             	sub    $0x1c,%esp
f0102e3e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102e41:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0102e44:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102e47:	03 75 10             	add    0x10(%ebp),%esi
  if (va_beg >= ULIM || va_end >= ULIM) {
f0102e4a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e50:	77 09                	ja     f0102e5b <user_mem_check+0x26>
f0102e52:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f0102e59:	76 1f                	jbe    f0102e7a <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f0102e5b:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0102e62:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0102e67:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f0102e6b:	a3 60 92 20 f0       	mov    %eax,0xf0209260
    return -E_FAULT;
f0102e70:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e75:	e9 a7 00 00 00       	jmp    f0102f21 <user_mem_check+0xec>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f0102e7a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102e7d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0102e83:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0102e89:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e8f:	a1 c8 9e 20 f0       	mov    0xf0209ec8,%eax
f0102e94:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102e97:	89 7d 08             	mov    %edi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0102e9a:	eb 7c                	jmp    f0102f18 <user_mem_check+0xe3>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f0102e9c:	89 d1                	mov    %edx,%ecx
f0102e9e:	c1 e9 16             	shr    $0x16,%ecx
f0102ea1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ea4:	8b 40 60             	mov    0x60(%eax),%eax
f0102ea7:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102eaa:	a8 01                	test   $0x1,%al
f0102eac:	75 14                	jne    f0102ec2 <user_mem_check+0x8d>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102eae:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102eb1:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102eb5:	89 15 60 92 20 f0    	mov    %edx,0xf0209260
      return -E_FAULT;
f0102ebb:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ec0:	eb 5f                	jmp    f0102f21 <user_mem_check+0xec>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0102ec2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ec7:	89 c1                	mov    %eax,%ecx
f0102ec9:	c1 e9 0c             	shr    $0xc,%ecx
f0102ecc:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0102ecf:	72 15                	jb     f0102ee6 <user_mem_check+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ed1:	50                   	push   %eax
f0102ed2:	68 e4 60 10 f0       	push   $0xf01060e4
f0102ed7:	68 14 03 00 00       	push   $0x314
f0102edc:	68 75 70 10 f0       	push   $0xf0107075
f0102ee1:	e8 5a d1 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0102ee6:	89 d1                	mov    %edx,%ecx
f0102ee8:	c1 e9 0c             	shr    $0xc,%ecx
f0102eeb:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0102ef1:	89 df                	mov    %ebx,%edi
f0102ef3:	23 bc 88 00 00 00 f0 	and    -0x10000000(%eax,%ecx,4),%edi
f0102efa:	39 fb                	cmp    %edi,%ebx
f0102efc:	74 14                	je     f0102f12 <user_mem_check+0xdd>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102efe:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f01:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102f05:	89 15 60 92 20 f0    	mov    %edx,0xf0209260
      return -E_FAULT;
f0102f0b:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f10:	eb 0f                	jmp    f0102f21 <user_mem_check+0xec>
    }

    va_beg2 += PGSIZE;
f0102f12:	81 c2 00 10 00 00    	add    $0x1000,%edx
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0102f18:	39 f2                	cmp    %esi,%edx
f0102f1a:	72 80                	jb     f0102e9c <user_mem_check+0x67>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f0102f1c:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0102f21:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f24:	5b                   	pop    %ebx
f0102f25:	5e                   	pop    %esi
f0102f26:	5f                   	pop    %edi
f0102f27:	5d                   	pop    %ebp
f0102f28:	c3                   	ret    

f0102f29 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102f29:	55                   	push   %ebp
f0102f2a:	89 e5                	mov    %esp,%ebp
f0102f2c:	53                   	push   %ebx
f0102f2d:	83 ec 04             	sub    $0x4,%esp
f0102f30:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f33:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f36:	83 c8 04             	or     $0x4,%eax
f0102f39:	50                   	push   %eax
f0102f3a:	ff 75 10             	pushl  0x10(%ebp)
f0102f3d:	ff 75 0c             	pushl  0xc(%ebp)
f0102f40:	53                   	push   %ebx
f0102f41:	e8 ef fe ff ff       	call   f0102e35 <user_mem_check>
f0102f46:	83 c4 10             	add    $0x10,%esp
f0102f49:	85 c0                	test   %eax,%eax
f0102f4b:	79 21                	jns    f0102f6e <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f4d:	83 ec 04             	sub    $0x4,%esp
f0102f50:	ff 35 60 92 20 f0    	pushl  0xf0209260
f0102f56:	ff 73 48             	pushl  0x48(%ebx)
f0102f59:	68 40 70 10 f0       	push   $0xf0107040
f0102f5e:	e8 be 08 00 00       	call   f0103821 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f63:	89 1c 24             	mov    %ebx,(%esp)
f0102f66:	e8 ef 05 00 00       	call   f010355a <env_destroy>
f0102f6b:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f6e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f71:	c9                   	leave  
f0102f72:	c3                   	ret    

f0102f73 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f73:	55                   	push   %ebp
f0102f74:	89 e5                	mov    %esp,%ebp
f0102f76:	57                   	push   %edi
f0102f77:	56                   	push   %esi
f0102f78:	53                   	push   %ebx
f0102f79:	83 ec 0c             	sub    $0xc,%esp
f0102f7c:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102f7e:	89 d3                	mov    %edx,%ebx
f0102f80:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0102f86:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102f8d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0102f93:	eb 58                	jmp    f0102fed <region_alloc+0x7a>
		struct PageInfo *p = page_alloc(0);
f0102f95:	83 ec 0c             	sub    $0xc,%esp
f0102f98:	6a 00                	push   $0x0
f0102f9a:	e8 2f e0 ff ff       	call   f0100fce <page_alloc>
		if (p == NULL)
f0102f9f:	83 c4 10             	add    $0x10,%esp
f0102fa2:	85 c0                	test   %eax,%eax
f0102fa4:	75 17                	jne    f0102fbd <region_alloc+0x4a>
			panic("Page alloc failed!");
f0102fa6:	83 ec 04             	sub    $0x4,%esp
f0102fa9:	68 b4 73 10 f0       	push   $0xf01073b4
f0102fae:	68 35 01 00 00       	push   $0x135
f0102fb3:	68 c7 73 10 f0       	push   $0xf01073c7
f0102fb8:	e8 83 d0 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f0102fbd:	6a 06                	push   $0x6
f0102fbf:	53                   	push   %ebx
f0102fc0:	50                   	push   %eax
f0102fc1:	ff 77 60             	pushl  0x60(%edi)
f0102fc4:	e8 2b e3 ff ff       	call   f01012f4 <page_insert>
f0102fc9:	83 c4 10             	add    $0x10,%esp
f0102fcc:	85 c0                	test   %eax,%eax
f0102fce:	74 17                	je     f0102fe7 <region_alloc+0x74>
			panic("Page table couldn't be allocated!!");
f0102fd0:	83 ec 04             	sub    $0x4,%esp
f0102fd3:	68 0c 74 10 f0       	push   $0xf010740c
f0102fd8:	68 37 01 00 00       	push   $0x137
f0102fdd:	68 c7 73 10 f0       	push   $0xf01073c7
f0102fe2:	e8 59 d0 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f0102fe7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0102fed:	39 f3                	cmp    %esi,%ebx
f0102fef:	72 a4                	jb     f0102f95 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0102ff1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ff4:	5b                   	pop    %ebx
f0102ff5:	5e                   	pop    %esi
f0102ff6:	5f                   	pop    %edi
f0102ff7:	5d                   	pop    %ebp
f0102ff8:	c3                   	ret    

f0102ff9 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102ff9:	55                   	push   %ebp
f0102ffa:	89 e5                	mov    %esp,%ebp
f0102ffc:	56                   	push   %esi
f0102ffd:	53                   	push   %ebx
f0102ffe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103001:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103004:	85 c0                	test   %eax,%eax
f0103006:	75 1a                	jne    f0103022 <envid2env+0x29>
		*env_store = curenv;
f0103008:	e8 e2 29 00 00       	call   f01059ef <cpunum>
f010300d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103010:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103016:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103019:	89 01                	mov    %eax,(%ecx)
		return 0;
f010301b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103020:	eb 70                	jmp    f0103092 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103022:	89 c3                	mov    %eax,%ebx
f0103024:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010302a:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f010302d:	03 1d 6c 92 20 f0    	add    0xf020926c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103033:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103037:	74 05                	je     f010303e <envid2env+0x45>
f0103039:	39 43 48             	cmp    %eax,0x48(%ebx)
f010303c:	74 10                	je     f010304e <envid2env+0x55>
		*env_store = 0;
f010303e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103041:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103047:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010304c:	eb 44                	jmp    f0103092 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010304e:	84 d2                	test   %dl,%dl
f0103050:	74 36                	je     f0103088 <envid2env+0x8f>
f0103052:	e8 98 29 00 00       	call   f01059ef <cpunum>
f0103057:	6b c0 74             	imul   $0x74,%eax,%eax
f010305a:	39 98 48 a0 20 f0    	cmp    %ebx,-0xfdf5fb8(%eax)
f0103060:	74 26                	je     f0103088 <envid2env+0x8f>
f0103062:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103065:	e8 85 29 00 00       	call   f01059ef <cpunum>
f010306a:	6b c0 74             	imul   $0x74,%eax,%eax
f010306d:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103073:	3b 70 48             	cmp    0x48(%eax),%esi
f0103076:	74 10                	je     f0103088 <envid2env+0x8f>
		*env_store = 0;
f0103078:	8b 45 0c             	mov    0xc(%ebp),%eax
f010307b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103081:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103086:	eb 0a                	jmp    f0103092 <envid2env+0x99>
	}

	*env_store = e;
f0103088:	8b 45 0c             	mov    0xc(%ebp),%eax
f010308b:	89 18                	mov    %ebx,(%eax)
	return 0;
f010308d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103092:	5b                   	pop    %ebx
f0103093:	5e                   	pop    %esi
f0103094:	5d                   	pop    %ebp
f0103095:	c3                   	ret    

f0103096 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103096:	55                   	push   %ebp
f0103097:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103099:	b8 40 03 12 f0       	mov    $0xf0120340,%eax
f010309e:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01030a1:	b8 23 00 00 00       	mov    $0x23,%eax
f01030a6:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01030a8:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01030aa:	b0 10                	mov    $0x10,%al
f01030ac:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01030ae:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01030b0:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01030b2:	ea b9 30 10 f0 08 00 	ljmp   $0x8,$0xf01030b9
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01030b9:	b0 00                	mov    $0x0,%al
f01030bb:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01030be:	5d                   	pop    %ebp
f01030bf:	c3                   	ret    

f01030c0 <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f01030c0:	8b 0d 6c 92 20 f0    	mov    0xf020926c,%ecx
f01030c6:	8b 15 70 92 20 f0    	mov    0xf0209270,%edx
f01030cc:	89 c8                	mov    %ecx,%eax
f01030ce:	81 c1 00 f0 01 00    	add    $0x1f000,%ecx
f01030d4:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f01030db:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f01030e2:	85 d2                	test   %edx,%edx
f01030e4:	74 05                	je     f01030eb <env_init+0x2b>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f01030e6:	89 40 c8             	mov    %eax,-0x38(%eax)
f01030e9:	eb 02                	jmp    f01030ed <env_init+0x2d>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f01030eb:	89 c2                	mov    %eax,%edx
f01030ed:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f01030f0:	39 c8                	cmp    %ecx,%eax
f01030f2:	75 e0                	jne    f01030d4 <env_init+0x14>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01030f4:	55                   	push   %ebp
f01030f5:	89 e5                	mov    %esp,%ebp
f01030f7:	89 15 70 92 20 f0    	mov    %edx,0xf0209270
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f01030fd:	e8 94 ff ff ff       	call   f0103096 <env_init_percpu>
}
f0103102:	5d                   	pop    %ebp
f0103103:	c3                   	ret    

f0103104 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103104:	55                   	push   %ebp
f0103105:	89 e5                	mov    %esp,%ebp
f0103107:	53                   	push   %ebx
f0103108:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010310b:	8b 1d 70 92 20 f0    	mov    0xf0209270,%ebx
f0103111:	85 db                	test   %ebx,%ebx
f0103113:	0f 84 34 01 00 00    	je     f010324d <env_alloc+0x149>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103119:	83 ec 0c             	sub    $0xc,%esp
f010311c:	6a 01                	push   $0x1
f010311e:	e8 ab de ff ff       	call   f0100fce <page_alloc>
f0103123:	83 c4 10             	add    $0x10,%esp
f0103126:	85 c0                	test   %eax,%eax
f0103128:	0f 84 26 01 00 00    	je     f0103254 <env_alloc+0x150>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f010312e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103133:	2b 05 d0 9e 20 f0    	sub    0xf0209ed0,%eax
f0103139:	c1 f8 03             	sar    $0x3,%eax
f010313c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010313f:	89 c2                	mov    %eax,%edx
f0103141:	c1 ea 0c             	shr    $0xc,%edx
f0103144:	3b 15 c8 9e 20 f0    	cmp    0xf0209ec8,%edx
f010314a:	72 12                	jb     f010315e <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010314c:	50                   	push   %eax
f010314d:	68 e4 60 10 f0       	push   $0xf01060e4
f0103152:	6a 58                	push   $0x58
f0103154:	68 81 70 10 f0       	push   $0xf0107081
f0103159:	e8 e2 ce ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010315e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103163:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0103166:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f010316b:	8b 15 cc 9e 20 f0    	mov    0xf0209ecc,%edx
f0103171:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103174:	8b 53 60             	mov    0x60(%ebx),%edx
f0103177:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f010317a:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f010317d:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103182:	75 e7                	jne    f010316b <env_alloc+0x67>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103184:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103187:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010318c:	77 15                	ja     f01031a3 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010318e:	50                   	push   %eax
f010318f:	68 08 61 10 f0       	push   $0xf0106108
f0103194:	68 d0 00 00 00       	push   $0xd0
f0103199:	68 c7 73 10 f0       	push   $0xf01073c7
f010319e:	e8 9d ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01031a3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01031a9:	83 ca 05             	or     $0x5,%edx
f01031ac:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01031b2:	8b 43 48             	mov    0x48(%ebx),%eax
f01031b5:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01031ba:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01031bf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01031c4:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01031c7:	89 da                	mov    %ebx,%edx
f01031c9:	2b 15 6c 92 20 f0    	sub    0xf020926c,%edx
f01031cf:	c1 fa 02             	sar    $0x2,%edx
f01031d2:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01031d8:	09 d0                	or     %edx,%eax
f01031da:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01031dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031e0:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01031e3:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01031ea:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01031f1:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01031f8:	83 ec 04             	sub    $0x4,%esp
f01031fb:	6a 44                	push   $0x44
f01031fd:	6a 00                	push   $0x0
f01031ff:	53                   	push   %ebx
f0103200:	e8 c5 21 00 00       	call   f01053ca <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103205:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010320b:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103211:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103217:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010321e:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;  //Modification for exercise 13
f0103224:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f010322b:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103232:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103236:	8b 43 44             	mov    0x44(%ebx),%eax
f0103239:	a3 70 92 20 f0       	mov    %eax,0xf0209270
	*newenv_store = e;
f010323e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103241:	89 18                	mov    %ebx,(%eax)

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
f0103243:	83 c4 10             	add    $0x10,%esp
f0103246:	b8 00 00 00 00       	mov    $0x0,%eax
f010324b:	eb 0c                	jmp    f0103259 <env_alloc+0x155>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010324d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103252:	eb 05                	jmp    f0103259 <env_alloc+0x155>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103254:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103259:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010325c:	c9                   	leave  
f010325d:	c3                   	ret    

f010325e <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010325e:	55                   	push   %ebp
f010325f:	89 e5                	mov    %esp,%ebp
f0103261:	57                   	push   %edi
f0103262:	56                   	push   %esi
f0103263:	53                   	push   %ebx
f0103264:	83 ec 34             	sub    $0x34,%esp
f0103267:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f010326a:	6a 00                	push   $0x0
f010326c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010326f:	50                   	push   %eax
f0103270:	e8 8f fe ff ff       	call   f0103104 <env_alloc>
	if (r){
f0103275:	83 c4 10             	add    $0x10,%esp
f0103278:	85 c0                	test   %eax,%eax
f010327a:	74 15                	je     f0103291 <env_create+0x33>
	panic("env_alloc: %e", r);
f010327c:	50                   	push   %eax
f010327d:	68 d2 73 10 f0       	push   $0xf01073d2
f0103282:	68 b2 01 00 00       	push   $0x1b2
f0103287:	68 c7 73 10 f0       	push   $0xf01073c7
f010328c:	e8 af cd ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f0103291:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103294:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f0103297:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010329d:	74 17                	je     f01032b6 <env_create+0x58>
	{
		panic ("Not a valid ELF binary image");
f010329f:	83 ec 04             	sub    $0x4,%esp
f01032a2:	68 e0 73 10 f0       	push   $0xf01073e0
f01032a7:	68 81 01 00 00       	push   $0x181
f01032ac:	68 c7 73 10 f0       	push   $0xf01073c7
f01032b1:	e8 8a cd ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f01032b6:	89 fb                	mov    %edi,%ebx
f01032b8:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f01032bb:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01032bf:	c1 e6 05             	shl    $0x5,%esi
f01032c2:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f01032c4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032c7:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032ca:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032cf:	77 15                	ja     f01032e6 <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032d1:	50                   	push   %eax
f01032d2:	68 08 61 10 f0       	push   $0xf0106108
f01032d7:	68 88 01 00 00       	push   $0x188
f01032dc:	68 c7 73 10 f0       	push   $0xf01073c7
f01032e1:	e8 5a cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032e6:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01032eb:	0f 22 d8             	mov    %eax,%cr3
f01032ee:	eb 60                	jmp    f0103350 <env_create+0xf2>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f01032f0:	83 3b 01             	cmpl   $0x1,(%ebx)
f01032f3:	75 58                	jne    f010334d <env_create+0xef>
		
		if(ph->p_memsz < ph->p_filesz){
f01032f5:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01032f8:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f01032fb:	73 17                	jae    f0103314 <env_create+0xb6>
		panic ("Memory size is smaller than file size!!");
f01032fd:	83 ec 04             	sub    $0x4,%esp
f0103300:	68 30 74 10 f0       	push   $0xf0107430
f0103305:	68 8e 01 00 00       	push   $0x18e
f010330a:	68 c7 73 10 f0       	push   $0xf01073c7
f010330f:	e8 2c cd ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0103314:	8b 53 08             	mov    0x8(%ebx),%edx
f0103317:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010331a:	e8 54 fc ff ff       	call   f0102f73 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f010331f:	83 ec 04             	sub    $0x4,%esp
f0103322:	ff 73 10             	pushl  0x10(%ebx)
f0103325:	89 f8                	mov    %edi,%eax
f0103327:	03 43 04             	add    0x4(%ebx),%eax
f010332a:	50                   	push   %eax
f010332b:	ff 73 08             	pushl  0x8(%ebx)
f010332e:	e8 4c 21 00 00       	call   f010547f <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0103333:	8b 43 10             	mov    0x10(%ebx),%eax
f0103336:	83 c4 0c             	add    $0xc,%esp
f0103339:	8b 53 14             	mov    0x14(%ebx),%edx
f010333c:	29 c2                	sub    %eax,%edx
f010333e:	52                   	push   %edx
f010333f:	6a 00                	push   $0x0
f0103341:	03 43 08             	add    0x8(%ebx),%eax
f0103344:	50                   	push   %eax
f0103345:	e8 80 20 00 00       	call   f01053ca <memset>
f010334a:	83 c4 10             	add    $0x10,%esp
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f010334d:	83 c3 20             	add    $0x20,%ebx
f0103350:	39 de                	cmp    %ebx,%esi
f0103352:	77 9c                	ja     f01032f0 <env_create+0x92>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0103354:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103359:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010335e:	77 15                	ja     f0103375 <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103360:	50                   	push   %eax
f0103361:	68 08 61 10 f0       	push   $0xf0106108
f0103366:	68 9b 01 00 00       	push   $0x19b
f010336b:	68 c7 73 10 f0       	push   $0xf01073c7
f0103370:	e8 cb cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103375:	05 00 00 00 10       	add    $0x10000000,%eax
f010337a:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f010337d:	8b 47 18             	mov    0x18(%edi),%eax
f0103380:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103383:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0103386:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010338b:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103390:	89 f8                	mov    %edi,%eax
f0103392:	e8 dc fb ff ff       	call   f0102f73 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f0103397:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010339a:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010339d:	89 78 50             	mov    %edi,0x50(%eax)

	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
	//IOPL = IO privelege level, for this to be user accessible, the IOPL<=CPL, Since CPL =3 we set IOPL=3
	if (type == ENV_TYPE_FS) {
f01033a0:	83 ff 01             	cmp    $0x1,%edi
f01033a3:	75 07                	jne    f01033ac <env_create+0x14e>
		env->env_tf.tf_eflags |= FL_IOPL_3; //FL_IOPL_3 in inc/mmu.h
f01033a5:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
	}

}
f01033ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033af:	5b                   	pop    %ebx
f01033b0:	5e                   	pop    %esi
f01033b1:	5f                   	pop    %edi
f01033b2:	5d                   	pop    %ebp
f01033b3:	c3                   	ret    

f01033b4 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033b4:	55                   	push   %ebp
f01033b5:	89 e5                	mov    %esp,%ebp
f01033b7:	57                   	push   %edi
f01033b8:	56                   	push   %esi
f01033b9:	53                   	push   %ebx
f01033ba:	83 ec 1c             	sub    $0x1c,%esp
f01033bd:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033c0:	e8 2a 26 00 00       	call   f01059ef <cpunum>
f01033c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01033cf:	39 b8 48 a0 20 f0    	cmp    %edi,-0xfdf5fb8(%eax)
f01033d5:	75 30                	jne    f0103407 <env_free+0x53>
		lcr3(PADDR(kern_pgdir));
f01033d7:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033e1:	77 15                	ja     f01033f8 <env_free+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033e3:	50                   	push   %eax
f01033e4:	68 08 61 10 f0       	push   $0xf0106108
f01033e9:	68 d0 01 00 00       	push   $0x1d0
f01033ee:	68 c7 73 10 f0       	push   $0xf01073c7
f01033f3:	e8 48 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033f8:	05 00 00 00 10       	add    $0x10000000,%eax
f01033fd:	0f 22 d8             	mov    %eax,%cr3
f0103400:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103407:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010340a:	89 d0                	mov    %edx,%eax
f010340c:	c1 e0 02             	shl    $0x2,%eax
f010340f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103412:	8b 47 60             	mov    0x60(%edi),%eax
f0103415:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103418:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010341e:	0f 84 a8 00 00 00    	je     f01034cc <env_free+0x118>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103424:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010342a:	89 f0                	mov    %esi,%eax
f010342c:	c1 e8 0c             	shr    $0xc,%eax
f010342f:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103432:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f0103438:	72 15                	jb     f010344f <env_free+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010343a:	56                   	push   %esi
f010343b:	68 e4 60 10 f0       	push   $0xf01060e4
f0103440:	68 df 01 00 00       	push   $0x1df
f0103445:	68 c7 73 10 f0       	push   $0xf01073c7
f010344a:	e8 f1 cb ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010344f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103452:	c1 e0 16             	shl    $0x16,%eax
f0103455:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103458:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010345d:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103464:	01 
f0103465:	74 17                	je     f010347e <env_free+0xca>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103467:	83 ec 08             	sub    $0x8,%esp
f010346a:	89 d8                	mov    %ebx,%eax
f010346c:	c1 e0 0c             	shl    $0xc,%eax
f010346f:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103472:	50                   	push   %eax
f0103473:	ff 77 60             	pushl  0x60(%edi)
f0103476:	e8 33 de ff ff       	call   f01012ae <page_remove>
f010347b:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010347e:	83 c3 01             	add    $0x1,%ebx
f0103481:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103487:	75 d4                	jne    f010345d <env_free+0xa9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103489:	8b 47 60             	mov    0x60(%edi),%eax
f010348c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010348f:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103496:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103499:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f010349f:	72 14                	jb     f01034b5 <env_free+0x101>
		panic("pa2page called with invalid pa");
f01034a1:	83 ec 04             	sub    $0x4,%esp
f01034a4:	68 58 74 10 f0       	push   $0xf0107458
f01034a9:	6a 51                	push   $0x51
f01034ab:	68 81 70 10 f0       	push   $0xf0107081
f01034b0:	e8 8b cb ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01034b5:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034b8:	a1 d0 9e 20 f0       	mov    0xf0209ed0,%eax
f01034bd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034c0:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01034c3:	50                   	push   %eax
f01034c4:	e8 cc db ff ff       	call   f0101095 <page_decref>
f01034c9:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	// cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034cc:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01034d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034d3:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01034d8:	0f 85 29 ff ff ff    	jne    f0103407 <env_free+0x53>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01034de:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034e1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034e6:	77 15                	ja     f01034fd <env_free+0x149>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034e8:	50                   	push   %eax
f01034e9:	68 08 61 10 f0       	push   $0xf0106108
f01034ee:	68 ed 01 00 00       	push   $0x1ed
f01034f3:	68 c7 73 10 f0       	push   $0xf01073c7
f01034f8:	e8 43 cb ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f01034fd:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103504:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103509:	c1 e8 0c             	shr    $0xc,%eax
f010350c:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f0103512:	72 14                	jb     f0103528 <env_free+0x174>
		panic("pa2page called with invalid pa");
f0103514:	83 ec 04             	sub    $0x4,%esp
f0103517:	68 58 74 10 f0       	push   $0xf0107458
f010351c:	6a 51                	push   $0x51
f010351e:	68 81 70 10 f0       	push   $0xf0107081
f0103523:	e8 18 cb ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103528:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010352b:	8b 15 d0 9e 20 f0    	mov    0xf0209ed0,%edx
f0103531:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103534:	50                   	push   %eax
f0103535:	e8 5b db ff ff       	call   f0101095 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010353a:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103541:	a1 70 92 20 f0       	mov    0xf0209270,%eax
f0103546:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103549:	89 3d 70 92 20 f0    	mov    %edi,0xf0209270
f010354f:	83 c4 10             	add    $0x10,%esp
}
f0103552:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103555:	5b                   	pop    %ebx
f0103556:	5e                   	pop    %esi
f0103557:	5f                   	pop    %edi
f0103558:	5d                   	pop    %ebp
f0103559:	c3                   	ret    

f010355a <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f010355a:	55                   	push   %ebp
f010355b:	89 e5                	mov    %esp,%ebp
f010355d:	53                   	push   %ebx
f010355e:	83 ec 04             	sub    $0x4,%esp
f0103561:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103564:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103568:	75 19                	jne    f0103583 <env_destroy+0x29>
f010356a:	e8 80 24 00 00       	call   f01059ef <cpunum>
f010356f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103572:	39 98 48 a0 20 f0    	cmp    %ebx,-0xfdf5fb8(%eax)
f0103578:	74 09                	je     f0103583 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f010357a:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103581:	eb 33                	jmp    f01035b6 <env_destroy+0x5c>
	}

	env_free(e);
f0103583:	83 ec 0c             	sub    $0xc,%esp
f0103586:	53                   	push   %ebx
f0103587:	e8 28 fe ff ff       	call   f01033b4 <env_free>

	if (curenv == e) {
f010358c:	e8 5e 24 00 00       	call   f01059ef <cpunum>
f0103591:	6b c0 74             	imul   $0x74,%eax,%eax
f0103594:	83 c4 10             	add    $0x10,%esp
f0103597:	39 98 48 a0 20 f0    	cmp    %ebx,-0xfdf5fb8(%eax)
f010359d:	75 17                	jne    f01035b6 <env_destroy+0x5c>
		curenv = NULL;
f010359f:	e8 4b 24 00 00       	call   f01059ef <cpunum>
f01035a4:	6b c0 74             	imul   $0x74,%eax,%eax
f01035a7:	c7 80 48 a0 20 f0 00 	movl   $0x0,-0xfdf5fb8(%eax)
f01035ae:	00 00 00 
		sched_yield();
f01035b1:	e8 20 0c 00 00       	call   f01041d6 <sched_yield>
	}
}
f01035b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035b9:	c9                   	leave  
f01035ba:	c3                   	ret    

f01035bb <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035bb:	55                   	push   %ebp
f01035bc:	89 e5                	mov    %esp,%ebp
f01035be:	53                   	push   %ebx
f01035bf:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01035c2:	e8 28 24 00 00       	call   f01059ef <cpunum>
f01035c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01035ca:	8b 98 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%ebx
f01035d0:	e8 1a 24 00 00       	call   f01059ef <cpunum>
f01035d5:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01035d8:	8b 65 08             	mov    0x8(%ebp),%esp
f01035db:	61                   	popa   
f01035dc:	07                   	pop    %es
f01035dd:	1f                   	pop    %ds
f01035de:	83 c4 08             	add    $0x8,%esp
f01035e1:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01035e2:	83 ec 04             	sub    $0x4,%esp
f01035e5:	68 fd 73 10 f0       	push   $0xf01073fd
f01035ea:	68 23 02 00 00       	push   $0x223
f01035ef:	68 c7 73 10 f0       	push   $0xf01073c7
f01035f4:	e8 47 ca ff ff       	call   f0100040 <_panic>

f01035f9 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01035f9:	55                   	push   %ebp
f01035fa:	89 e5                	mov    %esp,%ebp
f01035fc:	53                   	push   %ebx
f01035fd:	83 ec 04             	sub    $0x4,%esp
f0103600:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103603:	e8 e7 23 00 00       	call   f01059ef <cpunum>
f0103608:	6b c0 74             	imul   $0x74,%eax,%eax
f010360b:	83 b8 48 a0 20 f0 00 	cmpl   $0x0,-0xfdf5fb8(%eax)
f0103612:	75 10                	jne    f0103624 <env_run+0x2b>
	curenv = e;
f0103614:	e8 d6 23 00 00       	call   f01059ef <cpunum>
f0103619:	6b c0 74             	imul   $0x74,%eax,%eax
f010361c:	89 98 48 a0 20 f0    	mov    %ebx,-0xfdf5fb8(%eax)
f0103622:	eb 29                	jmp    f010364d <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103624:	e8 c6 23 00 00       	call   f01059ef <cpunum>
f0103629:	6b c0 74             	imul   $0x74,%eax,%eax
f010362c:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103632:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103636:	75 15                	jne    f010364d <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f0103638:	e8 b2 23 00 00       	call   f01059ef <cpunum>
f010363d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103640:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103646:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f010364d:	e8 9d 23 00 00       	call   f01059ef <cpunum>
f0103652:	6b c0 74             	imul   $0x74,%eax,%eax
f0103655:	89 98 48 a0 20 f0    	mov    %ebx,-0xfdf5fb8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f010365b:	e8 8f 23 00 00       	call   f01059ef <cpunum>
f0103660:	6b c0 74             	imul   $0x74,%eax,%eax
f0103663:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103669:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f0103670:	e8 7a 23 00 00       	call   f01059ef <cpunum>
f0103675:	6b c0 74             	imul   $0x74,%eax,%eax
f0103678:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f010367e:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f0103682:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103685:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010368a:	77 15                	ja     f01036a1 <env_run+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010368c:	50                   	push   %eax
f010368d:	68 08 61 10 f0       	push   $0xf0106108
f0103692:	68 4f 02 00 00       	push   $0x24f
f0103697:	68 c7 73 10 f0       	push   $0xf01073c7
f010369c:	e8 9f c9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036a1:	05 00 00 00 10       	add    $0x10000000,%eax
f01036a6:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01036a9:	83 ec 0c             	sub    $0xc,%esp
f01036ac:	68 c0 04 12 f0       	push   $0xf01204c0
f01036b1:	e8 41 26 00 00       	call   f0105cf7 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01036b6:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01036b8:	89 1c 24             	mov    %ebx,(%esp)
f01036bb:	e8 fb fe ff ff       	call   f01035bb <env_pop_tf>

f01036c0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036c0:	55                   	push   %ebp
f01036c1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036c3:	ba 70 00 00 00       	mov    $0x70,%edx
f01036c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01036cb:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036cc:	b2 71                	mov    $0x71,%dl
f01036ce:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01036cf:	0f b6 c0             	movzbl %al,%eax
}
f01036d2:	5d                   	pop    %ebp
f01036d3:	c3                   	ret    

f01036d4 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01036d4:	55                   	push   %ebp
f01036d5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036d7:	ba 70 00 00 00       	mov    $0x70,%edx
f01036dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01036df:	ee                   	out    %al,(%dx)
f01036e0:	b2 71                	mov    $0x71,%dl
f01036e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036e5:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01036e6:	5d                   	pop    %ebp
f01036e7:	c3                   	ret    

f01036e8 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01036e8:	55                   	push   %ebp
f01036e9:	89 e5                	mov    %esp,%ebp
f01036eb:	56                   	push   %esi
f01036ec:	53                   	push   %ebx
f01036ed:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01036f0:	66 a3 e8 03 12 f0    	mov    %ax,0xf01203e8
	if (!didinit)
f01036f6:	80 3d 74 92 20 f0 00 	cmpb   $0x0,0xf0209274
f01036fd:	74 57                	je     f0103756 <irq_setmask_8259A+0x6e>
f01036ff:	89 c6                	mov    %eax,%esi
f0103701:	ba 21 00 00 00       	mov    $0x21,%edx
f0103706:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103707:	66 c1 e8 08          	shr    $0x8,%ax
f010370b:	b2 a1                	mov    $0xa1,%dl
f010370d:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f010370e:	83 ec 0c             	sub    $0xc,%esp
f0103711:	68 77 74 10 f0       	push   $0xf0107477
f0103716:	e8 06 01 00 00       	call   f0103821 <cprintf>
f010371b:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010371e:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103723:	0f b7 f6             	movzwl %si,%esi
f0103726:	f7 d6                	not    %esi
f0103728:	0f a3 de             	bt     %ebx,%esi
f010372b:	73 11                	jae    f010373e <irq_setmask_8259A+0x56>
			cprintf(" %d", i);
f010372d:	83 ec 08             	sub    $0x8,%esp
f0103730:	53                   	push   %ebx
f0103731:	68 93 79 10 f0       	push   $0xf0107993
f0103736:	e8 e6 00 00 00       	call   f0103821 <cprintf>
f010373b:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010373e:	83 c3 01             	add    $0x1,%ebx
f0103741:	83 fb 10             	cmp    $0x10,%ebx
f0103744:	75 e2                	jne    f0103728 <irq_setmask_8259A+0x40>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103746:	83 ec 0c             	sub    $0xc,%esp
f0103749:	68 ee 78 10 f0       	push   $0xf01078ee
f010374e:	e8 ce 00 00 00       	call   f0103821 <cprintf>
f0103753:	83 c4 10             	add    $0x10,%esp
}
f0103756:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103759:	5b                   	pop    %ebx
f010375a:	5e                   	pop    %esi
f010375b:	5d                   	pop    %ebp
f010375c:	c3                   	ret    

f010375d <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010375d:	c6 05 74 92 20 f0 01 	movb   $0x1,0xf0209274
f0103764:	ba 21 00 00 00       	mov    $0x21,%edx
f0103769:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010376e:	ee                   	out    %al,(%dx)
f010376f:	b2 a1                	mov    $0xa1,%dl
f0103771:	ee                   	out    %al,(%dx)
f0103772:	b2 20                	mov    $0x20,%dl
f0103774:	b8 11 00 00 00       	mov    $0x11,%eax
f0103779:	ee                   	out    %al,(%dx)
f010377a:	b2 21                	mov    $0x21,%dl
f010377c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103781:	ee                   	out    %al,(%dx)
f0103782:	b8 04 00 00 00       	mov    $0x4,%eax
f0103787:	ee                   	out    %al,(%dx)
f0103788:	b8 03 00 00 00       	mov    $0x3,%eax
f010378d:	ee                   	out    %al,(%dx)
f010378e:	b2 a0                	mov    $0xa0,%dl
f0103790:	b8 11 00 00 00       	mov    $0x11,%eax
f0103795:	ee                   	out    %al,(%dx)
f0103796:	b2 a1                	mov    $0xa1,%dl
f0103798:	b8 28 00 00 00       	mov    $0x28,%eax
f010379d:	ee                   	out    %al,(%dx)
f010379e:	b8 02 00 00 00       	mov    $0x2,%eax
f01037a3:	ee                   	out    %al,(%dx)
f01037a4:	b8 01 00 00 00       	mov    $0x1,%eax
f01037a9:	ee                   	out    %al,(%dx)
f01037aa:	b2 20                	mov    $0x20,%dl
f01037ac:	b8 68 00 00 00       	mov    $0x68,%eax
f01037b1:	ee                   	out    %al,(%dx)
f01037b2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037b7:	ee                   	out    %al,(%dx)
f01037b8:	b2 a0                	mov    $0xa0,%dl
f01037ba:	b8 68 00 00 00       	mov    $0x68,%eax
f01037bf:	ee                   	out    %al,(%dx)
f01037c0:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037c5:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01037c6:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f01037cd:	66 83 f8 ff          	cmp    $0xffff,%ax
f01037d1:	74 13                	je     f01037e6 <pic_init+0x89>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01037d3:	55                   	push   %ebp
f01037d4:	89 e5                	mov    %esp,%ebp
f01037d6:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01037d9:	0f b7 c0             	movzwl %ax,%eax
f01037dc:	50                   	push   %eax
f01037dd:	e8 06 ff ff ff       	call   f01036e8 <irq_setmask_8259A>
f01037e2:	83 c4 10             	add    $0x10,%esp
}
f01037e5:	c9                   	leave  
f01037e6:	f3 c3                	repz ret 

f01037e8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01037e8:	55                   	push   %ebp
f01037e9:	89 e5                	mov    %esp,%ebp
f01037eb:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01037ee:	ff 75 08             	pushl  0x8(%ebp)
f01037f1:	e8 84 cf ff ff       	call   f010077a <cputchar>
f01037f6:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01037f9:	c9                   	leave  
f01037fa:	c3                   	ret    

f01037fb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01037fb:	55                   	push   %ebp
f01037fc:	89 e5                	mov    %esp,%ebp
f01037fe:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103801:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103808:	ff 75 0c             	pushl  0xc(%ebp)
f010380b:	ff 75 08             	pushl  0x8(%ebp)
f010380e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103811:	50                   	push   %eax
f0103812:	68 e8 37 10 f0       	push   $0xf01037e8
f0103817:	e8 23 15 00 00       	call   f0104d3f <vprintfmt>
	return cnt;
}
f010381c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010381f:	c9                   	leave  
f0103820:	c3                   	ret    

f0103821 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103821:	55                   	push   %ebp
f0103822:	89 e5                	mov    %esp,%ebp
f0103824:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103827:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010382a:	50                   	push   %eax
f010382b:	ff 75 08             	pushl  0x8(%ebp)
f010382e:	e8 c8 ff ff ff       	call   f01037fb <vcprintf>
	va_end(ap);

	return cnt;
}
f0103833:	c9                   	leave  
f0103834:	c3                   	ret    

f0103835 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103835:	55                   	push   %ebp
f0103836:	89 e5                	mov    %esp,%ebp
f0103838:	56                   	push   %esi
f0103839:	53                   	push   %ebx
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	
	int i = cpunum();
f010383a:	e8 b0 21 00 00       	call   f01059ef <cpunum>
f010383f:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f0103841:	e8 a9 21 00 00       	call   f01059ef <cpunum>
f0103846:	89 c6                	mov    %eax,%esi
f0103848:	e8 a2 21 00 00       	call   f01059ef <cpunum>
f010384d:	6b f6 74             	imul   $0x74,%esi,%esi
f0103850:	c1 e0 0f             	shl    $0xf,%eax
f0103853:	8d 80 00 30 21 f0    	lea    -0xfded000(%eax),%eax
f0103859:	89 86 50 a0 20 f0    	mov    %eax,-0xfdf5fb0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010385f:	e8 8b 21 00 00       	call   f01059ef <cpunum>
f0103864:	6b c0 74             	imul   $0x74,%eax,%eax
f0103867:	66 c7 80 54 a0 20 f0 	movw   $0x10,-0xfdf5fac(%eax)
f010386e:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f0103870:	8d 43 05             	lea    0x5(%ebx),%eax
f0103873:	6b d3 74             	imul   $0x74,%ebx,%edx
f0103876:	81 c2 4c a0 20 f0    	add    $0xf020a04c,%edx
f010387c:	66 c7 04 c5 80 03 12 	movw   $0x67,-0xfedfc80(,%eax,8)
f0103883:	f0 67 00 
f0103886:	66 89 14 c5 82 03 12 	mov    %dx,-0xfedfc7e(,%eax,8)
f010388d:	f0 
f010388e:	89 d1                	mov    %edx,%ecx
f0103890:	c1 e9 10             	shr    $0x10,%ecx
f0103893:	88 0c c5 84 03 12 f0 	mov    %cl,-0xfedfc7c(,%eax,8)
f010389a:	c6 04 c5 86 03 12 f0 	movb   $0x40,-0xfedfc7a(,%eax,8)
f01038a1:	40 
f01038a2:	c1 ea 18             	shr    $0x18,%edx
f01038a5:	88 14 c5 87 03 12 f0 	mov    %dl,-0xfedfc79(,%eax,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f01038ac:	c6 04 c5 85 03 12 f0 	movb   $0x89,-0xfedfc7b(,%eax,8)
f01038b3:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f01038b4:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038bb:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038be:	b8 ea 03 12 f0       	mov    $0xf01203ea,%eax
f01038c3:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f01038c6:	5b                   	pop    %ebx
f01038c7:	5e                   	pop    %esi
f01038c8:	5d                   	pop    %ebp
f01038c9:	c3                   	ret    

f01038ca <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f01038ca:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f01038cf:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f01038d6:	66 89 14 c5 80 92 20 	mov    %dx,-0xfdf6d80(,%eax,8)
f01038dd:	f0 
f01038de:	66 c7 04 c5 82 92 20 	movw   $0x8,-0xfdf6d7e(,%eax,8)
f01038e5:	f0 08 00 
f01038e8:	c6 04 c5 84 92 20 f0 	movb   $0x0,-0xfdf6d7c(,%eax,8)
f01038ef:	00 
f01038f0:	c6 04 c5 85 92 20 f0 	movb   $0x8e,-0xfdf6d7b(,%eax,8)
f01038f7:	8e 
f01038f8:	c1 ea 10             	shr    $0x10,%edx
f01038fb:	66 89 14 c5 86 92 20 	mov    %dx,-0xfdf6d7a(,%eax,8)
f0103902:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f0103903:	83 c0 01             	add    $0x1,%eax
f0103906:	83 f8 14             	cmp    $0x14,%eax
f0103909:	75 c4                	jne    f01038cf <trap_init+0x5>
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f010390b:	a1 fc 03 12 f0       	mov    0xf01203fc,%eax
f0103910:	66 a3 98 92 20 f0    	mov    %ax,0xf0209298
f0103916:	66 c7 05 9a 92 20 f0 	movw   $0x8,0xf020929a
f010391d:	08 00 
f010391f:	c6 05 9c 92 20 f0 00 	movb   $0x0,0xf020929c
f0103926:	c6 05 9d 92 20 f0 ee 	movb   $0xee,0xf020929d
f010392d:	c1 e8 10             	shr    $0x10,%eax
f0103930:	66 a3 9e 92 20 f0    	mov    %ax,0xf020929e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f0103936:	a1 b0 04 12 f0       	mov    0xf01204b0,%eax
f010393b:	66 a3 00 94 20 f0    	mov    %ax,0xf0209400
f0103941:	66 c7 05 02 94 20 f0 	movw   $0x8,0xf0209402
f0103948:	08 00 
f010394a:	c6 05 04 94 20 f0 00 	movb   $0x0,0xf0209404
f0103951:	c6 05 05 94 20 f0 ee 	movb   $0xee,0xf0209405
f0103958:	c1 e8 10             	shr    $0x10,%eax
f010395b:	66 a3 06 94 20 f0    	mov    %ax,0xf0209406
f0103961:	b8 20 00 00 00       	mov    $0x20,%eax

	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);
f0103966:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f010396d:	66 89 14 c5 80 92 20 	mov    %dx,-0xfdf6d80(,%eax,8)
f0103974:	f0 
f0103975:	66 c7 04 c5 82 92 20 	movw   $0x8,-0xfdf6d7e(,%eax,8)
f010397c:	f0 08 00 
f010397f:	c6 04 c5 84 92 20 f0 	movb   $0x0,-0xfdf6d7c(,%eax,8)
f0103986:	00 
f0103987:	c6 04 c5 85 92 20 f0 	movb   $0xee,-0xfdf6d7b(,%eax,8)
f010398e:	ee 
f010398f:	c1 ea 10             	shr    $0x10,%edx
f0103992:	66 89 14 c5 86 92 20 	mov    %dx,-0xfdf6d7a(,%eax,8)
f0103999:	f0 
f010399a:	83 c0 01             	add    $0x1,%eax

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3

	//For IRQ interrupts
	for(j=0;j<16;j++)
f010399d:	83 f8 30             	cmp    $0x30,%eax
f01039a0:	75 c4                	jne    f0103966 <trap_init+0x9c>
}


void
trap_init(void)
{
f01039a2:	55                   	push   %ebp
f01039a3:	89 e5                	mov    %esp,%ebp
f01039a5:	83 ec 08             	sub    $0x8,%esp
	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);

	// Per-CPU setup 
	trap_init_percpu();
f01039a8:	e8 88 fe ff ff       	call   f0103835 <trap_init_percpu>
}
f01039ad:	c9                   	leave  
f01039ae:	c3                   	ret    

f01039af <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039af:	55                   	push   %ebp
f01039b0:	89 e5                	mov    %esp,%ebp
f01039b2:	53                   	push   %ebx
f01039b3:	83 ec 0c             	sub    $0xc,%esp
f01039b6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039b9:	ff 33                	pushl  (%ebx)
f01039bb:	68 8b 74 10 f0       	push   $0xf010748b
f01039c0:	e8 5c fe ff ff       	call   f0103821 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039c5:	83 c4 08             	add    $0x8,%esp
f01039c8:	ff 73 04             	pushl  0x4(%ebx)
f01039cb:	68 9a 74 10 f0       	push   $0xf010749a
f01039d0:	e8 4c fe ff ff       	call   f0103821 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01039d5:	83 c4 08             	add    $0x8,%esp
f01039d8:	ff 73 08             	pushl  0x8(%ebx)
f01039db:	68 a9 74 10 f0       	push   $0xf01074a9
f01039e0:	e8 3c fe ff ff       	call   f0103821 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01039e5:	83 c4 08             	add    $0x8,%esp
f01039e8:	ff 73 0c             	pushl  0xc(%ebx)
f01039eb:	68 b8 74 10 f0       	push   $0xf01074b8
f01039f0:	e8 2c fe ff ff       	call   f0103821 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01039f5:	83 c4 08             	add    $0x8,%esp
f01039f8:	ff 73 10             	pushl  0x10(%ebx)
f01039fb:	68 c7 74 10 f0       	push   $0xf01074c7
f0103a00:	e8 1c fe ff ff       	call   f0103821 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a05:	83 c4 08             	add    $0x8,%esp
f0103a08:	ff 73 14             	pushl  0x14(%ebx)
f0103a0b:	68 d6 74 10 f0       	push   $0xf01074d6
f0103a10:	e8 0c fe ff ff       	call   f0103821 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a15:	83 c4 08             	add    $0x8,%esp
f0103a18:	ff 73 18             	pushl  0x18(%ebx)
f0103a1b:	68 e5 74 10 f0       	push   $0xf01074e5
f0103a20:	e8 fc fd ff ff       	call   f0103821 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a25:	83 c4 08             	add    $0x8,%esp
f0103a28:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a2b:	68 f4 74 10 f0       	push   $0xf01074f4
f0103a30:	e8 ec fd ff ff       	call   f0103821 <cprintf>
f0103a35:	83 c4 10             	add    $0x10,%esp
}
f0103a38:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a3b:	c9                   	leave  
f0103a3c:	c3                   	ret    

f0103a3d <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f0103a3d:	55                   	push   %ebp
f0103a3e:	89 e5                	mov    %esp,%ebp
f0103a40:	56                   	push   %esi
f0103a41:	53                   	push   %ebx
f0103a42:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a45:	e8 a5 1f 00 00       	call   f01059ef <cpunum>
f0103a4a:	83 ec 04             	sub    $0x4,%esp
f0103a4d:	50                   	push   %eax
f0103a4e:	53                   	push   %ebx
f0103a4f:	68 58 75 10 f0       	push   $0xf0107558
f0103a54:	e8 c8 fd ff ff       	call   f0103821 <cprintf>
	print_regs(&tf->tf_regs);
f0103a59:	89 1c 24             	mov    %ebx,(%esp)
f0103a5c:	e8 4e ff ff ff       	call   f01039af <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a61:	83 c4 08             	add    $0x8,%esp
f0103a64:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a68:	50                   	push   %eax
f0103a69:	68 76 75 10 f0       	push   $0xf0107576
f0103a6e:	e8 ae fd ff ff       	call   f0103821 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103a73:	83 c4 08             	add    $0x8,%esp
f0103a76:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103a7a:	50                   	push   %eax
f0103a7b:	68 89 75 10 f0       	push   $0xf0107589
f0103a80:	e8 9c fd ff ff       	call   f0103821 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103a85:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103a88:	83 c4 10             	add    $0x10,%esp
f0103a8b:	83 f8 13             	cmp    $0x13,%eax
f0103a8e:	77 09                	ja     f0103a99 <print_trapframe+0x5c>
		return excnames[trapno];
f0103a90:	8b 14 85 40 78 10 f0 	mov    -0xfef87c0(,%eax,4),%edx
f0103a97:	eb 1f                	jmp    f0103ab8 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103a99:	83 f8 30             	cmp    $0x30,%eax
f0103a9c:	74 15                	je     f0103ab3 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103a9e:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103aa1:	83 fa 10             	cmp    $0x10,%edx
f0103aa4:	b9 22 75 10 f0       	mov    $0xf0107522,%ecx
f0103aa9:	ba 0f 75 10 f0       	mov    $0xf010750f,%edx
f0103aae:	0f 43 d1             	cmovae %ecx,%edx
f0103ab1:	eb 05                	jmp    f0103ab8 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103ab3:	ba 03 75 10 f0       	mov    $0xf0107503,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ab8:	83 ec 04             	sub    $0x4,%esp
f0103abb:	52                   	push   %edx
f0103abc:	50                   	push   %eax
f0103abd:	68 9c 75 10 f0       	push   $0xf010759c
f0103ac2:	e8 5a fd ff ff       	call   f0103821 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103ac7:	83 c4 10             	add    $0x10,%esp
f0103aca:	3b 1d 80 9a 20 f0    	cmp    0xf0209a80,%ebx
f0103ad0:	75 1a                	jne    f0103aec <print_trapframe+0xaf>
f0103ad2:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ad6:	75 14                	jne    f0103aec <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103ad8:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103adb:	83 ec 08             	sub    $0x8,%esp
f0103ade:	50                   	push   %eax
f0103adf:	68 ae 75 10 f0       	push   $0xf01075ae
f0103ae4:	e8 38 fd ff ff       	call   f0103821 <cprintf>
f0103ae9:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103aec:	83 ec 08             	sub    $0x8,%esp
f0103aef:	ff 73 2c             	pushl  0x2c(%ebx)
f0103af2:	68 bd 75 10 f0       	push   $0xf01075bd
f0103af7:	e8 25 fd ff ff       	call   f0103821 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103afc:	83 c4 10             	add    $0x10,%esp
f0103aff:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b03:	75 49                	jne    f0103b4e <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b05:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b08:	89 c2                	mov    %eax,%edx
f0103b0a:	83 e2 01             	and    $0x1,%edx
f0103b0d:	ba 3c 75 10 f0       	mov    $0xf010753c,%edx
f0103b12:	b9 31 75 10 f0       	mov    $0xf0107531,%ecx
f0103b17:	0f 44 ca             	cmove  %edx,%ecx
f0103b1a:	89 c2                	mov    %eax,%edx
f0103b1c:	83 e2 02             	and    $0x2,%edx
f0103b1f:	ba 4e 75 10 f0       	mov    $0xf010754e,%edx
f0103b24:	be 48 75 10 f0       	mov    $0xf0107548,%esi
f0103b29:	0f 45 d6             	cmovne %esi,%edx
f0103b2c:	83 e0 04             	and    $0x4,%eax
f0103b2f:	be a4 76 10 f0       	mov    $0xf01076a4,%esi
f0103b34:	b8 53 75 10 f0       	mov    $0xf0107553,%eax
f0103b39:	0f 44 c6             	cmove  %esi,%eax
f0103b3c:	51                   	push   %ecx
f0103b3d:	52                   	push   %edx
f0103b3e:	50                   	push   %eax
f0103b3f:	68 cb 75 10 f0       	push   $0xf01075cb
f0103b44:	e8 d8 fc ff ff       	call   f0103821 <cprintf>
f0103b49:	83 c4 10             	add    $0x10,%esp
f0103b4c:	eb 10                	jmp    f0103b5e <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b4e:	83 ec 0c             	sub    $0xc,%esp
f0103b51:	68 ee 78 10 f0       	push   $0xf01078ee
f0103b56:	e8 c6 fc ff ff       	call   f0103821 <cprintf>
f0103b5b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b5e:	83 ec 08             	sub    $0x8,%esp
f0103b61:	ff 73 30             	pushl  0x30(%ebx)
f0103b64:	68 da 75 10 f0       	push   $0xf01075da
f0103b69:	e8 b3 fc ff ff       	call   f0103821 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b6e:	83 c4 08             	add    $0x8,%esp
f0103b71:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103b75:	50                   	push   %eax
f0103b76:	68 e9 75 10 f0       	push   $0xf01075e9
f0103b7b:	e8 a1 fc ff ff       	call   f0103821 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103b80:	83 c4 08             	add    $0x8,%esp
f0103b83:	ff 73 38             	pushl  0x38(%ebx)
f0103b86:	68 fc 75 10 f0       	push   $0xf01075fc
f0103b8b:	e8 91 fc ff ff       	call   f0103821 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103b90:	83 c4 10             	add    $0x10,%esp
f0103b93:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103b97:	74 25                	je     f0103bbe <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103b99:	83 ec 08             	sub    $0x8,%esp
f0103b9c:	ff 73 3c             	pushl  0x3c(%ebx)
f0103b9f:	68 0b 76 10 f0       	push   $0xf010760b
f0103ba4:	e8 78 fc ff ff       	call   f0103821 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103ba9:	83 c4 08             	add    $0x8,%esp
f0103bac:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103bb0:	50                   	push   %eax
f0103bb1:	68 1a 76 10 f0       	push   $0xf010761a
f0103bb6:	e8 66 fc ff ff       	call   f0103821 <cprintf>
f0103bbb:	83 c4 10             	add    $0x10,%esp
	}
}
f0103bbe:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103bc1:	5b                   	pop    %ebx
f0103bc2:	5e                   	pop    %esi
f0103bc3:	5d                   	pop    %ebp
f0103bc4:	c3                   	ret    

f0103bc5 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bc5:	55                   	push   %ebp
f0103bc6:	89 e5                	mov    %esp,%ebp
f0103bc8:	57                   	push   %edi
f0103bc9:	56                   	push   %esi
f0103bca:	53                   	push   %ebx
f0103bcb:	83 ec 1c             	sub    $0x1c,%esp
f0103bce:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103bd1:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103bd4:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103bd8:	75 15                	jne    f0103bef <page_fault_handler+0x2a>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103bda:	56                   	push   %esi
f0103bdb:	68 f0 77 10 f0       	push   $0xf01077f0
f0103be0:	68 57 01 00 00       	push   $0x157
f0103be5:	68 2d 76 10 f0       	push   $0xf010762d
f0103bea:	e8 51 c4 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	//Store the current env's stack tf_esp for use, if the call occurs inside UXtrapframe  
	const uint32_t cur_tf_esp_addr = (uint32_t)(tf->tf_esp); 	// trap-time esp
f0103bef:	8b 7b 3c             	mov    0x3c(%ebx),%edi

	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
f0103bf2:	e8 f8 1d 00 00       	call   f01059ef <cpunum>
f0103bf7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bfa:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103c00:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103c04:	75 46                	jne    f0103c4c <page_fault_handler+0x87>
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c06:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			curenv->env_id, fault_va, tf->tf_eip);
f0103c0c:	e8 de 1d 00 00       	call   f01059ef <cpunum>
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c11:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c14:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103c15:	6b c0 74             	imul   $0x74,%eax,%eax
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c18:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103c1e:	ff 70 48             	pushl  0x48(%eax)
f0103c21:	68 18 78 10 f0       	push   $0xf0107818
f0103c26:	e8 f6 fb ff ff       	call   f0103821 <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103c2b:	89 1c 24             	mov    %ebx,(%esp)
f0103c2e:	e8 0a fe ff ff       	call   f0103a3d <print_trapframe>
		env_destroy(curenv);	// Destroy the environment that caused the fault.
f0103c33:	e8 b7 1d 00 00       	call   f01059ef <cpunum>
f0103c38:	83 c4 04             	add    $0x4,%esp
f0103c3b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c3e:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f0103c44:	e8 11 f9 ff ff       	call   f010355a <env_destroy>
f0103c49:	83 c4 10             	add    $0x10,%esp
	}
	
	//Check if the	
	struct UTrapframe* usertf = NULL; //As defined in inc/trap.h
	
	if((cur_tf_esp_addr < UXSTACKTOP) && (cur_tf_esp_addr >=(UXSTACKTOP - PGSIZE)))
f0103c4c:	8d 97 00 10 40 11    	lea    0x11401000(%edi),%edx
	{
		//If its already inside the exception stack
		//Allocate the address by leaving space for 32-bit word
		usertf = (struct UTrapframe*)(cur_tf_esp_addr - 4 - sizeof(struct UTrapframe));
f0103c52:	8d 47 c8             	lea    -0x38(%edi),%eax
f0103c55:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103c5b:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103c60:	0f 46 d0             	cmovbe %eax,%edx
f0103c63:	89 d7                	mov    %edx,%edi
		usertf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
	}
	
	//Check whether the usertf memory is valid
	//This function will not return if there is a fault and it will also destroy the environment
	user_mem_assert(curenv, (void*)usertf, sizeof(struct UTrapframe), PTE_U | PTE_P | PTE_W);
f0103c65:	e8 85 1d 00 00       	call   f01059ef <cpunum>
f0103c6a:	6a 07                	push   $0x7
f0103c6c:	6a 34                	push   $0x34
f0103c6e:	57                   	push   %edi
f0103c6f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c72:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f0103c78:	e8 ac f2 ff ff       	call   f0102f29 <user_mem_assert>
	
	
	// User exeception trapframe
	usertf->utf_fault_va = fault_va;
f0103c7d:	89 fa                	mov    %edi,%edx
f0103c7f:	89 37                	mov    %esi,(%edi)
	usertf->utf_err = tf->tf_err;
f0103c81:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103c84:	89 47 04             	mov    %eax,0x4(%edi)
	usertf->utf_regs = tf->tf_regs;
f0103c87:	8d 7f 08             	lea    0x8(%edi),%edi
f0103c8a:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103c8f:	89 de                	mov    %ebx,%esi
f0103c91:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	usertf->utf_eip = tf->tf_eip;
f0103c93:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c96:	89 42 28             	mov    %eax,0x28(%edx)
	usertf->utf_esp = tf->tf_esp;
f0103c99:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c9c:	89 42 30             	mov    %eax,0x30(%edx)
	usertf->utf_eflags = tf->tf_eflags;
f0103c9f:	8b 43 38             	mov    0x38(%ebx),%eax
f0103ca2:	89 42 2c             	mov    %eax,0x2c(%edx)
	
	//Setup the tf with Exception stack frame
	
	tf->tf_esp= (uintptr_t)usertf;
f0103ca5:	89 53 3c             	mov    %edx,0x3c(%ebx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall; 
f0103ca8:	e8 42 1d 00 00       	call   f01059ef <cpunum>
f0103cad:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cb0:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103cb6:	8b 40 64             	mov    0x64(%eax),%eax
f0103cb9:	89 43 30             	mov    %eax,0x30(%ebx)

	env_run(curenv);
f0103cbc:	e8 2e 1d 00 00       	call   f01059ef <cpunum>
f0103cc1:	83 c4 04             	add    $0x4,%esp
f0103cc4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cc7:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f0103ccd:	e8 27 f9 ff ff       	call   f01035f9 <env_run>

f0103cd2 <trap>:
	
}

void
trap(struct Trapframe *tf)
{
f0103cd2:	55                   	push   %ebp
f0103cd3:	89 e5                	mov    %esp,%ebp
f0103cd5:	57                   	push   %edi
f0103cd6:	56                   	push   %esi
f0103cd7:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103cda:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103cdb:	83 3d c0 9e 20 f0 00 	cmpl   $0x0,0xf0209ec0
f0103ce2:	74 01                	je     f0103ce5 <trap+0x13>
		asm volatile("hlt");
f0103ce4:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103ce5:	e8 05 1d 00 00       	call   f01059ef <cpunum>
f0103cea:	6b d0 74             	imul   $0x74,%eax,%edx
f0103ced:	81 c2 40 a0 20 f0    	add    $0xf020a040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103cf3:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cf8:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103cfc:	83 f8 02             	cmp    $0x2,%eax
f0103cff:	75 10                	jne    f0103d11 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d01:	83 ec 0c             	sub    $0xc,%esp
f0103d04:	68 c0 04 12 f0       	push   $0xf01204c0
f0103d09:	e8 4c 1f 00 00       	call   f0105c5a <spin_lock>
f0103d0e:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d11:	9c                   	pushf  
f0103d12:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d13:	f6 c4 02             	test   $0x2,%ah
f0103d16:	74 19                	je     f0103d31 <trap+0x5f>
f0103d18:	68 39 76 10 f0       	push   $0xf0107639
f0103d1d:	68 9b 70 10 f0       	push   $0xf010709b
f0103d22:	68 1d 01 00 00       	push   $0x11d
f0103d27:	68 2d 76 10 f0       	push   $0xf010762d
f0103d2c:	e8 0f c3 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d31:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d35:	83 e0 03             	and    $0x3,%eax
f0103d38:	66 83 f8 03          	cmp    $0x3,%ax
f0103d3c:	0f 85 a0 00 00 00    	jne    f0103de2 <trap+0x110>
f0103d42:	83 ec 0c             	sub    $0xc,%esp
f0103d45:	68 c0 04 12 f0       	push   $0xf01204c0
f0103d4a:	e8 0b 1f 00 00       	call   f0105c5a <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f0103d4f:	e8 9b 1c 00 00       	call   f01059ef <cpunum>
f0103d54:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d57:	83 c4 10             	add    $0x10,%esp
f0103d5a:	83 b8 48 a0 20 f0 00 	cmpl   $0x0,-0xfdf5fb8(%eax)
f0103d61:	75 19                	jne    f0103d7c <trap+0xaa>
f0103d63:	68 52 76 10 f0       	push   $0xf0107652
f0103d68:	68 9b 70 10 f0       	push   $0xf010709b
f0103d6d:	68 25 01 00 00       	push   $0x125
f0103d72:	68 2d 76 10 f0       	push   $0xf010762d
f0103d77:	e8 c4 c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103d7c:	e8 6e 1c 00 00       	call   f01059ef <cpunum>
f0103d81:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d84:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103d8a:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103d8e:	75 2d                	jne    f0103dbd <trap+0xeb>
			env_free(curenv);
f0103d90:	e8 5a 1c 00 00       	call   f01059ef <cpunum>
f0103d95:	83 ec 0c             	sub    $0xc,%esp
f0103d98:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d9b:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f0103da1:	e8 0e f6 ff ff       	call   f01033b4 <env_free>
			curenv = NULL;
f0103da6:	e8 44 1c 00 00       	call   f01059ef <cpunum>
f0103dab:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dae:	c7 80 48 a0 20 f0 00 	movl   $0x0,-0xfdf5fb8(%eax)
f0103db5:	00 00 00 
			sched_yield();
f0103db8:	e8 19 04 00 00       	call   f01041d6 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103dbd:	e8 2d 1c 00 00       	call   f01059ef <cpunum>
f0103dc2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dc5:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103dcb:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103dd0:	89 c7                	mov    %eax,%edi
f0103dd2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103dd4:	e8 16 1c 00 00       	call   f01059ef <cpunum>
f0103dd9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ddc:	8b b0 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103de2:	89 35 80 9a 20 f0    	mov    %esi,0xf0209a80
{

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103de8:	8b 46 28             	mov    0x28(%esi),%eax
f0103deb:	83 f8 27             	cmp    $0x27,%eax
f0103dee:	75 1d                	jne    f0103e0d <trap+0x13b>
		cprintf("Spurious interrupt on irq 7\n");
f0103df0:	83 ec 0c             	sub    $0xc,%esp
f0103df3:	68 59 76 10 f0       	push   $0xf0107659
f0103df8:	e8 24 fa ff ff       	call   f0103821 <cprintf>
		print_trapframe(tf);
f0103dfd:	89 34 24             	mov    %esi,(%esp)
f0103e00:	e8 38 fc ff ff       	call   f0103a3d <print_trapframe>
f0103e05:	83 c4 10             	add    $0x10,%esp
f0103e08:	e9 c9 00 00 00       	jmp    f0103ed6 <trap+0x204>
	}

	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103e0d:	83 f8 20             	cmp    $0x20,%eax
f0103e10:	74 69                	je     f0103e7b <trap+0x1a9>
f0103e12:	83 f8 20             	cmp    $0x20,%eax
f0103e15:	77 0c                	ja     f0103e23 <trap+0x151>
f0103e17:	83 f8 03             	cmp    $0x3,%eax
f0103e1a:	74 18                	je     f0103e34 <trap+0x162>
f0103e1c:	83 f8 0e             	cmp    $0xe,%eax
f0103e1f:	74 30                	je     f0103e51 <trap+0x17f>
f0103e21:	eb 70                	jmp    f0103e93 <trap+0x1c1>
f0103e23:	83 f8 24             	cmp    $0x24,%eax
f0103e26:	74 64                	je     f0103e8c <trap+0x1ba>
f0103e28:	83 f8 30             	cmp    $0x30,%eax
f0103e2b:	74 2d                	je     f0103e5a <trap+0x188>
f0103e2d:	83 f8 21             	cmp    $0x21,%eax
f0103e30:	75 61                	jne    f0103e93 <trap+0x1c1>
f0103e32:	eb 51                	jmp    f0103e85 <trap+0x1b3>
		case T_BRKPT:
			monitor(tf);
f0103e34:	83 ec 0c             	sub    $0xc,%esp
f0103e37:	56                   	push   %esi
f0103e38:	e8 d6 ca ff ff       	call   f0100913 <monitor>
			cprintf("return from breakpoint....\n");
f0103e3d:	c7 04 24 76 76 10 f0 	movl   $0xf0107676,(%esp)
f0103e44:	e8 d8 f9 ff ff       	call   f0103821 <cprintf>
f0103e49:	83 c4 10             	add    $0x10,%esp
f0103e4c:	e9 85 00 00 00       	jmp    f0103ed6 <trap+0x204>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103e51:	83 ec 0c             	sub    $0xc,%esp
f0103e54:	56                   	push   %esi
f0103e55:	e8 6b fd ff ff       	call   f0103bc5 <page_fault_handler>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e5a:	83 ec 08             	sub    $0x8,%esp
f0103e5d:	ff 76 04             	pushl  0x4(%esi)
f0103e60:	ff 36                	pushl  (%esi)
f0103e62:	ff 76 10             	pushl  0x10(%esi)
f0103e65:	ff 76 18             	pushl  0x18(%esi)
f0103e68:	ff 76 14             	pushl  0x14(%esi)
f0103e6b:	ff 76 1c             	pushl  0x1c(%esi)
f0103e6e:	e8 43 04 00 00       	call   f01042b6 <syscall>
f0103e73:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e76:	83 c4 20             	add    $0x20,%esp
f0103e79:	eb 5b                	jmp    f0103ed6 <trap+0x204>

		// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
		case IRQ_OFFSET+IRQ_TIMER:
			lapic_eoi();
f0103e7b:	e8 ba 1c 00 00       	call   f0105b3a <lapic_eoi>
			sched_yield();
f0103e80:	e8 51 03 00 00       	call   f01041d6 <sched_yield>
			break;
		
		// Handle keyboard and serial interrupts.
		// LAB 5: Your code here.
		case IRQ_OFFSET+IRQ_KBD:
			kbd_intr();
f0103e85:	e8 5d c7 ff ff       	call   f01005e7 <kbd_intr>
f0103e8a:	eb 4a                	jmp    f0103ed6 <trap+0x204>
			break;

		case IRQ_OFFSET+IRQ_SERIAL:
			serial_intr();
f0103e8c:	e8 3a c7 ff ff       	call   f01005cb <serial_intr>
f0103e91:	eb 43                	jmp    f0103ed6 <trap+0x204>
	

	
		default:
		// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f0103e93:	83 ec 0c             	sub    $0xc,%esp
f0103e96:	56                   	push   %esi
f0103e97:	e8 a1 fb ff ff       	call   f0103a3d <print_trapframe>
			if (tf->tf_cs == GD_KT){
f0103e9c:	83 c4 10             	add    $0x10,%esp
f0103e9f:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103ea4:	75 17                	jne    f0103ebd <trap+0x1eb>
			panic("unhandled trap in kernel");
f0103ea6:	83 ec 04             	sub    $0x4,%esp
f0103ea9:	68 92 76 10 f0       	push   $0xf0107692
f0103eae:	68 00 01 00 00       	push   $0x100
f0103eb3:	68 2d 76 10 f0       	push   $0xf010762d
f0103eb8:	e8 83 c1 ff ff       	call   f0100040 <_panic>
			}
		else {
			env_destroy(curenv);
f0103ebd:	e8 2d 1b 00 00       	call   f01059ef <cpunum>
f0103ec2:	83 ec 0c             	sub    $0xc,%esp
f0103ec5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ec8:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f0103ece:	e8 87 f6 ff ff       	call   f010355a <env_destroy>
f0103ed3:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103ed6:	e8 14 1b 00 00       	call   f01059ef <cpunum>
f0103edb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ede:	83 b8 48 a0 20 f0 00 	cmpl   $0x0,-0xfdf5fb8(%eax)
f0103ee5:	74 2a                	je     f0103f11 <trap+0x23f>
f0103ee7:	e8 03 1b 00 00       	call   f01059ef <cpunum>
f0103eec:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eef:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0103ef5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ef9:	75 16                	jne    f0103f11 <trap+0x23f>
		env_run(curenv);
f0103efb:	e8 ef 1a 00 00       	call   f01059ef <cpunum>
f0103f00:	83 ec 0c             	sub    $0xc,%esp
f0103f03:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f06:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f0103f0c:	e8 e8 f6 ff ff       	call   f01035f9 <env_run>
	else
		sched_yield();
f0103f11:	e8 c0 02 00 00       	call   f01041d6 <sched_yield>

f0103f16 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103f16:	6a 00                	push   $0x0
f0103f18:	6a 00                	push   $0x0
f0103f1a:	e9 d2 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f1f:	90                   	nop

f0103f20 <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103f20:	6a 00                	push   $0x0
f0103f22:	6a 01                	push   $0x1
f0103f24:	e9 c8 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f29:	90                   	nop

f0103f2a <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103f2a:	6a 00                	push   $0x0
f0103f2c:	6a 02                	push   $0x2
f0103f2e:	e9 be 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f33:	90                   	nop

f0103f34 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103f34:	6a 00                	push   $0x0
f0103f36:	6a 03                	push   $0x3
f0103f38:	e9 b4 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f3d:	90                   	nop

f0103f3e <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103f3e:	6a 00                	push   $0x0
f0103f40:	6a 04                	push   $0x4
f0103f42:	e9 aa 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f47:	90                   	nop

f0103f48 <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103f48:	6a 00                	push   $0x0
f0103f4a:	6a 05                	push   $0x5
f0103f4c:	e9 a0 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f51:	90                   	nop

f0103f52 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103f52:	6a 00                	push   $0x0
f0103f54:	6a 06                	push   $0x6
f0103f56:	e9 96 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f5b:	90                   	nop

f0103f5c <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103f5c:	6a 00                	push   $0x0
f0103f5e:	6a 07                	push   $0x7
f0103f60:	e9 8c 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f65:	90                   	nop

f0103f66 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103f66:	6a 08                	push   $0x8
f0103f68:	e9 84 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f6d:	90                   	nop

f0103f6e <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103f6e:	6a 00                	push   $0x0
f0103f70:	6a 09                	push   $0x9
f0103f72:	e9 7a 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f77:	90                   	nop

f0103f78 <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103f78:	6a 0a                	push   $0xa
f0103f7a:	e9 72 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f7f:	90                   	nop

f0103f80 <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103f80:	6a 0b                	push   $0xb
f0103f82:	e9 6a 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f87:	90                   	nop

f0103f88 <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103f88:	6a 0c                	push   $0xc
f0103f8a:	e9 62 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f8f:	90                   	nop

f0103f90 <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103f90:	6a 0d                	push   $0xd
f0103f92:	e9 5a 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f97:	90                   	nop

f0103f98 <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103f98:	6a 0e                	push   $0xe
f0103f9a:	e9 52 01 00 00       	jmp    f01040f1 <_alltraps>
f0103f9f:	90                   	nop

f0103fa0 <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103fa0:	6a 00                	push   $0x0
f0103fa2:	6a 0f                	push   $0xf
f0103fa4:	e9 48 01 00 00       	jmp    f01040f1 <_alltraps>
f0103fa9:	90                   	nop

f0103faa <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103faa:	6a 00                	push   $0x0
f0103fac:	6a 10                	push   $0x10
f0103fae:	e9 3e 01 00 00       	jmp    f01040f1 <_alltraps>
f0103fb3:	90                   	nop

f0103fb4 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103fb4:	6a 11                	push   $0x11
f0103fb6:	e9 36 01 00 00       	jmp    f01040f1 <_alltraps>
f0103fbb:	90                   	nop

f0103fbc <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103fbc:	6a 00                	push   $0x0
f0103fbe:	6a 12                	push   $0x12
f0103fc0:	e9 2c 01 00 00       	jmp    f01040f1 <_alltraps>
f0103fc5:	90                   	nop

f0103fc6 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103fc6:	6a 00                	push   $0x0
f0103fc8:	6a 13                	push   $0x13
f0103fca:	e9 22 01 00 00       	jmp    f01040f1 <_alltraps>
f0103fcf:	90                   	nop

f0103fd0 <handler_20>:

	TRAPHANDLER_NOEC(handler_20, 20)
f0103fd0:	6a 00                	push   $0x0
f0103fd2:	6a 14                	push   $0x14
f0103fd4:	e9 18 01 00 00       	jmp    f01040f1 <_alltraps>
f0103fd9:	90                   	nop

f0103fda <handler_21>:
	TRAPHANDLER_NOEC(handler_21, 21)
f0103fda:	6a 00                	push   $0x0
f0103fdc:	6a 15                	push   $0x15
f0103fde:	e9 0e 01 00 00       	jmp    f01040f1 <_alltraps>
f0103fe3:	90                   	nop

f0103fe4 <handler_22>:
	TRAPHANDLER_NOEC(handler_22, 22)
f0103fe4:	6a 00                	push   $0x0
f0103fe6:	6a 16                	push   $0x16
f0103fe8:	e9 04 01 00 00       	jmp    f01040f1 <_alltraps>
f0103fed:	90                   	nop

f0103fee <handler_23>:
	TRAPHANDLER_NOEC(handler_23, 23)
f0103fee:	6a 00                	push   $0x0
f0103ff0:	6a 17                	push   $0x17
f0103ff2:	e9 fa 00 00 00       	jmp    f01040f1 <_alltraps>
f0103ff7:	90                   	nop

f0103ff8 <handler_24>:
	TRAPHANDLER_NOEC(handler_24, 24)
f0103ff8:	6a 00                	push   $0x0
f0103ffa:	6a 18                	push   $0x18
f0103ffc:	e9 f0 00 00 00       	jmp    f01040f1 <_alltraps>
f0104001:	90                   	nop

f0104002 <handler_25>:
	TRAPHANDLER_NOEC(handler_25, 25)
f0104002:	6a 00                	push   $0x0
f0104004:	6a 19                	push   $0x19
f0104006:	e9 e6 00 00 00       	jmp    f01040f1 <_alltraps>
f010400b:	90                   	nop

f010400c <handler_26>:
	TRAPHANDLER_NOEC(handler_26, 26)
f010400c:	6a 00                	push   $0x0
f010400e:	6a 1a                	push   $0x1a
f0104010:	e9 dc 00 00 00       	jmp    f01040f1 <_alltraps>
f0104015:	90                   	nop

f0104016 <handler_27>:
	TRAPHANDLER_NOEC(handler_27, 27)
f0104016:	6a 00                	push   $0x0
f0104018:	6a 1b                	push   $0x1b
f010401a:	e9 d2 00 00 00       	jmp    f01040f1 <_alltraps>
f010401f:	90                   	nop

f0104020 <handler_28>:
	TRAPHANDLER_NOEC(handler_28, 28)
f0104020:	6a 00                	push   $0x0
f0104022:	6a 1c                	push   $0x1c
f0104024:	e9 c8 00 00 00       	jmp    f01040f1 <_alltraps>
f0104029:	90                   	nop

f010402a <handler_29>:
	TRAPHANDLER_NOEC(handler_29, 29)
f010402a:	6a 00                	push   $0x0
f010402c:	6a 1d                	push   $0x1d
f010402e:	e9 be 00 00 00       	jmp    f01040f1 <_alltraps>
f0104033:	90                   	nop

f0104034 <handler_30>:
	TRAPHANDLER_NOEC(handler_30, 30)
f0104034:	6a 00                	push   $0x0
f0104036:	6a 1e                	push   $0x1e
f0104038:	e9 b4 00 00 00       	jmp    f01040f1 <_alltraps>
f010403d:	90                   	nop

f010403e <handler_31>:
	TRAPHANDLER_NOEC(handler_31, 31)
f010403e:	6a 00                	push   $0x0
f0104040:	6a 1f                	push   $0x1f
f0104042:	e9 aa 00 00 00       	jmp    f01040f1 <_alltraps>
f0104047:	90                   	nop

f0104048 <handler_32>:
	TRAPHANDLER_NOEC(handler_32, 32)
f0104048:	6a 00                	push   $0x0
f010404a:	6a 20                	push   $0x20
f010404c:	e9 a0 00 00 00       	jmp    f01040f1 <_alltraps>
f0104051:	90                   	nop

f0104052 <handler_33>:
	TRAPHANDLER_NOEC(handler_33, 33)
f0104052:	6a 00                	push   $0x0
f0104054:	6a 21                	push   $0x21
f0104056:	e9 96 00 00 00       	jmp    f01040f1 <_alltraps>
f010405b:	90                   	nop

f010405c <handler_34>:
	TRAPHANDLER_NOEC(handler_34, 34)
f010405c:	6a 00                	push   $0x0
f010405e:	6a 22                	push   $0x22
f0104060:	e9 8c 00 00 00       	jmp    f01040f1 <_alltraps>
f0104065:	90                   	nop

f0104066 <handler_35>:
	TRAPHANDLER_NOEC(handler_35, 35)
f0104066:	6a 00                	push   $0x0
f0104068:	6a 23                	push   $0x23
f010406a:	e9 82 00 00 00       	jmp    f01040f1 <_alltraps>
f010406f:	90                   	nop

f0104070 <handler_36>:
	TRAPHANDLER_NOEC(handler_36, 36)
f0104070:	6a 00                	push   $0x0
f0104072:	6a 24                	push   $0x24
f0104074:	e9 78 00 00 00       	jmp    f01040f1 <_alltraps>
f0104079:	90                   	nop

f010407a <handler_37>:
	TRAPHANDLER_NOEC(handler_37, 37)
f010407a:	6a 00                	push   $0x0
f010407c:	6a 25                	push   $0x25
f010407e:	e9 6e 00 00 00       	jmp    f01040f1 <_alltraps>
f0104083:	90                   	nop

f0104084 <handler_38>:
	TRAPHANDLER_NOEC(handler_38, 38)
f0104084:	6a 00                	push   $0x0
f0104086:	6a 26                	push   $0x26
f0104088:	e9 64 00 00 00       	jmp    f01040f1 <_alltraps>
f010408d:	90                   	nop

f010408e <handler_39>:
	TRAPHANDLER_NOEC(handler_39, 39)
f010408e:	6a 00                	push   $0x0
f0104090:	6a 27                	push   $0x27
f0104092:	e9 5a 00 00 00       	jmp    f01040f1 <_alltraps>
f0104097:	90                   	nop

f0104098 <handler_40>:
	TRAPHANDLER_NOEC(handler_40, 40)
f0104098:	6a 00                	push   $0x0
f010409a:	6a 28                	push   $0x28
f010409c:	e9 50 00 00 00       	jmp    f01040f1 <_alltraps>
f01040a1:	90                   	nop

f01040a2 <handler_41>:
	TRAPHANDLER_NOEC(handler_41, 41)
f01040a2:	6a 00                	push   $0x0
f01040a4:	6a 29                	push   $0x29
f01040a6:	e9 46 00 00 00       	jmp    f01040f1 <_alltraps>
f01040ab:	90                   	nop

f01040ac <handler_42>:
	TRAPHANDLER_NOEC(handler_42, 42)
f01040ac:	6a 00                	push   $0x0
f01040ae:	6a 2a                	push   $0x2a
f01040b0:	e9 3c 00 00 00       	jmp    f01040f1 <_alltraps>
f01040b5:	90                   	nop

f01040b6 <handler_43>:
	TRAPHANDLER_NOEC(handler_43, 43)
f01040b6:	6a 00                	push   $0x0
f01040b8:	6a 2b                	push   $0x2b
f01040ba:	e9 32 00 00 00       	jmp    f01040f1 <_alltraps>
f01040bf:	90                   	nop

f01040c0 <handler_44>:
	TRAPHANDLER_NOEC(handler_44, 44)
f01040c0:	6a 00                	push   $0x0
f01040c2:	6a 2c                	push   $0x2c
f01040c4:	e9 28 00 00 00       	jmp    f01040f1 <_alltraps>
f01040c9:	90                   	nop

f01040ca <handler_45>:
	TRAPHANDLER_NOEC(handler_45, 45)
f01040ca:	6a 00                	push   $0x0
f01040cc:	6a 2d                	push   $0x2d
f01040ce:	e9 1e 00 00 00       	jmp    f01040f1 <_alltraps>
f01040d3:	90                   	nop

f01040d4 <handler_46>:
	TRAPHANDLER_NOEC(handler_46, 46)
f01040d4:	6a 00                	push   $0x0
f01040d6:	6a 2e                	push   $0x2e
f01040d8:	e9 14 00 00 00       	jmp    f01040f1 <_alltraps>
f01040dd:	90                   	nop

f01040de <handler_47>:
	TRAPHANDLER_NOEC(handler_47, 47)
f01040de:	6a 00                	push   $0x0
f01040e0:	6a 2f                	push   $0x2f
f01040e2:	e9 0a 00 00 00       	jmp    f01040f1 <_alltraps>
f01040e7:	90                   	nop

f01040e8 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f01040e8:	6a 00                	push   $0x0
f01040ea:	6a 30                	push   $0x30
f01040ec:	e9 00 00 00 00       	jmp    f01040f1 <_alltraps>

f01040f1 <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f01040f1:	1e                   	push   %ds
	push %es
f01040f2:	06                   	push   %es
	pushal
f01040f3:	60                   	pusha  

	
	movw $GD_KD, %ax
f01040f4:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01040f8:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01040fa:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f01040fc:	54                   	push   %esp
	call trap
f01040fd:	e8 d0 fb ff ff       	call   f0103cd2 <trap>

f0104102 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104102:	55                   	push   %ebp
f0104103:	89 e5                	mov    %esp,%ebp
f0104105:	83 ec 08             	sub    $0x8,%esp
f0104108:	a1 6c 92 20 f0       	mov    0xf020926c,%eax
f010410d:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104110:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104115:	8b 02                	mov    (%edx),%eax
f0104117:	83 e8 01             	sub    $0x1,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f010411a:	83 f8 02             	cmp    $0x2,%eax
f010411d:	76 10                	jbe    f010412f <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010411f:	83 c1 01             	add    $0x1,%ecx
f0104122:	83 c2 7c             	add    $0x7c,%edx
f0104125:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010412b:	75 e8                	jne    f0104115 <sched_halt+0x13>
f010412d:	eb 08                	jmp    f0104137 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010412f:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104135:	75 1f                	jne    f0104156 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104137:	83 ec 0c             	sub    $0xc,%esp
f010413a:	68 90 78 10 f0       	push   $0xf0107890
f010413f:	e8 dd f6 ff ff       	call   f0103821 <cprintf>
f0104144:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104147:	83 ec 0c             	sub    $0xc,%esp
f010414a:	6a 00                	push   $0x0
f010414c:	e8 c2 c7 ff ff       	call   f0100913 <monitor>
f0104151:	83 c4 10             	add    $0x10,%esp
f0104154:	eb f1                	jmp    f0104147 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104156:	e8 94 18 00 00       	call   f01059ef <cpunum>
f010415b:	6b c0 74             	imul   $0x74,%eax,%eax
f010415e:	c7 80 48 a0 20 f0 00 	movl   $0x0,-0xfdf5fb8(%eax)
f0104165:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104168:	a1 cc 9e 20 f0       	mov    0xf0209ecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010416d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104172:	77 12                	ja     f0104186 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104174:	50                   	push   %eax
f0104175:	68 08 61 10 f0       	push   $0xf0106108
f010417a:	6a 54                	push   $0x54
f010417c:	68 b9 78 10 f0       	push   $0xf01078b9
f0104181:	e8 ba be ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104186:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010418b:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010418e:	e8 5c 18 00 00       	call   f01059ef <cpunum>
f0104193:	6b d0 74             	imul   $0x74,%eax,%edx
f0104196:	81 c2 40 a0 20 f0    	add    $0xf020a040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010419c:	b8 02 00 00 00       	mov    $0x2,%eax
f01041a1:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01041a5:	83 ec 0c             	sub    $0xc,%esp
f01041a8:	68 c0 04 12 f0       	push   $0xf01204c0
f01041ad:	e8 45 1b 00 00       	call   f0105cf7 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01041b2:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01041b4:	e8 36 18 00 00       	call   f01059ef <cpunum>
f01041b9:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01041bc:	8b 80 50 a0 20 f0    	mov    -0xfdf5fb0(%eax),%eax
f01041c2:	bd 00 00 00 00       	mov    $0x0,%ebp
f01041c7:	89 c4                	mov    %eax,%esp
f01041c9:	6a 00                	push   $0x0
f01041cb:	6a 00                	push   $0x0
f01041cd:	fb                   	sti    
f01041ce:	f4                   	hlt    
f01041cf:	eb fd                	jmp    f01041ce <sched_halt+0xcc>
f01041d1:	83 c4 10             	add    $0x10,%esp
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01041d4:	c9                   	leave  
f01041d5:	c3                   	ret    

f01041d6 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01041d6:	55                   	push   %ebp
f01041d7:	89 e5                	mov    %esp,%ebp
f01041d9:	53                   	push   %ebx
f01041da:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01041dd:	e8 0d 18 00 00       	call   f01059ef <cpunum>
f01041e2:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f01041e5:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01041ea:	83 b8 48 a0 20 f0 00 	cmpl   $0x0,-0xfdf5fb8(%eax)
f01041f1:	74 33                	je     f0104226 <sched_yield+0x50>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f01041f3:	e8 f7 17 00 00       	call   f01059ef <cpunum>
f01041f8:	6b c0 74             	imul   $0x74,%eax,%eax
f01041fb:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0104201:	2b 05 6c 92 20 f0    	sub    0xf020926c,%eax
f0104207:	c1 f8 02             	sar    $0x2,%eax
f010420a:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f0104210:	83 c0 01             	add    $0x1,%eax
f0104213:	89 c1                	mov    %eax,%ecx
f0104215:	c1 f9 1f             	sar    $0x1f,%ecx
f0104218:	c1 e9 16             	shr    $0x16,%ecx
f010421b:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f010421e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104224:	29 ca                	sub    %ecx,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f0104226:	a1 6c 92 20 f0       	mov    0xf020926c,%eax
f010422b:	b9 00 04 00 00       	mov    $0x400,%ecx
f0104230:	6b da 7c             	imul   $0x7c,%edx,%ebx
f0104233:	83 7c 18 54 02       	cmpl   $0x2,0x54(%eax,%ebx,1)
f0104238:	74 70                	je     f01042aa <sched_yield+0xd4>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f010423a:	83 c2 01             	add    $0x1,%edx
f010423d:	89 d3                	mov    %edx,%ebx
f010423f:	c1 fb 1f             	sar    $0x1f,%ebx
f0104242:	c1 eb 16             	shr    $0x16,%ebx
f0104245:	01 da                	add    %ebx,%edx
f0104247:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010424d:	29 da                	sub    %ebx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f010424f:	83 e9 01             	sub    $0x1,%ecx
f0104252:	75 dc                	jne    f0104230 <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f0104254:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104257:	01 c2                	add    %eax,%edx
f0104259:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f010425d:	75 09                	jne    f0104268 <sched_yield+0x92>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f010425f:	83 ec 0c             	sub    $0xc,%esp
f0104262:	52                   	push   %edx
f0104263:	e8 91 f3 ff ff       	call   f01035f9 <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f0104268:	e8 82 17 00 00       	call   f01059ef <cpunum>
f010426d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104270:	83 b8 48 a0 20 f0 00 	cmpl   $0x0,-0xfdf5fb8(%eax)
f0104277:	74 2a                	je     f01042a3 <sched_yield+0xcd>
f0104279:	e8 71 17 00 00       	call   f01059ef <cpunum>
f010427e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104281:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0104287:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010428b:	75 16                	jne    f01042a3 <sched_yield+0xcd>
	    env_run(curenv) ;
f010428d:	e8 5d 17 00 00       	call   f01059ef <cpunum>
f0104292:	83 ec 0c             	sub    $0xc,%esp
f0104295:	6b c0 74             	imul   $0x74,%eax,%eax
f0104298:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f010429e:	e8 56 f3 ff ff       	call   f01035f9 <env_run>
	}
	// sched_halt never returns
	sched_halt();
f01042a3:	e8 5a fe ff ff       	call   f0104102 <sched_halt>
f01042a8:	eb 07                	jmp    f01042b1 <sched_yield+0xdb>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f01042aa:	6b d2 7c             	imul   $0x7c,%edx,%edx
f01042ad:	01 c2                	add    %eax,%edx
f01042af:	eb ae                	jmp    f010425f <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f01042b1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042b4:	c9                   	leave  
f01042b5:	c3                   	ret    

f01042b6 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01042b6:	55                   	push   %ebp
f01042b7:	89 e5                	mov    %esp,%ebp
f01042b9:	57                   	push   %edi
f01042ba:	56                   	push   %esi
f01042bb:	53                   	push   %ebx
f01042bc:	83 ec 1c             	sub    $0x1c,%esp
f01042bf:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f01042c2:	83 f8 0d             	cmp    $0xd,%eax
f01042c5:	0f 87 43 05 00 00    	ja     f010480e <syscall+0x558>
f01042cb:	ff 24 85 34 79 10 f0 	jmp    *-0xfef86cc(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f01042d2:	e8 18 17 00 00       	call   f01059ef <cpunum>
f01042d7:	6a 05                	push   $0x5
f01042d9:	ff 75 10             	pushl  0x10(%ebp)
f01042dc:	ff 75 0c             	pushl  0xc(%ebp)
f01042df:	6b c0 74             	imul   $0x74,%eax,%eax
f01042e2:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f01042e8:	e8 3c ec ff ff       	call   f0102f29 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01042ed:	83 c4 0c             	add    $0xc,%esp
f01042f0:	ff 75 0c             	pushl  0xc(%ebp)
f01042f3:	ff 75 10             	pushl  0x10(%ebp)
f01042f6:	68 c6 78 10 f0       	push   $0xf01078c6
f01042fb:	e8 21 f5 ff ff       	call   f0103821 <cprintf>
f0104300:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f0104303:	b8 00 00 00 00       	mov    $0x0,%eax
f0104308:	e9 1d 05 00 00       	jmp    f010482a <syscall+0x574>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010430d:	e8 e7 c2 ff ff       	call   f01005f9 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0104312:	e9 13 05 00 00       	jmp    f010482a <syscall+0x574>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104317:	e8 d3 16 00 00       	call   f01059ef <cpunum>
f010431c:	6b c0 74             	imul   $0x74,%eax,%eax
f010431f:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0104325:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0104328:	e9 fd 04 00 00       	jmp    f010482a <syscall+0x574>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010432d:	83 ec 04             	sub    $0x4,%esp
f0104330:	6a 01                	push   $0x1
f0104332:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104335:	50                   	push   %eax
f0104336:	ff 75 0c             	pushl  0xc(%ebp)
f0104339:	e8 bb ec ff ff       	call   f0102ff9 <envid2env>
f010433e:	89 c2                	mov    %eax,%edx
f0104340:	83 c4 10             	add    $0x10,%esp
f0104343:	85 d2                	test   %edx,%edx
f0104345:	0f 88 df 04 00 00    	js     f010482a <syscall+0x574>
		return r;
	env_destroy(e);
f010434b:	83 ec 0c             	sub    $0xc,%esp
f010434e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104351:	e8 04 f2 ff ff       	call   f010355a <env_destroy>
f0104356:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104359:	b8 00 00 00 00       	mov    $0x0,%eax
f010435e:	e9 c7 04 00 00       	jmp    f010482a <syscall+0x574>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104363:	e8 6e fe ff ff       	call   f01041d6 <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childenv;
	int errcode = env_alloc(&childenv, curenv->env_id);
f0104368:	e8 82 16 00 00       	call   f01059ef <cpunum>
f010436d:	83 ec 08             	sub    $0x8,%esp
f0104370:	6b c0 74             	imul   $0x74,%eax,%eax
f0104373:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0104379:	ff 70 48             	pushl  0x48(%eax)
f010437c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010437f:	50                   	push   %eax
f0104380:	e8 7f ed ff ff       	call   f0103104 <env_alloc>
f0104385:	89 c2                	mov    %eax,%edx
	
	//If the error code is less than 0, that means there has been an error while creating an env	
	if (errcode < 0) {
f0104387:	83 c4 10             	add    $0x10,%esp
f010438a:	85 d2                	test   %edx,%edx
f010438c:	0f 88 98 04 00 00    	js     f010482a <syscall+0x574>
		return errcode; //Return the environment
	}
	
	//Set the child environment as not runnable	
	childenv->env_status = ENV_NOT_RUNNABLE;
f0104392:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104395:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)

	//Copy the current environemnt register data into the child
	childenv->env_tf = curenv->env_tf;
f010439c:	e8 4e 16 00 00       	call   f01059ef <cpunum>
f01043a1:	6b c0 74             	imul   $0x74,%eax,%eax
f01043a4:	8b b0 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%esi
f01043aa:	b9 11 00 00 00       	mov    $0x11,%ecx
f01043af:	89 df                	mov    %ebx,%edi
f01043b1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

	// when the child is scheduled to run, it has to restart the trapframe. 
	//Hence we modify the register eax to be 0. 

	childenv->env_tf.tf_regs.reg_eax = 0; 
f01043b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043b6:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return childenv->env_id;
f01043bd:	8b 40 48             	mov    0x48(%eax),%eax
f01043c0:	e9 65 04 00 00       	jmp    f010482a <syscall+0x574>

	// LAB 4: Your code here.
	
	struct Env *env_store;
	int errcode; 
	errcode = envid2env(envid, &env_store,1);
f01043c5:	83 ec 04             	sub    $0x4,%esp
f01043c8:	6a 01                	push   $0x1
f01043ca:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043cd:	50                   	push   %eax
f01043ce:	ff 75 0c             	pushl  0xc(%ebp)
f01043d1:	e8 23 ec ff ff       	call   f0102ff9 <envid2env>
	if (errcode < 0)
f01043d6:	83 c4 10             	add    $0x10,%esp
f01043d9:	85 c0                	test   %eax,%eax
f01043db:	0f 88 49 04 00 00    	js     f010482a <syscall+0x574>
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f01043e1:	8b 45 10             	mov    0x10(%ebp),%eax
f01043e4:	8d 50 fe             	lea    -0x2(%eax),%edx
		env_store->env_status = status;

	else
		return E_INVAL;
f01043e7:	b8 03 00 00 00       	mov    $0x3,%eax
	errcode = envid2env(envid, &env_store,1);
	if (errcode < 0)
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f01043ec:	f7 c2 fd ff ff ff    	test   $0xfffffffd,%edx
f01043f2:	0f 85 32 04 00 00    	jne    f010482a <syscall+0x574>
		env_store->env_status = status;
f01043f8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043fb:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01043fe:	89 58 54             	mov    %ebx,0x54(%eax)

	else
		return E_INVAL;

	return 0;
f0104401:	b8 00 00 00 00       	mov    $0x0,%eax
f0104406:	e9 1f 04 00 00       	jmp    f010482a <syscall+0x574>
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
		return  E_INVAL;
f010440b:	b8 03 00 00 00       	mov    $0x3,%eax
	
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
f0104410:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104417:	0f 87 0d 04 00 00    	ja     f010482a <syscall+0x574>
f010441d:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104424:	0f 85 00 04 00 00    	jne    f010482a <syscall+0x574>
		return  E_INVAL;

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f010442a:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f0104431:	0f 84 f3 03 00 00    	je     f010482a <syscall+0x574>
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
f0104437:	83 ec 0c             	sub    $0xc,%esp
f010443a:	6a 01                	push   $0x1
f010443c:	e8 8d cb ff ff       	call   f0100fce <page_alloc>
f0104441:	89 c3                	mov    %eax,%ebx
	if (!newpage)
f0104443:	83 c4 10             	add    $0x10,%esp
		return E_NO_MEM; 
f0104446:	b8 04 00 00 00       	mov    $0x4,%eax
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
	if (!newpage)
f010444b:	85 db                	test   %ebx,%ebx
f010444d:	0f 84 d7 03 00 00    	je     f010482a <syscall+0x574>
		return E_NO_MEM; 

	//Use environid to get the environment 
	if ((code = envid2env(envid, &en,1))<0)
f0104453:	83 ec 04             	sub    $0x4,%esp
f0104456:	6a 01                	push   $0x1
f0104458:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010445b:	50                   	push   %eax
f010445c:	ff 75 0c             	pushl  0xc(%ebp)
f010445f:	e8 95 eb ff ff       	call   f0102ff9 <envid2env>
f0104464:	83 c4 10             	add    $0x10,%esp
f0104467:	85 c0                	test   %eax,%eax
f0104469:	0f 88 bb 03 00 00    	js     f010482a <syscall+0x574>
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
f010446f:	ff 75 14             	pushl  0x14(%ebp)
f0104472:	ff 75 10             	pushl  0x10(%ebp)
f0104475:	53                   	push   %ebx
f0104476:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104479:	ff 70 60             	pushl  0x60(%eax)
f010447c:	e8 73 ce ff ff       	call   f01012f4 <page_insert>
f0104481:	89 c6                	mov    %eax,%esi
	if (code < 0)
f0104483:	83 c4 10             	add    $0x10,%esp
	{
		page_free(newpage);
		return code;
	}
	
	return 0;
f0104486:	b8 00 00 00 00       	mov    $0x0,%eax
	if ((code = envid2env(envid, &en,1))<0)
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
	if (code < 0)
f010448b:	85 f6                	test   %esi,%esi
f010448d:	0f 89 97 03 00 00    	jns    f010482a <syscall+0x574>
	{
		page_free(newpage);
f0104493:	83 ec 0c             	sub    $0xc,%esp
f0104496:	53                   	push   %ebx
f0104497:	e8 a8 cb ff ff       	call   f0101044 <page_free>
f010449c:	83 c4 10             	add    $0x10,%esp
		return code;
f010449f:	89 f0                	mov    %esi,%eax
f01044a1:	e9 84 03 00 00       	jmp    f010482a <syscall+0x574>
	struct Env* src_env;
	struct Env* dst_env;
	int errcode;
	
	//Check for valid src env id
	errcode = envid2env(srcenvid, &src_env, 1);
f01044a6:	83 ec 04             	sub    $0x4,%esp
f01044a9:	6a 01                	push   $0x1
f01044ab:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01044ae:	50                   	push   %eax
f01044af:	ff 75 0c             	pushl  0xc(%ebp)
f01044b2:	e8 42 eb ff ff       	call   f0102ff9 <envid2env>
f01044b7:	89 c2                	mov    %eax,%edx
	if (errcode < 0) 
f01044b9:	83 c4 10             	add    $0x10,%esp
f01044bc:	85 d2                	test   %edx,%edx
f01044be:	0f 88 66 03 00 00    	js     f010482a <syscall+0x574>
		return errcode;
	
	//Check for valid des env id
	errcode = envid2env(dstenvid, &dst_env, 1);
f01044c4:	83 ec 04             	sub    $0x4,%esp
f01044c7:	6a 01                	push   $0x1
f01044c9:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01044cc:	50                   	push   %eax
f01044cd:	ff 75 14             	pushl  0x14(%ebp)
f01044d0:	e8 24 eb ff ff       	call   f0102ff9 <envid2env>
	if (errcode < 0) 
f01044d5:	83 c4 10             	add    $0x10,%esp
f01044d8:	85 c0                	test   %eax,%eax
f01044da:	0f 88 4a 03 00 00    	js     f010482a <syscall+0x574>
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
f01044e0:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01044e7:	77 6d                	ja     f0104556 <syscall+0x2a0>
f01044e9:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f01044f0:	77 64                	ja     f0104556 <syscall+0x2a0>
f01044f2:	8b 45 10             	mov    0x10(%ebp),%eax
f01044f5:	0b 45 18             	or     0x18(%ebp),%eax
		return -E_INVAL;
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
f01044f8:	a9 ff 0f 00 00       	test   $0xfff,%eax
f01044fd:	75 61                	jne    f0104560 <syscall+0x2aa>
		return -E_INVAL;

	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
f01044ff:	83 ec 04             	sub    $0x4,%esp
f0104502:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104505:	50                   	push   %eax
f0104506:	ff 75 10             	pushl  0x10(%ebp)
f0104509:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010450c:	ff 70 60             	pushl  0x60(%eax)
f010450f:	e8 1a cd ff ff       	call   f010122e <page_lookup>
	if (!srcPage) 
f0104514:	83 c4 10             	add    $0x10,%esp
f0104517:	85 c0                	test   %eax,%eax
f0104519:	74 4f                	je     f010456a <syscall+0x2b4>
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f010451b:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f0104522:	74 50                	je     f0104574 <syscall+0x2be>
		return -E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
f0104524:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104527:	f6 02 02             	testb  $0x2,(%edx)
f010452a:	75 06                	jne    f0104532 <syscall+0x27c>
f010452c:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104530:	75 4c                	jne    f010457e <syscall+0x2c8>
		return -E_INVAL;
	}

	// mapping
	errcode = page_insert(dst_env->env_pgdir, srcPage, dstva, perm);
f0104532:	ff 75 1c             	pushl  0x1c(%ebp)
f0104535:	ff 75 18             	pushl  0x18(%ebp)
f0104538:	50                   	push   %eax
f0104539:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010453c:	ff 70 60             	pushl  0x60(%eax)
f010453f:	e8 b0 cd ff ff       	call   f01012f4 <page_insert>
f0104544:	83 c4 10             	add    $0x10,%esp
f0104547:	85 c0                	test   %eax,%eax
f0104549:	ba 00 00 00 00       	mov    $0x0,%edx
f010454e:	0f 4f c2             	cmovg  %edx,%eax
f0104551:	e9 d4 02 00 00       	jmp    f010482a <syscall+0x574>
	if (errcode < 0) 
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
		return -E_INVAL;
f0104556:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010455b:	e9 ca 02 00 00       	jmp    f010482a <syscall+0x574>
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
		return -E_INVAL;
f0104560:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104565:	e9 c0 02 00 00       	jmp    f010482a <syscall+0x574>
	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
	if (!srcPage) 
		return -E_INVAL;
f010456a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010456f:	e9 b6 02 00 00       	jmp    f010482a <syscall+0x574>
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return -E_INVAL; 	
f0104574:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104579:	e9 ac 02 00 00       	jmp    f010482a <syscall+0x574>
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
		return -E_INVAL;
f010457e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f0104583:	e9 a2 02 00 00       	jmp    f010482a <syscall+0x574>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env* en;
	//Check for valid envid
	int errcode = envid2env(envid, &en, 1);
f0104588:	83 ec 04             	sub    $0x4,%esp
f010458b:	6a 01                	push   $0x1
f010458d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104590:	50                   	push   %eax
f0104591:	ff 75 0c             	pushl  0xc(%ebp)
f0104594:	e8 60 ea ff ff       	call   f0102ff9 <envid2env>
	if (errcode < 0){ 
f0104599:	83 c4 10             	add    $0x10,%esp
f010459c:	85 c0                	test   %eax,%eax
f010459e:	0f 88 86 02 00 00    	js     f010482a <syscall+0x574>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
f01045a4:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01045ab:	77 27                	ja     f01045d4 <syscall+0x31e>
f01045ad:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01045b4:	75 28                	jne    f01045de <syscall+0x328>
		return -E_INVAL;
	}

	page_remove(en->env_pgdir, va);
f01045b6:	83 ec 08             	sub    $0x8,%esp
f01045b9:	ff 75 10             	pushl  0x10(%ebp)
f01045bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045bf:	ff 70 60             	pushl  0x60(%eax)
f01045c2:	e8 e7 cc ff ff       	call   f01012ae <page_remove>
f01045c7:	83 c4 10             	add    $0x10,%esp

	return 0;
f01045ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01045cf:	e9 56 02 00 00       	jmp    f010482a <syscall+0x574>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
		return -E_INVAL;
f01045d4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045d9:	e9 4c 02 00 00       	jmp    f010482a <syscall+0x574>
f01045de:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f01045e3:	e9 42 02 00 00       	jmp    f010482a <syscall+0x574>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here. //Exercise 8 code
	struct Env* en;
	int errcode = envid2env(envid, &en, 1);
f01045e8:	83 ec 04             	sub    $0x4,%esp
f01045eb:	6a 01                	push   $0x1
f01045ed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045f0:	50                   	push   %eax
f01045f1:	ff 75 0c             	pushl  0xc(%ebp)
f01045f4:	e8 00 ea ff ff       	call   f0102ff9 <envid2env>
	if (errcode < 0) {
f01045f9:	83 c4 10             	add    $0x10,%esp
f01045fc:	85 c0                	test   %eax,%eax
f01045fe:	0f 88 26 02 00 00    	js     f010482a <syscall+0x574>
		return errcode;
	}

	//Set the pgfault_upcall to func
	en->env_pgfault_upcall = func;
f0104604:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104607:	8b 7d 10             	mov    0x10(%ebp),%edi
f010460a:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f010460d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104612:	e9 13 02 00 00       	jmp    f010482a <syscall+0x574>
	// LAB 4: Your code here.
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
f0104617:	83 ec 04             	sub    $0x4,%esp
f010461a:	6a 00                	push   $0x0
f010461c:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010461f:	50                   	push   %eax
f0104620:	ff 75 0c             	pushl  0xc(%ebp)
f0104623:	e8 d1 e9 ff ff       	call   f0102ff9 <envid2env>
f0104628:	83 c4 10             	add    $0x10,%esp
f010462b:	85 c0                	test   %eax,%eax
f010462d:	0f 88 0d 01 00 00    	js     f0104740 <syscall+0x48a>
		return -E_BAD_ENV; 
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
f0104633:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104636:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f010463a:	0f 84 0a 01 00 00    	je     f010474a <syscall+0x494>
		return -E_IPC_NOT_RECV;
	
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
f0104640:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104647:	0f 87 b0 00 00 00    	ja     f01046fd <syscall+0x447>
f010464d:	81 78 6c ff ff bf ee 	cmpl   $0xeebfffff,0x6c(%eax)
f0104654:	0f 87 a3 00 00 00    	ja     f01046fd <syscall+0x447>
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
			return -E_INVAL;
f010465a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
f010465f:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f0104666:	0f 85 be 01 00 00    	jne    f010482a <syscall+0x574>
			return -E_INVAL;
	
		//Check for permissions
		if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f010466c:	f7 45 18 fd f1 ff ff 	testl  $0xfffff1fd,0x18(%ebp)
f0104673:	0f 84 b1 01 00 00    	je     f010482a <syscall+0x574>
			return -E_INVAL;

		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
f0104679:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
f0104680:	e8 6a 13 00 00       	call   f01059ef <cpunum>
f0104685:	83 ec 04             	sub    $0x4,%esp
f0104688:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010468b:	52                   	push   %edx
f010468c:	ff 75 14             	pushl  0x14(%ebp)
f010468f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104692:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0104698:	ff 70 60             	pushl  0x60(%eax)
f010469b:	e8 8e cb ff ff       	call   f010122e <page_lookup>
f01046a0:	89 c2                	mov    %eax,%edx
f01046a2:	83 c4 10             	add    $0x10,%esp
f01046a5:	85 c0                	test   %eax,%eax
f01046a7:	74 40                	je     f01046e9 <syscall+0x433>
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f01046a9:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f01046ad:	74 11                	je     f01046c0 <syscall+0x40a>
			return -E_INVAL; 
f01046af:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f01046b4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01046b7:	f6 01 02             	testb  $0x2,(%ecx)
f01046ba:	0f 84 6a 01 00 00    	je     f010482a <syscall+0x574>
			return -E_INVAL; 
		
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
f01046c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046c3:	8b 48 6c             	mov    0x6c(%eax),%ecx
f01046c6:	85 c9                	test   %ecx,%ecx
f01046c8:	74 14                	je     f01046de <syscall+0x428>
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
f01046ca:	ff 75 18             	pushl  0x18(%ebp)
f01046cd:	51                   	push   %ecx
f01046ce:	52                   	push   %edx
f01046cf:	ff 70 60             	pushl  0x60(%eax)
f01046d2:	e8 1d cc ff ff       	call   f01012f4 <page_insert>
f01046d7:	83 c4 10             	add    $0x10,%esp
f01046da:	85 c0                	test   %eax,%eax
f01046dc:	78 15                	js     f01046f3 <syscall+0x43d>
				return -E_NO_MEM;
			
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
f01046de:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046e1:	8b 5d 18             	mov    0x18(%ebp),%ebx
f01046e4:	89 58 78             	mov    %ebx,0x78(%eax)
f01046e7:	eb 1b                	jmp    f0104704 <syscall+0x44e>
		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
f01046e9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01046ee:	e9 37 01 00 00       	jmp    f010482a <syscall+0x574>
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
				return -E_NO_MEM;
f01046f3:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01046f8:	e9 2d 01 00 00       	jmp    f010482a <syscall+0x574>
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
	}
	else{
		target_env->env_ipc_perm = 0; //  0 otherwise. 
f01046fd:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
	}
	
	target_env->env_ipc_recving  = 0; //is set to 0 to block future sends
f0104704:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104707:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	target_env->env_ipc_from = curenv->env_id; // is set to the sending envid;
f010470b:	e8 df 12 00 00       	call   f01059ef <cpunum>
f0104710:	6b c0 74             	imul   $0x74,%eax,%eax
f0104713:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0104719:	8b 40 48             	mov    0x48(%eax),%eax
f010471c:	89 43 74             	mov    %eax,0x74(%ebx)
	target_env->env_tf.tf_regs.reg_eax = 0;
f010471f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104722:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	target_env->env_ipc_value = value; // is set to the 'value' parameter;
f0104729:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010472c:	89 48 70             	mov    %ecx,0x70(%eax)
	target_env->env_status = ENV_RUNNABLE; 
f010472f:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	
	return 0;
f0104736:	b8 00 00 00 00       	mov    $0x0,%eax
f010473b:	e9 ea 00 00 00       	jmp    f010482a <syscall+0x574>
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
		return -E_BAD_ENV; 
f0104740:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104745:	e9 e0 00 00 00       	jmp    f010482a <syscall+0x574>
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
		return -E_IPC_NOT_RECV;
f010474a:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall((envid_t) a1, (void *)a2);

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);
f010474f:	e9 d6 00 00 00       	jmp    f010482a <syscall+0x574>
	//panic("sys_ipc_recv not implemented");

	//check if dstva is below UTOP
	
	
	if ((uint32_t)dstva < UTOP)
f0104754:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f010475b:	77 21                	ja     f010477e <syscall+0x4c8>
	{
		if ((uint32_t)dstva % PGSIZE !=0)
f010475d:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104764:	0f 85 bb 00 00 00    	jne    f0104825 <syscall+0x56f>
			return -E_INVAL;
		curenv->env_ipc_dstva = dstva;
f010476a:	e8 80 12 00 00       	call   f01059ef <cpunum>
f010476f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104772:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f0104778:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010477b:	89 58 6c             	mov    %ebx,0x6c(%eax)
	}
	
	//Enable receiving
	curenv->env_ipc_recving = 1;
f010477e:	e8 6c 12 00 00       	call   f01059ef <cpunum>
f0104783:	6b c0 74             	imul   $0x74,%eax,%eax
f0104786:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f010478c:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f0104790:	e8 5a 12 00 00       	call   f01059ef <cpunum>
f0104795:	6b c0 74             	imul   $0x74,%eax,%eax
f0104798:	8b 80 48 a0 20 f0    	mov    -0xfdf5fb8(%eax),%eax
f010479e:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f01047a5:	e8 2c fa ff ff       	call   f01041d6 <sched_yield>

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
f01047aa:	8b 75 10             	mov    0x10(%ebp),%esi
	struct Env *e;
	int r;

	//user_mem_assert(curenv, tf, sizeof(struct Trapframe), 0);
	
	if  ( (r= envid2env(envid, &e, 1)) < 0 ) {
f01047ad:	83 ec 04             	sub    $0x4,%esp
f01047b0:	6a 01                	push   $0x1
f01047b2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01047b5:	50                   	push   %eax
f01047b6:	ff 75 0c             	pushl  0xc(%ebp)
f01047b9:	e8 3b e8 ff ff       	call   f0102ff9 <envid2env>
f01047be:	83 c4 10             	add    $0x10,%esp
f01047c1:	85 c0                	test   %eax,%eax
f01047c3:	79 15                	jns    f01047da <syscall+0x524>
	    panic("Bad or stale environment in kern/syscall.c/sys_env_set_st : %e \n",r); 
f01047c5:	50                   	push   %eax
f01047c6:	68 f0 78 10 f0       	push   $0xf01078f0
f01047cb:	68 a2 00 00 00       	push   $0xa2
f01047d0:	68 cb 78 10 f0       	push   $0xf01078cb
f01047d5:	e8 66 b8 ff ff       	call   f0100040 <_panic>
	    return r;	
	}
	e->env_tf = *tf;
f01047da:	b9 11 00 00 00       	mov    $0x11,%ecx
f01047df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01047e2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	e->env_tf.tf_ds |= 3;
f01047e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01047e7:	66 83 48 24 03       	orw    $0x3,0x24(%eax)
	e->env_tf.tf_es |= 3;
f01047ec:	66 83 48 20 03       	orw    $0x3,0x20(%eax)
	e->env_tf.tf_ss |= 3;
f01047f1:	66 83 48 40 03       	orw    $0x3,0x40(%eax)
	e->env_tf.tf_cs |= 3;
f01047f6:	66 83 48 34 03       	orw    $0x3,0x34(%eax)
	// Make sure CPL = 3, interrupts enabled.
	e->env_tf.tf_eflags |= FL_IF;
	e->env_tf.tf_eflags &= ~(FL_IOPL_MASK);
f01047fb:	8b 50 38             	mov    0x38(%eax),%edx
f01047fe:	80 e6 cf             	and    $0xcf,%dh
f0104801:	80 ce 02             	or     $0x2,%dh
f0104804:	89 50 38             	mov    %edx,0x38(%eax)

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);

	case SYS_env_set_trapframe:
		return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
f0104807:	b8 00 00 00 00       	mov    $0x0,%eax
f010480c:	eb 1c                	jmp    f010482a <syscall+0x574>
		
	default:
		panic("Invalid System Call \n");
f010480e:	83 ec 04             	sub    $0x4,%esp
f0104811:	68 da 78 10 f0       	push   $0xf01078da
f0104816:	68 37 02 00 00       	push   $0x237
f010481b:	68 cb 78 10 f0       	push   $0xf01078cb
f0104820:	e8 1b b8 ff ff       	call   f0100040 <_panic>

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
f0104825:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		
	default:
		panic("Invalid System Call \n");
		return -E_INVAL;
	}
}
f010482a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010482d:	5b                   	pop    %ebx
f010482e:	5e                   	pop    %esi
f010482f:	5f                   	pop    %edi
f0104830:	5d                   	pop    %ebp
f0104831:	c3                   	ret    

f0104832 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104832:	55                   	push   %ebp
f0104833:	89 e5                	mov    %esp,%ebp
f0104835:	57                   	push   %edi
f0104836:	56                   	push   %esi
f0104837:	53                   	push   %ebx
f0104838:	83 ec 14             	sub    $0x14,%esp
f010483b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010483e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104841:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104844:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104847:	8b 1a                	mov    (%edx),%ebx
f0104849:	8b 01                	mov    (%ecx),%eax
f010484b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010484e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104855:	e9 88 00 00 00       	jmp    f01048e2 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f010485a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010485d:	01 d8                	add    %ebx,%eax
f010485f:	89 c6                	mov    %eax,%esi
f0104861:	c1 ee 1f             	shr    $0x1f,%esi
f0104864:	01 c6                	add    %eax,%esi
f0104866:	d1 fe                	sar    %esi
f0104868:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010486b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010486e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104871:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104873:	eb 03                	jmp    f0104878 <stab_binsearch+0x46>
			m--;
f0104875:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104878:	39 c3                	cmp    %eax,%ebx
f010487a:	7f 1f                	jg     f010489b <stab_binsearch+0x69>
f010487c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104880:	83 ea 0c             	sub    $0xc,%edx
f0104883:	39 f9                	cmp    %edi,%ecx
f0104885:	75 ee                	jne    f0104875 <stab_binsearch+0x43>
f0104887:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010488a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010488d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104890:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104894:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104897:	76 18                	jbe    f01048b1 <stab_binsearch+0x7f>
f0104899:	eb 05                	jmp    f01048a0 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010489b:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010489e:	eb 42                	jmp    f01048e2 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01048a0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01048a3:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01048a5:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048a8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048af:	eb 31                	jmp    f01048e2 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01048b1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048b4:	73 17                	jae    f01048cd <stab_binsearch+0x9b>
			*region_right = m - 1;
f01048b6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01048b9:	83 e8 01             	sub    $0x1,%eax
f01048bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048bf:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048c2:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048c4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048cb:	eb 15                	jmp    f01048e2 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01048cd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048d0:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01048d3:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f01048d5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01048d9:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048db:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01048e2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01048e5:	0f 8e 6f ff ff ff    	jle    f010485a <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01048eb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01048ef:	75 0f                	jne    f0104900 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f01048f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048f4:	8b 00                	mov    (%eax),%eax
f01048f6:	83 e8 01             	sub    $0x1,%eax
f01048f9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048fc:	89 06                	mov    %eax,(%esi)
f01048fe:	eb 2c                	jmp    f010492c <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104900:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104903:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104905:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104908:	8b 0e                	mov    (%esi),%ecx
f010490a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010490d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104910:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104913:	eb 03                	jmp    f0104918 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104915:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104918:	39 c8                	cmp    %ecx,%eax
f010491a:	7e 0b                	jle    f0104927 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010491c:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104920:	83 ea 0c             	sub    $0xc,%edx
f0104923:	39 fb                	cmp    %edi,%ebx
f0104925:	75 ee                	jne    f0104915 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104927:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010492a:	89 06                	mov    %eax,(%esi)
	}
}
f010492c:	83 c4 14             	add    $0x14,%esp
f010492f:	5b                   	pop    %ebx
f0104930:	5e                   	pop    %esi
f0104931:	5f                   	pop    %edi
f0104932:	5d                   	pop    %ebp
f0104933:	c3                   	ret    

f0104934 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104934:	55                   	push   %ebp
f0104935:	89 e5                	mov    %esp,%ebp
f0104937:	57                   	push   %edi
f0104938:	56                   	push   %esi
f0104939:	53                   	push   %ebx
f010493a:	83 ec 3c             	sub    $0x3c,%esp
f010493d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104940:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104943:	c7 06 6c 79 10 f0    	movl   $0xf010796c,(%esi)
	info->eip_line = 0;
f0104949:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104950:	c7 46 08 6c 79 10 f0 	movl   $0xf010796c,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104957:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010495e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104961:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104968:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010496e:	0f 87 a4 00 00 00    	ja     f0104a18 <debuginfo_eip+0xe4>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f0104974:	e8 76 10 00 00       	call   f01059ef <cpunum>
f0104979:	6a 05                	push   $0x5
f010497b:	6a 10                	push   $0x10
f010497d:	68 00 00 20 00       	push   $0x200000
f0104982:	6b c0 74             	imul   $0x74,%eax,%eax
f0104985:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f010498b:	e8 a5 e4 ff ff       	call   f0102e35 <user_mem_check>
f0104990:	83 c4 10             	add    $0x10,%esp
f0104993:	85 c0                	test   %eax,%eax
f0104995:	0f 88 24 02 00 00    	js     f0104bbf <debuginfo_eip+0x28b>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f010499b:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f01049a0:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01049a6:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01049ac:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01049af:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01049b5:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f01049b8:	89 d9                	mov    %ebx,%ecx
f01049ba:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01049bd:	29 c1                	sub    %eax,%ecx
f01049bf:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f01049c2:	e8 28 10 00 00       	call   f01059ef <cpunum>
f01049c7:	6a 05                	push   $0x5
f01049c9:	ff 75 b8             	pushl  -0x48(%ebp)
f01049cc:	ff 75 c4             	pushl  -0x3c(%ebp)
f01049cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d2:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f01049d8:	e8 58 e4 ff ff       	call   f0102e35 <user_mem_check>
f01049dd:	83 c4 10             	add    $0x10,%esp
f01049e0:	85 c0                	test   %eax,%eax
f01049e2:	0f 88 de 01 00 00    	js     f0104bc6 <debuginfo_eip+0x292>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f01049e8:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01049eb:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01049ee:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01049f1:	e8 f9 0f 00 00       	call   f01059ef <cpunum>
f01049f6:	6a 05                	push   $0x5
f01049f8:	ff 75 b8             	pushl  -0x48(%ebp)
f01049fb:	ff 75 c0             	pushl  -0x40(%ebp)
f01049fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a01:	ff b0 48 a0 20 f0    	pushl  -0xfdf5fb8(%eax)
f0104a07:	e8 29 e4 ff ff       	call   f0102e35 <user_mem_check>
f0104a0c:	83 c4 10             	add    $0x10,%esp
f0104a0f:	85 c0                	test   %eax,%eax
f0104a11:	79 1f                	jns    f0104a32 <debuginfo_eip+0xfe>
f0104a13:	e9 b5 01 00 00       	jmp    f0104bcd <debuginfo_eip+0x299>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a18:	c7 45 bc 5f 5f 11 f0 	movl   $0xf0115f5f,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104a1f:	c7 45 c0 f1 27 11 f0 	movl   $0xf01127f1,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104a26:	bb f0 27 11 f0       	mov    $0xf01127f0,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104a2b:	c7 45 c4 30 7f 10 f0 	movl   $0xf0107f30,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104a32:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104a35:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104a38:	0f 83 96 01 00 00    	jae    f0104bd4 <debuginfo_eip+0x2a0>
f0104a3e:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104a42:	0f 85 93 01 00 00    	jne    f0104bdb <debuginfo_eip+0x2a7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104a48:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104a4f:	89 d8                	mov    %ebx,%eax
f0104a51:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104a54:	29 d8                	sub    %ebx,%eax
f0104a56:	c1 f8 02             	sar    $0x2,%eax
f0104a59:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104a5f:	83 e8 01             	sub    $0x1,%eax
f0104a62:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104a65:	83 ec 08             	sub    $0x8,%esp
f0104a68:	57                   	push   %edi
f0104a69:	6a 64                	push   $0x64
f0104a6b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104a6e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104a71:	89 d8                	mov    %ebx,%eax
f0104a73:	e8 ba fd ff ff       	call   f0104832 <stab_binsearch>
	if (lfile == 0)
f0104a78:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a7b:	83 c4 10             	add    $0x10,%esp
f0104a7e:	85 c0                	test   %eax,%eax
f0104a80:	0f 84 5c 01 00 00    	je     f0104be2 <debuginfo_eip+0x2ae>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104a86:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104a89:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a8c:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104a8f:	83 ec 08             	sub    $0x8,%esp
f0104a92:	57                   	push   %edi
f0104a93:	6a 24                	push   $0x24
f0104a95:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104a98:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104a9b:	89 d8                	mov    %ebx,%eax
f0104a9d:	e8 90 fd ff ff       	call   f0104832 <stab_binsearch>

	if (lfun <= rfun) {
f0104aa2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104aa5:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104aa8:	83 c4 10             	add    $0x10,%esp
f0104aab:	39 d8                	cmp    %ebx,%eax
f0104aad:	7f 32                	jg     f0104ae1 <debuginfo_eip+0x1ad>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104aaf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104ab2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104ab5:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0104ab8:	8b 11                	mov    (%ecx),%edx
f0104aba:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104abd:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104ac0:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104ac3:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104ac6:	73 09                	jae    f0104ad1 <debuginfo_eip+0x19d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104ac8:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104acb:	03 55 c0             	add    -0x40(%ebp),%edx
f0104ace:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104ad1:	8b 51 08             	mov    0x8(%ecx),%edx
f0104ad4:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104ad7:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104ad9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104adc:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0104adf:	eb 0f                	jmp    f0104af0 <debuginfo_eip+0x1bc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104ae1:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104ae4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ae7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104aea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104aed:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104af0:	83 ec 08             	sub    $0x8,%esp
f0104af3:	6a 3a                	push   $0x3a
f0104af5:	ff 76 08             	pushl  0x8(%esi)
f0104af8:	e8 b1 08 00 00       	call   f01053ae <strfind>
f0104afd:	2b 46 08             	sub    0x8(%esi),%eax
f0104b00:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0104b03:	83 c4 08             	add    $0x8,%esp
f0104b06:	57                   	push   %edi
f0104b07:	6a 44                	push   $0x44
f0104b09:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b0c:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b0f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104b12:	89 d8                	mov    %ebx,%eax
f0104b14:	e8 19 fd ff ff       	call   f0104832 <stab_binsearch>
	if (lline > rline) {
f0104b19:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b1c:	83 c4 10             	add    $0x10,%esp
f0104b1f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104b22:	0f 8f c1 00 00 00    	jg     f0104be9 <debuginfo_eip+0x2b5>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104b28:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104b2b:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0104b30:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104b33:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b39:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b3c:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0104b3f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104b42:	eb 06                	jmp    f0104b4a <debuginfo_eip+0x216>
f0104b44:	83 e8 01             	sub    $0x1,%eax
f0104b47:	83 ea 0c             	sub    $0xc,%edx
f0104b4a:	39 c7                	cmp    %eax,%edi
f0104b4c:	7f 2a                	jg     f0104b78 <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f0104b4e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104b52:	80 f9 84             	cmp    $0x84,%cl
f0104b55:	0f 84 9c 00 00 00    	je     f0104bf7 <debuginfo_eip+0x2c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104b5b:	80 f9 64             	cmp    $0x64,%cl
f0104b5e:	75 e4                	jne    f0104b44 <debuginfo_eip+0x210>
f0104b60:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104b64:	74 de                	je     f0104b44 <debuginfo_eip+0x210>
f0104b66:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104b69:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104b6c:	e9 8c 00 00 00       	jmp    f0104bfd <debuginfo_eip+0x2c9>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104b71:	03 55 c0             	add    -0x40(%ebp),%edx
f0104b74:	89 16                	mov    %edx,(%esi)
f0104b76:	eb 03                	jmp    f0104b7b <debuginfo_eip+0x247>
f0104b78:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104b7b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104b7e:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104b81:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104b86:	39 da                	cmp    %ebx,%edx
f0104b88:	0f 8d 8b 00 00 00    	jge    f0104c19 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
f0104b8e:	83 c2 01             	add    $0x1,%edx
f0104b91:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104b94:	89 d0                	mov    %edx,%eax
f0104b96:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104b99:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104b9c:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104b9f:	eb 04                	jmp    f0104ba5 <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104ba1:	83 46 14 01          	addl   $0x1,0x14(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104ba5:	39 c3                	cmp    %eax,%ebx
f0104ba7:	7e 47                	jle    f0104bf0 <debuginfo_eip+0x2bc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104ba9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104bad:	83 c0 01             	add    $0x1,%eax
f0104bb0:	83 c2 0c             	add    $0xc,%edx
f0104bb3:	80 f9 a0             	cmp    $0xa0,%cl
f0104bb6:	74 e9                	je     f0104ba1 <debuginfo_eip+0x26d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bbd:	eb 5a                	jmp    f0104c19 <debuginfo_eip+0x2e5>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104bbf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bc4:	eb 53                	jmp    f0104c19 <debuginfo_eip+0x2e5>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104bc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bcb:	eb 4c                	jmp    f0104c19 <debuginfo_eip+0x2e5>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0104bcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bd2:	eb 45                	jmp    f0104c19 <debuginfo_eip+0x2e5>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104bd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bd9:	eb 3e                	jmp    f0104c19 <debuginfo_eip+0x2e5>
f0104bdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104be0:	eb 37                	jmp    f0104c19 <debuginfo_eip+0x2e5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104be2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104be7:	eb 30                	jmp    f0104c19 <debuginfo_eip+0x2e5>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0104be9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bee:	eb 29                	jmp    f0104c19 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bf0:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bf5:	eb 22                	jmp    f0104c19 <debuginfo_eip+0x2e5>
f0104bf7:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104bfa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104bfd:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104c00:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104c03:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104c06:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104c09:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0104c0c:	39 c2                	cmp    %eax,%edx
f0104c0e:	0f 82 5d ff ff ff    	jb     f0104b71 <debuginfo_eip+0x23d>
f0104c14:	e9 62 ff ff ff       	jmp    f0104b7b <debuginfo_eip+0x247>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0104c19:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c1c:	5b                   	pop    %ebx
f0104c1d:	5e                   	pop    %esi
f0104c1e:	5f                   	pop    %edi
f0104c1f:	5d                   	pop    %ebp
f0104c20:	c3                   	ret    

f0104c21 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104c21:	55                   	push   %ebp
f0104c22:	89 e5                	mov    %esp,%ebp
f0104c24:	57                   	push   %edi
f0104c25:	56                   	push   %esi
f0104c26:	53                   	push   %ebx
f0104c27:	83 ec 1c             	sub    $0x1c,%esp
f0104c2a:	89 c7                	mov    %eax,%edi
f0104c2c:	89 d6                	mov    %edx,%esi
f0104c2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c31:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c34:	89 d1                	mov    %edx,%ecx
f0104c36:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c39:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104c3c:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c3f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104c42:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104c45:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104c4c:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0104c4f:	72 05                	jb     f0104c56 <printnum+0x35>
f0104c51:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0104c54:	77 3e                	ja     f0104c94 <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104c56:	83 ec 0c             	sub    $0xc,%esp
f0104c59:	ff 75 18             	pushl  0x18(%ebp)
f0104c5c:	83 eb 01             	sub    $0x1,%ebx
f0104c5f:	53                   	push   %ebx
f0104c60:	50                   	push   %eax
f0104c61:	83 ec 08             	sub    $0x8,%esp
f0104c64:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104c67:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c6a:	ff 75 dc             	pushl  -0x24(%ebp)
f0104c6d:	ff 75 d8             	pushl  -0x28(%ebp)
f0104c70:	e8 7b 11 00 00       	call   f0105df0 <__udivdi3>
f0104c75:	83 c4 18             	add    $0x18,%esp
f0104c78:	52                   	push   %edx
f0104c79:	50                   	push   %eax
f0104c7a:	89 f2                	mov    %esi,%edx
f0104c7c:	89 f8                	mov    %edi,%eax
f0104c7e:	e8 9e ff ff ff       	call   f0104c21 <printnum>
f0104c83:	83 c4 20             	add    $0x20,%esp
f0104c86:	eb 13                	jmp    f0104c9b <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104c88:	83 ec 08             	sub    $0x8,%esp
f0104c8b:	56                   	push   %esi
f0104c8c:	ff 75 18             	pushl  0x18(%ebp)
f0104c8f:	ff d7                	call   *%edi
f0104c91:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104c94:	83 eb 01             	sub    $0x1,%ebx
f0104c97:	85 db                	test   %ebx,%ebx
f0104c99:	7f ed                	jg     f0104c88 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104c9b:	83 ec 08             	sub    $0x8,%esp
f0104c9e:	56                   	push   %esi
f0104c9f:	83 ec 04             	sub    $0x4,%esp
f0104ca2:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104ca5:	ff 75 e0             	pushl  -0x20(%ebp)
f0104ca8:	ff 75 dc             	pushl  -0x24(%ebp)
f0104cab:	ff 75 d8             	pushl  -0x28(%ebp)
f0104cae:	e8 6d 12 00 00       	call   f0105f20 <__umoddi3>
f0104cb3:	83 c4 14             	add    $0x14,%esp
f0104cb6:	0f be 80 76 79 10 f0 	movsbl -0xfef868a(%eax),%eax
f0104cbd:	50                   	push   %eax
f0104cbe:	ff d7                	call   *%edi
f0104cc0:	83 c4 10             	add    $0x10,%esp
}
f0104cc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104cc6:	5b                   	pop    %ebx
f0104cc7:	5e                   	pop    %esi
f0104cc8:	5f                   	pop    %edi
f0104cc9:	5d                   	pop    %ebp
f0104cca:	c3                   	ret    

f0104ccb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104ccb:	55                   	push   %ebp
f0104ccc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104cce:	83 fa 01             	cmp    $0x1,%edx
f0104cd1:	7e 0e                	jle    f0104ce1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104cd3:	8b 10                	mov    (%eax),%edx
f0104cd5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104cd8:	89 08                	mov    %ecx,(%eax)
f0104cda:	8b 02                	mov    (%edx),%eax
f0104cdc:	8b 52 04             	mov    0x4(%edx),%edx
f0104cdf:	eb 22                	jmp    f0104d03 <getuint+0x38>
	else if (lflag)
f0104ce1:	85 d2                	test   %edx,%edx
f0104ce3:	74 10                	je     f0104cf5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104ce5:	8b 10                	mov    (%eax),%edx
f0104ce7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104cea:	89 08                	mov    %ecx,(%eax)
f0104cec:	8b 02                	mov    (%edx),%eax
f0104cee:	ba 00 00 00 00       	mov    $0x0,%edx
f0104cf3:	eb 0e                	jmp    f0104d03 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104cf5:	8b 10                	mov    (%eax),%edx
f0104cf7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104cfa:	89 08                	mov    %ecx,(%eax)
f0104cfc:	8b 02                	mov    (%edx),%eax
f0104cfe:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104d03:	5d                   	pop    %ebp
f0104d04:	c3                   	ret    

f0104d05 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104d05:	55                   	push   %ebp
f0104d06:	89 e5                	mov    %esp,%ebp
f0104d08:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104d0b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104d0f:	8b 10                	mov    (%eax),%edx
f0104d11:	3b 50 04             	cmp    0x4(%eax),%edx
f0104d14:	73 0a                	jae    f0104d20 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104d16:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104d19:	89 08                	mov    %ecx,(%eax)
f0104d1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d1e:	88 02                	mov    %al,(%edx)
}
f0104d20:	5d                   	pop    %ebp
f0104d21:	c3                   	ret    

f0104d22 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104d22:	55                   	push   %ebp
f0104d23:	89 e5                	mov    %esp,%ebp
f0104d25:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104d28:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104d2b:	50                   	push   %eax
f0104d2c:	ff 75 10             	pushl  0x10(%ebp)
f0104d2f:	ff 75 0c             	pushl  0xc(%ebp)
f0104d32:	ff 75 08             	pushl  0x8(%ebp)
f0104d35:	e8 05 00 00 00       	call   f0104d3f <vprintfmt>
	va_end(ap);
f0104d3a:	83 c4 10             	add    $0x10,%esp
}
f0104d3d:	c9                   	leave  
f0104d3e:	c3                   	ret    

f0104d3f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104d3f:	55                   	push   %ebp
f0104d40:	89 e5                	mov    %esp,%ebp
f0104d42:	57                   	push   %edi
f0104d43:	56                   	push   %esi
f0104d44:	53                   	push   %ebx
f0104d45:	83 ec 2c             	sub    $0x2c,%esp
f0104d48:	8b 75 08             	mov    0x8(%ebp),%esi
f0104d4b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d4e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104d51:	eb 12                	jmp    f0104d65 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104d53:	85 c0                	test   %eax,%eax
f0104d55:	0f 84 90 03 00 00    	je     f01050eb <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0104d5b:	83 ec 08             	sub    $0x8,%esp
f0104d5e:	53                   	push   %ebx
f0104d5f:	50                   	push   %eax
f0104d60:	ff d6                	call   *%esi
f0104d62:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104d65:	83 c7 01             	add    $0x1,%edi
f0104d68:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104d6c:	83 f8 25             	cmp    $0x25,%eax
f0104d6f:	75 e2                	jne    f0104d53 <vprintfmt+0x14>
f0104d71:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104d75:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104d7c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104d83:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104d8a:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d8f:	eb 07                	jmp    f0104d98 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d91:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104d94:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d98:	8d 47 01             	lea    0x1(%edi),%eax
f0104d9b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104d9e:	0f b6 07             	movzbl (%edi),%eax
f0104da1:	0f b6 c8             	movzbl %al,%ecx
f0104da4:	83 e8 23             	sub    $0x23,%eax
f0104da7:	3c 55                	cmp    $0x55,%al
f0104da9:	0f 87 21 03 00 00    	ja     f01050d0 <vprintfmt+0x391>
f0104daf:	0f b6 c0             	movzbl %al,%eax
f0104db2:	ff 24 85 c0 7a 10 f0 	jmp    *-0xfef8540(,%eax,4)
f0104db9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104dbc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104dc0:	eb d6                	jmp    f0104d98 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dc2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104dc5:	b8 00 00 00 00       	mov    $0x0,%eax
f0104dca:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104dcd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104dd0:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104dd4:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104dd7:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104dda:	83 fa 09             	cmp    $0x9,%edx
f0104ddd:	77 39                	ja     f0104e18 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104ddf:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104de2:	eb e9                	jmp    f0104dcd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104de4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104de7:	8d 48 04             	lea    0x4(%eax),%ecx
f0104dea:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104ded:	8b 00                	mov    (%eax),%eax
f0104def:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104df2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104df5:	eb 27                	jmp    f0104e1e <vprintfmt+0xdf>
f0104df7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dfa:	85 c0                	test   %eax,%eax
f0104dfc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104e01:	0f 49 c8             	cmovns %eax,%ecx
f0104e04:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e0a:	eb 8c                	jmp    f0104d98 <vprintfmt+0x59>
f0104e0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104e0f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104e16:	eb 80                	jmp    f0104d98 <vprintfmt+0x59>
f0104e18:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e1b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104e1e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104e22:	0f 89 70 ff ff ff    	jns    f0104d98 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104e28:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104e2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e2e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e35:	e9 5e ff ff ff       	jmp    f0104d98 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104e3a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104e40:	e9 53 ff ff ff       	jmp    f0104d98 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104e45:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e48:	8d 50 04             	lea    0x4(%eax),%edx
f0104e4b:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e4e:	83 ec 08             	sub    $0x8,%esp
f0104e51:	53                   	push   %ebx
f0104e52:	ff 30                	pushl  (%eax)
f0104e54:	ff d6                	call   *%esi
			break;
f0104e56:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e59:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104e5c:	e9 04 ff ff ff       	jmp    f0104d65 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104e61:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e64:	8d 50 04             	lea    0x4(%eax),%edx
f0104e67:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e6a:	8b 00                	mov    (%eax),%eax
f0104e6c:	99                   	cltd   
f0104e6d:	31 d0                	xor    %edx,%eax
f0104e6f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104e71:	83 f8 0f             	cmp    $0xf,%eax
f0104e74:	7f 0b                	jg     f0104e81 <vprintfmt+0x142>
f0104e76:	8b 14 85 40 7c 10 f0 	mov    -0xfef83c0(,%eax,4),%edx
f0104e7d:	85 d2                	test   %edx,%edx
f0104e7f:	75 18                	jne    f0104e99 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104e81:	50                   	push   %eax
f0104e82:	68 8e 79 10 f0       	push   $0xf010798e
f0104e87:	53                   	push   %ebx
f0104e88:	56                   	push   %esi
f0104e89:	e8 94 fe ff ff       	call   f0104d22 <printfmt>
f0104e8e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104e94:	e9 cc fe ff ff       	jmp    f0104d65 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104e99:	52                   	push   %edx
f0104e9a:	68 ad 70 10 f0       	push   $0xf01070ad
f0104e9f:	53                   	push   %ebx
f0104ea0:	56                   	push   %esi
f0104ea1:	e8 7c fe ff ff       	call   f0104d22 <printfmt>
f0104ea6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ea9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104eac:	e9 b4 fe ff ff       	jmp    f0104d65 <vprintfmt+0x26>
f0104eb1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104eb4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104eb7:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104eba:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ebd:	8d 50 04             	lea    0x4(%eax),%edx
f0104ec0:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ec3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104ec5:	85 ff                	test   %edi,%edi
f0104ec7:	ba 87 79 10 f0       	mov    $0xf0107987,%edx
f0104ecc:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0104ecf:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104ed3:	0f 84 92 00 00 00    	je     f0104f6b <vprintfmt+0x22c>
f0104ed9:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104edd:	0f 8e 96 00 00 00    	jle    f0104f79 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ee3:	83 ec 08             	sub    $0x8,%esp
f0104ee6:	51                   	push   %ecx
f0104ee7:	57                   	push   %edi
f0104ee8:	e8 77 03 00 00       	call   f0105264 <strnlen>
f0104eed:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104ef0:	29 c1                	sub    %eax,%ecx
f0104ef2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104ef5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104ef8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104efc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104eff:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104f02:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f04:	eb 0f                	jmp    f0104f15 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104f06:	83 ec 08             	sub    $0x8,%esp
f0104f09:	53                   	push   %ebx
f0104f0a:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f0d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f0f:	83 ef 01             	sub    $0x1,%edi
f0104f12:	83 c4 10             	add    $0x10,%esp
f0104f15:	85 ff                	test   %edi,%edi
f0104f17:	7f ed                	jg     f0104f06 <vprintfmt+0x1c7>
f0104f19:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104f1c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f1f:	85 c9                	test   %ecx,%ecx
f0104f21:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f26:	0f 49 c1             	cmovns %ecx,%eax
f0104f29:	29 c1                	sub    %eax,%ecx
f0104f2b:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f2e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f31:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f34:	89 cb                	mov    %ecx,%ebx
f0104f36:	eb 4d                	jmp    f0104f85 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104f38:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104f3c:	74 1b                	je     f0104f59 <vprintfmt+0x21a>
f0104f3e:	0f be c0             	movsbl %al,%eax
f0104f41:	83 e8 20             	sub    $0x20,%eax
f0104f44:	83 f8 5e             	cmp    $0x5e,%eax
f0104f47:	76 10                	jbe    f0104f59 <vprintfmt+0x21a>
					putch('?', putdat);
f0104f49:	83 ec 08             	sub    $0x8,%esp
f0104f4c:	ff 75 0c             	pushl  0xc(%ebp)
f0104f4f:	6a 3f                	push   $0x3f
f0104f51:	ff 55 08             	call   *0x8(%ebp)
f0104f54:	83 c4 10             	add    $0x10,%esp
f0104f57:	eb 0d                	jmp    f0104f66 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104f59:	83 ec 08             	sub    $0x8,%esp
f0104f5c:	ff 75 0c             	pushl  0xc(%ebp)
f0104f5f:	52                   	push   %edx
f0104f60:	ff 55 08             	call   *0x8(%ebp)
f0104f63:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104f66:	83 eb 01             	sub    $0x1,%ebx
f0104f69:	eb 1a                	jmp    f0104f85 <vprintfmt+0x246>
f0104f6b:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f6e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f71:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f74:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104f77:	eb 0c                	jmp    f0104f85 <vprintfmt+0x246>
f0104f79:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f7c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f7f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f82:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104f85:	83 c7 01             	add    $0x1,%edi
f0104f88:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104f8c:	0f be d0             	movsbl %al,%edx
f0104f8f:	85 d2                	test   %edx,%edx
f0104f91:	74 23                	je     f0104fb6 <vprintfmt+0x277>
f0104f93:	85 f6                	test   %esi,%esi
f0104f95:	78 a1                	js     f0104f38 <vprintfmt+0x1f9>
f0104f97:	83 ee 01             	sub    $0x1,%esi
f0104f9a:	79 9c                	jns    f0104f38 <vprintfmt+0x1f9>
f0104f9c:	89 df                	mov    %ebx,%edi
f0104f9e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fa1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fa4:	eb 18                	jmp    f0104fbe <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104fa6:	83 ec 08             	sub    $0x8,%esp
f0104fa9:	53                   	push   %ebx
f0104faa:	6a 20                	push   $0x20
f0104fac:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104fae:	83 ef 01             	sub    $0x1,%edi
f0104fb1:	83 c4 10             	add    $0x10,%esp
f0104fb4:	eb 08                	jmp    f0104fbe <vprintfmt+0x27f>
f0104fb6:	89 df                	mov    %ebx,%edi
f0104fb8:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fbb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fbe:	85 ff                	test   %edi,%edi
f0104fc0:	7f e4                	jg     f0104fa6 <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fc2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fc5:	e9 9b fd ff ff       	jmp    f0104d65 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104fca:	83 fa 01             	cmp    $0x1,%edx
f0104fcd:	7e 16                	jle    f0104fe5 <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f0104fcf:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fd2:	8d 50 08             	lea    0x8(%eax),%edx
f0104fd5:	89 55 14             	mov    %edx,0x14(%ebp)
f0104fd8:	8b 50 04             	mov    0x4(%eax),%edx
f0104fdb:	8b 00                	mov    (%eax),%eax
f0104fdd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104fe0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104fe3:	eb 32                	jmp    f0105017 <vprintfmt+0x2d8>
	else if (lflag)
f0104fe5:	85 d2                	test   %edx,%edx
f0104fe7:	74 18                	je     f0105001 <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f0104fe9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fec:	8d 50 04             	lea    0x4(%eax),%edx
f0104fef:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ff2:	8b 00                	mov    (%eax),%eax
f0104ff4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104ff7:	89 c1                	mov    %eax,%ecx
f0104ff9:	c1 f9 1f             	sar    $0x1f,%ecx
f0104ffc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104fff:	eb 16                	jmp    f0105017 <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f0105001:	8b 45 14             	mov    0x14(%ebp),%eax
f0105004:	8d 50 04             	lea    0x4(%eax),%edx
f0105007:	89 55 14             	mov    %edx,0x14(%ebp)
f010500a:	8b 00                	mov    (%eax),%eax
f010500c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010500f:	89 c1                	mov    %eax,%ecx
f0105011:	c1 f9 1f             	sar    $0x1f,%ecx
f0105014:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105017:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010501a:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010501d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105022:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105026:	79 74                	jns    f010509c <vprintfmt+0x35d>
				putch('-', putdat);
f0105028:	83 ec 08             	sub    $0x8,%esp
f010502b:	53                   	push   %ebx
f010502c:	6a 2d                	push   $0x2d
f010502e:	ff d6                	call   *%esi
				num = -(long long) num;
f0105030:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105033:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105036:	f7 d8                	neg    %eax
f0105038:	83 d2 00             	adc    $0x0,%edx
f010503b:	f7 da                	neg    %edx
f010503d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0105040:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105045:	eb 55                	jmp    f010509c <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105047:	8d 45 14             	lea    0x14(%ebp),%eax
f010504a:	e8 7c fc ff ff       	call   f0104ccb <getuint>
			base = 10;
f010504f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105054:	eb 46                	jmp    f010509c <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0105056:	8d 45 14             	lea    0x14(%ebp),%eax
f0105059:	e8 6d fc ff ff       	call   f0104ccb <getuint>
			base = 8;
f010505e:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105063:	eb 37                	jmp    f010509c <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0105065:	83 ec 08             	sub    $0x8,%esp
f0105068:	53                   	push   %ebx
f0105069:	6a 30                	push   $0x30
f010506b:	ff d6                	call   *%esi
			putch('x', putdat);
f010506d:	83 c4 08             	add    $0x8,%esp
f0105070:	53                   	push   %ebx
f0105071:	6a 78                	push   $0x78
f0105073:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0105075:	8b 45 14             	mov    0x14(%ebp),%eax
f0105078:	8d 50 04             	lea    0x4(%eax),%edx
f010507b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010507e:	8b 00                	mov    (%eax),%eax
f0105080:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0105085:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0105088:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010508d:	eb 0d                	jmp    f010509c <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010508f:	8d 45 14             	lea    0x14(%ebp),%eax
f0105092:	e8 34 fc ff ff       	call   f0104ccb <getuint>
			base = 16;
f0105097:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010509c:	83 ec 0c             	sub    $0xc,%esp
f010509f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01050a3:	57                   	push   %edi
f01050a4:	ff 75 e0             	pushl  -0x20(%ebp)
f01050a7:	51                   	push   %ecx
f01050a8:	52                   	push   %edx
f01050a9:	50                   	push   %eax
f01050aa:	89 da                	mov    %ebx,%edx
f01050ac:	89 f0                	mov    %esi,%eax
f01050ae:	e8 6e fb ff ff       	call   f0104c21 <printnum>
			break;
f01050b3:	83 c4 20             	add    $0x20,%esp
f01050b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050b9:	e9 a7 fc ff ff       	jmp    f0104d65 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01050be:	83 ec 08             	sub    $0x8,%esp
f01050c1:	53                   	push   %ebx
f01050c2:	51                   	push   %ecx
f01050c3:	ff d6                	call   *%esi
			break;
f01050c5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01050c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01050cb:	e9 95 fc ff ff       	jmp    f0104d65 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01050d0:	83 ec 08             	sub    $0x8,%esp
f01050d3:	53                   	push   %ebx
f01050d4:	6a 25                	push   $0x25
f01050d6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01050d8:	83 c4 10             	add    $0x10,%esp
f01050db:	eb 03                	jmp    f01050e0 <vprintfmt+0x3a1>
f01050dd:	83 ef 01             	sub    $0x1,%edi
f01050e0:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01050e4:	75 f7                	jne    f01050dd <vprintfmt+0x39e>
f01050e6:	e9 7a fc ff ff       	jmp    f0104d65 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01050eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01050ee:	5b                   	pop    %ebx
f01050ef:	5e                   	pop    %esi
f01050f0:	5f                   	pop    %edi
f01050f1:	5d                   	pop    %ebp
f01050f2:	c3                   	ret    

f01050f3 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01050f3:	55                   	push   %ebp
f01050f4:	89 e5                	mov    %esp,%ebp
f01050f6:	83 ec 18             	sub    $0x18,%esp
f01050f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01050fc:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01050ff:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105102:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105106:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105109:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105110:	85 c0                	test   %eax,%eax
f0105112:	74 26                	je     f010513a <vsnprintf+0x47>
f0105114:	85 d2                	test   %edx,%edx
f0105116:	7e 22                	jle    f010513a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105118:	ff 75 14             	pushl  0x14(%ebp)
f010511b:	ff 75 10             	pushl  0x10(%ebp)
f010511e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105121:	50                   	push   %eax
f0105122:	68 05 4d 10 f0       	push   $0xf0104d05
f0105127:	e8 13 fc ff ff       	call   f0104d3f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010512c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010512f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105132:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105135:	83 c4 10             	add    $0x10,%esp
f0105138:	eb 05                	jmp    f010513f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010513a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010513f:	c9                   	leave  
f0105140:	c3                   	ret    

f0105141 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105141:	55                   	push   %ebp
f0105142:	89 e5                	mov    %esp,%ebp
f0105144:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105147:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010514a:	50                   	push   %eax
f010514b:	ff 75 10             	pushl  0x10(%ebp)
f010514e:	ff 75 0c             	pushl  0xc(%ebp)
f0105151:	ff 75 08             	pushl  0x8(%ebp)
f0105154:	e8 9a ff ff ff       	call   f01050f3 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105159:	c9                   	leave  
f010515a:	c3                   	ret    

f010515b <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010515b:	55                   	push   %ebp
f010515c:	89 e5                	mov    %esp,%ebp
f010515e:	57                   	push   %edi
f010515f:	56                   	push   %esi
f0105160:	53                   	push   %ebx
f0105161:	83 ec 0c             	sub    $0xc,%esp
f0105164:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f0105167:	85 c0                	test   %eax,%eax
f0105169:	74 11                	je     f010517c <readline+0x21>
		cprintf("%s", prompt);
f010516b:	83 ec 08             	sub    $0x8,%esp
f010516e:	50                   	push   %eax
f010516f:	68 ad 70 10 f0       	push   $0xf01070ad
f0105174:	e8 a8 e6 ff ff       	call   f0103821 <cprintf>
f0105179:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f010517c:	83 ec 0c             	sub    $0xc,%esp
f010517f:	6a 00                	push   $0x0
f0105181:	e8 15 b6 ff ff       	call   f010079b <iscons>
f0105186:	89 c7                	mov    %eax,%edi
f0105188:	83 c4 10             	add    $0x10,%esp
#else
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
f010518b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105190:	e8 f5 b5 ff ff       	call   f010078a <getchar>
f0105195:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105197:	85 c0                	test   %eax,%eax
f0105199:	79 29                	jns    f01051c4 <readline+0x69>
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f010519b:	b8 00 00 00 00       	mov    $0x0,%eax
	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
f01051a0:	83 fb f8             	cmp    $0xfffffff8,%ebx
f01051a3:	0f 84 9b 00 00 00    	je     f0105244 <readline+0xe9>
				cprintf("read error: %e\n", c);
f01051a9:	83 ec 08             	sub    $0x8,%esp
f01051ac:	53                   	push   %ebx
f01051ad:	68 9f 7c 10 f0       	push   $0xf0107c9f
f01051b2:	e8 6a e6 ff ff       	call   f0103821 <cprintf>
f01051b7:	83 c4 10             	add    $0x10,%esp
			return NULL;
f01051ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01051bf:	e9 80 00 00 00       	jmp    f0105244 <readline+0xe9>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01051c4:	83 f8 7f             	cmp    $0x7f,%eax
f01051c7:	0f 94 c2             	sete   %dl
f01051ca:	83 f8 08             	cmp    $0x8,%eax
f01051cd:	0f 94 c0             	sete   %al
f01051d0:	08 c2                	or     %al,%dl
f01051d2:	74 1a                	je     f01051ee <readline+0x93>
f01051d4:	85 f6                	test   %esi,%esi
f01051d6:	7e 16                	jle    f01051ee <readline+0x93>
			if (echoing)
f01051d8:	85 ff                	test   %edi,%edi
f01051da:	74 0d                	je     f01051e9 <readline+0x8e>
				cputchar('\b');
f01051dc:	83 ec 0c             	sub    $0xc,%esp
f01051df:	6a 08                	push   $0x8
f01051e1:	e8 94 b5 ff ff       	call   f010077a <cputchar>
f01051e6:	83 c4 10             	add    $0x10,%esp
			i--;
f01051e9:	83 ee 01             	sub    $0x1,%esi
f01051ec:	eb a2                	jmp    f0105190 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01051ee:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01051f4:	7f 23                	jg     f0105219 <readline+0xbe>
f01051f6:	83 fb 1f             	cmp    $0x1f,%ebx
f01051f9:	7e 1e                	jle    f0105219 <readline+0xbe>
			if (echoing)
f01051fb:	85 ff                	test   %edi,%edi
f01051fd:	74 0c                	je     f010520b <readline+0xb0>
				cputchar(c);
f01051ff:	83 ec 0c             	sub    $0xc,%esp
f0105202:	53                   	push   %ebx
f0105203:	e8 72 b5 ff ff       	call   f010077a <cputchar>
f0105208:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010520b:	88 9e c0 9a 20 f0    	mov    %bl,-0xfdf6540(%esi)
f0105211:	8d 76 01             	lea    0x1(%esi),%esi
f0105214:	e9 77 ff ff ff       	jmp    f0105190 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105219:	83 fb 0d             	cmp    $0xd,%ebx
f010521c:	74 09                	je     f0105227 <readline+0xcc>
f010521e:	83 fb 0a             	cmp    $0xa,%ebx
f0105221:	0f 85 69 ff ff ff    	jne    f0105190 <readline+0x35>
			if (echoing)
f0105227:	85 ff                	test   %edi,%edi
f0105229:	74 0d                	je     f0105238 <readline+0xdd>
				cputchar('\n');
f010522b:	83 ec 0c             	sub    $0xc,%esp
f010522e:	6a 0a                	push   $0xa
f0105230:	e8 45 b5 ff ff       	call   f010077a <cputchar>
f0105235:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105238:	c6 86 c0 9a 20 f0 00 	movb   $0x0,-0xfdf6540(%esi)
			return buf;
f010523f:	b8 c0 9a 20 f0       	mov    $0xf0209ac0,%eax
		}
	}
}
f0105244:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105247:	5b                   	pop    %ebx
f0105248:	5e                   	pop    %esi
f0105249:	5f                   	pop    %edi
f010524a:	5d                   	pop    %ebp
f010524b:	c3                   	ret    

f010524c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010524c:	55                   	push   %ebp
f010524d:	89 e5                	mov    %esp,%ebp
f010524f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105252:	b8 00 00 00 00       	mov    $0x0,%eax
f0105257:	eb 03                	jmp    f010525c <strlen+0x10>
		n++;
f0105259:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010525c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105260:	75 f7                	jne    f0105259 <strlen+0xd>
		n++;
	return n;
}
f0105262:	5d                   	pop    %ebp
f0105263:	c3                   	ret    

f0105264 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105264:	55                   	push   %ebp
f0105265:	89 e5                	mov    %esp,%ebp
f0105267:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010526a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010526d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105272:	eb 03                	jmp    f0105277 <strnlen+0x13>
		n++;
f0105274:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105277:	39 c2                	cmp    %eax,%edx
f0105279:	74 08                	je     f0105283 <strnlen+0x1f>
f010527b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010527f:	75 f3                	jne    f0105274 <strnlen+0x10>
f0105281:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0105283:	5d                   	pop    %ebp
f0105284:	c3                   	ret    

f0105285 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105285:	55                   	push   %ebp
f0105286:	89 e5                	mov    %esp,%ebp
f0105288:	53                   	push   %ebx
f0105289:	8b 45 08             	mov    0x8(%ebp),%eax
f010528c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010528f:	89 c2                	mov    %eax,%edx
f0105291:	83 c2 01             	add    $0x1,%edx
f0105294:	83 c1 01             	add    $0x1,%ecx
f0105297:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010529b:	88 5a ff             	mov    %bl,-0x1(%edx)
f010529e:	84 db                	test   %bl,%bl
f01052a0:	75 ef                	jne    f0105291 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01052a2:	5b                   	pop    %ebx
f01052a3:	5d                   	pop    %ebp
f01052a4:	c3                   	ret    

f01052a5 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01052a5:	55                   	push   %ebp
f01052a6:	89 e5                	mov    %esp,%ebp
f01052a8:	53                   	push   %ebx
f01052a9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01052ac:	53                   	push   %ebx
f01052ad:	e8 9a ff ff ff       	call   f010524c <strlen>
f01052b2:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01052b5:	ff 75 0c             	pushl  0xc(%ebp)
f01052b8:	01 d8                	add    %ebx,%eax
f01052ba:	50                   	push   %eax
f01052bb:	e8 c5 ff ff ff       	call   f0105285 <strcpy>
	return dst;
}
f01052c0:	89 d8                	mov    %ebx,%eax
f01052c2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01052c5:	c9                   	leave  
f01052c6:	c3                   	ret    

f01052c7 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01052c7:	55                   	push   %ebp
f01052c8:	89 e5                	mov    %esp,%ebp
f01052ca:	56                   	push   %esi
f01052cb:	53                   	push   %ebx
f01052cc:	8b 75 08             	mov    0x8(%ebp),%esi
f01052cf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052d2:	89 f3                	mov    %esi,%ebx
f01052d4:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052d7:	89 f2                	mov    %esi,%edx
f01052d9:	eb 0f                	jmp    f01052ea <strncpy+0x23>
		*dst++ = *src;
f01052db:	83 c2 01             	add    $0x1,%edx
f01052de:	0f b6 01             	movzbl (%ecx),%eax
f01052e1:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01052e4:	80 39 01             	cmpb   $0x1,(%ecx)
f01052e7:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052ea:	39 da                	cmp    %ebx,%edx
f01052ec:	75 ed                	jne    f01052db <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01052ee:	89 f0                	mov    %esi,%eax
f01052f0:	5b                   	pop    %ebx
f01052f1:	5e                   	pop    %esi
f01052f2:	5d                   	pop    %ebp
f01052f3:	c3                   	ret    

f01052f4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01052f4:	55                   	push   %ebp
f01052f5:	89 e5                	mov    %esp,%ebp
f01052f7:	56                   	push   %esi
f01052f8:	53                   	push   %ebx
f01052f9:	8b 75 08             	mov    0x8(%ebp),%esi
f01052fc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052ff:	8b 55 10             	mov    0x10(%ebp),%edx
f0105302:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105304:	85 d2                	test   %edx,%edx
f0105306:	74 21                	je     f0105329 <strlcpy+0x35>
f0105308:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010530c:	89 f2                	mov    %esi,%edx
f010530e:	eb 09                	jmp    f0105319 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105310:	83 c2 01             	add    $0x1,%edx
f0105313:	83 c1 01             	add    $0x1,%ecx
f0105316:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105319:	39 c2                	cmp    %eax,%edx
f010531b:	74 09                	je     f0105326 <strlcpy+0x32>
f010531d:	0f b6 19             	movzbl (%ecx),%ebx
f0105320:	84 db                	test   %bl,%bl
f0105322:	75 ec                	jne    f0105310 <strlcpy+0x1c>
f0105324:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105326:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105329:	29 f0                	sub    %esi,%eax
}
f010532b:	5b                   	pop    %ebx
f010532c:	5e                   	pop    %esi
f010532d:	5d                   	pop    %ebp
f010532e:	c3                   	ret    

f010532f <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010532f:	55                   	push   %ebp
f0105330:	89 e5                	mov    %esp,%ebp
f0105332:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105335:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105338:	eb 06                	jmp    f0105340 <strcmp+0x11>
		p++, q++;
f010533a:	83 c1 01             	add    $0x1,%ecx
f010533d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105340:	0f b6 01             	movzbl (%ecx),%eax
f0105343:	84 c0                	test   %al,%al
f0105345:	74 04                	je     f010534b <strcmp+0x1c>
f0105347:	3a 02                	cmp    (%edx),%al
f0105349:	74 ef                	je     f010533a <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010534b:	0f b6 c0             	movzbl %al,%eax
f010534e:	0f b6 12             	movzbl (%edx),%edx
f0105351:	29 d0                	sub    %edx,%eax
}
f0105353:	5d                   	pop    %ebp
f0105354:	c3                   	ret    

f0105355 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105355:	55                   	push   %ebp
f0105356:	89 e5                	mov    %esp,%ebp
f0105358:	53                   	push   %ebx
f0105359:	8b 45 08             	mov    0x8(%ebp),%eax
f010535c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010535f:	89 c3                	mov    %eax,%ebx
f0105361:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105364:	eb 06                	jmp    f010536c <strncmp+0x17>
		n--, p++, q++;
f0105366:	83 c0 01             	add    $0x1,%eax
f0105369:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010536c:	39 d8                	cmp    %ebx,%eax
f010536e:	74 15                	je     f0105385 <strncmp+0x30>
f0105370:	0f b6 08             	movzbl (%eax),%ecx
f0105373:	84 c9                	test   %cl,%cl
f0105375:	74 04                	je     f010537b <strncmp+0x26>
f0105377:	3a 0a                	cmp    (%edx),%cl
f0105379:	74 eb                	je     f0105366 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010537b:	0f b6 00             	movzbl (%eax),%eax
f010537e:	0f b6 12             	movzbl (%edx),%edx
f0105381:	29 d0                	sub    %edx,%eax
f0105383:	eb 05                	jmp    f010538a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105385:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010538a:	5b                   	pop    %ebx
f010538b:	5d                   	pop    %ebp
f010538c:	c3                   	ret    

f010538d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010538d:	55                   	push   %ebp
f010538e:	89 e5                	mov    %esp,%ebp
f0105390:	8b 45 08             	mov    0x8(%ebp),%eax
f0105393:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105397:	eb 07                	jmp    f01053a0 <strchr+0x13>
		if (*s == c)
f0105399:	38 ca                	cmp    %cl,%dl
f010539b:	74 0f                	je     f01053ac <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010539d:	83 c0 01             	add    $0x1,%eax
f01053a0:	0f b6 10             	movzbl (%eax),%edx
f01053a3:	84 d2                	test   %dl,%dl
f01053a5:	75 f2                	jne    f0105399 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01053a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01053ac:	5d                   	pop    %ebp
f01053ad:	c3                   	ret    

f01053ae <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01053ae:	55                   	push   %ebp
f01053af:	89 e5                	mov    %esp,%ebp
f01053b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01053b4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01053b8:	eb 03                	jmp    f01053bd <strfind+0xf>
f01053ba:	83 c0 01             	add    $0x1,%eax
f01053bd:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01053c0:	84 d2                	test   %dl,%dl
f01053c2:	74 04                	je     f01053c8 <strfind+0x1a>
f01053c4:	38 ca                	cmp    %cl,%dl
f01053c6:	75 f2                	jne    f01053ba <strfind+0xc>
			break;
	return (char *) s;
}
f01053c8:	5d                   	pop    %ebp
f01053c9:	c3                   	ret    

f01053ca <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01053ca:	55                   	push   %ebp
f01053cb:	89 e5                	mov    %esp,%ebp
f01053cd:	57                   	push   %edi
f01053ce:	56                   	push   %esi
f01053cf:	53                   	push   %ebx
f01053d0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01053d3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01053d6:	85 c9                	test   %ecx,%ecx
f01053d8:	74 36                	je     f0105410 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01053da:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01053e0:	75 28                	jne    f010540a <memset+0x40>
f01053e2:	f6 c1 03             	test   $0x3,%cl
f01053e5:	75 23                	jne    f010540a <memset+0x40>
		c &= 0xFF;
f01053e7:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01053eb:	89 d3                	mov    %edx,%ebx
f01053ed:	c1 e3 08             	shl    $0x8,%ebx
f01053f0:	89 d6                	mov    %edx,%esi
f01053f2:	c1 e6 18             	shl    $0x18,%esi
f01053f5:	89 d0                	mov    %edx,%eax
f01053f7:	c1 e0 10             	shl    $0x10,%eax
f01053fa:	09 f0                	or     %esi,%eax
f01053fc:	09 c2                	or     %eax,%edx
f01053fe:	89 d0                	mov    %edx,%eax
f0105400:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105402:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0105405:	fc                   	cld    
f0105406:	f3 ab                	rep stos %eax,%es:(%edi)
f0105408:	eb 06                	jmp    f0105410 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010540a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010540d:	fc                   	cld    
f010540e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105410:	89 f8                	mov    %edi,%eax
f0105412:	5b                   	pop    %ebx
f0105413:	5e                   	pop    %esi
f0105414:	5f                   	pop    %edi
f0105415:	5d                   	pop    %ebp
f0105416:	c3                   	ret    

f0105417 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105417:	55                   	push   %ebp
f0105418:	89 e5                	mov    %esp,%ebp
f010541a:	57                   	push   %edi
f010541b:	56                   	push   %esi
f010541c:	8b 45 08             	mov    0x8(%ebp),%eax
f010541f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105422:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105425:	39 c6                	cmp    %eax,%esi
f0105427:	73 35                	jae    f010545e <memmove+0x47>
f0105429:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010542c:	39 d0                	cmp    %edx,%eax
f010542e:	73 2e                	jae    f010545e <memmove+0x47>
		s += n;
		d += n;
f0105430:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105433:	89 d6                	mov    %edx,%esi
f0105435:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105437:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010543d:	75 13                	jne    f0105452 <memmove+0x3b>
f010543f:	f6 c1 03             	test   $0x3,%cl
f0105442:	75 0e                	jne    f0105452 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105444:	83 ef 04             	sub    $0x4,%edi
f0105447:	8d 72 fc             	lea    -0x4(%edx),%esi
f010544a:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010544d:	fd                   	std    
f010544e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105450:	eb 09                	jmp    f010545b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105452:	83 ef 01             	sub    $0x1,%edi
f0105455:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105458:	fd                   	std    
f0105459:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010545b:	fc                   	cld    
f010545c:	eb 1d                	jmp    f010547b <memmove+0x64>
f010545e:	89 f2                	mov    %esi,%edx
f0105460:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105462:	f6 c2 03             	test   $0x3,%dl
f0105465:	75 0f                	jne    f0105476 <memmove+0x5f>
f0105467:	f6 c1 03             	test   $0x3,%cl
f010546a:	75 0a                	jne    f0105476 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010546c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010546f:	89 c7                	mov    %eax,%edi
f0105471:	fc                   	cld    
f0105472:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105474:	eb 05                	jmp    f010547b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105476:	89 c7                	mov    %eax,%edi
f0105478:	fc                   	cld    
f0105479:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010547b:	5e                   	pop    %esi
f010547c:	5f                   	pop    %edi
f010547d:	5d                   	pop    %ebp
f010547e:	c3                   	ret    

f010547f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010547f:	55                   	push   %ebp
f0105480:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0105482:	ff 75 10             	pushl  0x10(%ebp)
f0105485:	ff 75 0c             	pushl  0xc(%ebp)
f0105488:	ff 75 08             	pushl  0x8(%ebp)
f010548b:	e8 87 ff ff ff       	call   f0105417 <memmove>
}
f0105490:	c9                   	leave  
f0105491:	c3                   	ret    

f0105492 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105492:	55                   	push   %ebp
f0105493:	89 e5                	mov    %esp,%ebp
f0105495:	56                   	push   %esi
f0105496:	53                   	push   %ebx
f0105497:	8b 45 08             	mov    0x8(%ebp),%eax
f010549a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010549d:	89 c6                	mov    %eax,%esi
f010549f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054a2:	eb 1a                	jmp    f01054be <memcmp+0x2c>
		if (*s1 != *s2)
f01054a4:	0f b6 08             	movzbl (%eax),%ecx
f01054a7:	0f b6 1a             	movzbl (%edx),%ebx
f01054aa:	38 d9                	cmp    %bl,%cl
f01054ac:	74 0a                	je     f01054b8 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01054ae:	0f b6 c1             	movzbl %cl,%eax
f01054b1:	0f b6 db             	movzbl %bl,%ebx
f01054b4:	29 d8                	sub    %ebx,%eax
f01054b6:	eb 0f                	jmp    f01054c7 <memcmp+0x35>
		s1++, s2++;
f01054b8:	83 c0 01             	add    $0x1,%eax
f01054bb:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054be:	39 f0                	cmp    %esi,%eax
f01054c0:	75 e2                	jne    f01054a4 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01054c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01054c7:	5b                   	pop    %ebx
f01054c8:	5e                   	pop    %esi
f01054c9:	5d                   	pop    %ebp
f01054ca:	c3                   	ret    

f01054cb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01054cb:	55                   	push   %ebp
f01054cc:	89 e5                	mov    %esp,%ebp
f01054ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01054d1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01054d4:	89 c2                	mov    %eax,%edx
f01054d6:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01054d9:	eb 07                	jmp    f01054e2 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01054db:	38 08                	cmp    %cl,(%eax)
f01054dd:	74 07                	je     f01054e6 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01054df:	83 c0 01             	add    $0x1,%eax
f01054e2:	39 d0                	cmp    %edx,%eax
f01054e4:	72 f5                	jb     f01054db <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01054e6:	5d                   	pop    %ebp
f01054e7:	c3                   	ret    

f01054e8 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01054e8:	55                   	push   %ebp
f01054e9:	89 e5                	mov    %esp,%ebp
f01054eb:	57                   	push   %edi
f01054ec:	56                   	push   %esi
f01054ed:	53                   	push   %ebx
f01054ee:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054f1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054f4:	eb 03                	jmp    f01054f9 <strtol+0x11>
		s++;
f01054f6:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054f9:	0f b6 01             	movzbl (%ecx),%eax
f01054fc:	3c 09                	cmp    $0x9,%al
f01054fe:	74 f6                	je     f01054f6 <strtol+0xe>
f0105500:	3c 20                	cmp    $0x20,%al
f0105502:	74 f2                	je     f01054f6 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105504:	3c 2b                	cmp    $0x2b,%al
f0105506:	75 0a                	jne    f0105512 <strtol+0x2a>
		s++;
f0105508:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010550b:	bf 00 00 00 00       	mov    $0x0,%edi
f0105510:	eb 10                	jmp    f0105522 <strtol+0x3a>
f0105512:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105517:	3c 2d                	cmp    $0x2d,%al
f0105519:	75 07                	jne    f0105522 <strtol+0x3a>
		s++, neg = 1;
f010551b:	8d 49 01             	lea    0x1(%ecx),%ecx
f010551e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105522:	85 db                	test   %ebx,%ebx
f0105524:	0f 94 c0             	sete   %al
f0105527:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010552d:	75 19                	jne    f0105548 <strtol+0x60>
f010552f:	80 39 30             	cmpb   $0x30,(%ecx)
f0105532:	75 14                	jne    f0105548 <strtol+0x60>
f0105534:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105538:	0f 85 82 00 00 00    	jne    f01055c0 <strtol+0xd8>
		s += 2, base = 16;
f010553e:	83 c1 02             	add    $0x2,%ecx
f0105541:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105546:	eb 16                	jmp    f010555e <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105548:	84 c0                	test   %al,%al
f010554a:	74 12                	je     f010555e <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010554c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105551:	80 39 30             	cmpb   $0x30,(%ecx)
f0105554:	75 08                	jne    f010555e <strtol+0x76>
		s++, base = 8;
f0105556:	83 c1 01             	add    $0x1,%ecx
f0105559:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010555e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105563:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105566:	0f b6 11             	movzbl (%ecx),%edx
f0105569:	8d 72 d0             	lea    -0x30(%edx),%esi
f010556c:	89 f3                	mov    %esi,%ebx
f010556e:	80 fb 09             	cmp    $0x9,%bl
f0105571:	77 08                	ja     f010557b <strtol+0x93>
			dig = *s - '0';
f0105573:	0f be d2             	movsbl %dl,%edx
f0105576:	83 ea 30             	sub    $0x30,%edx
f0105579:	eb 22                	jmp    f010559d <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f010557b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010557e:	89 f3                	mov    %esi,%ebx
f0105580:	80 fb 19             	cmp    $0x19,%bl
f0105583:	77 08                	ja     f010558d <strtol+0xa5>
			dig = *s - 'a' + 10;
f0105585:	0f be d2             	movsbl %dl,%edx
f0105588:	83 ea 57             	sub    $0x57,%edx
f010558b:	eb 10                	jmp    f010559d <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f010558d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105590:	89 f3                	mov    %esi,%ebx
f0105592:	80 fb 19             	cmp    $0x19,%bl
f0105595:	77 16                	ja     f01055ad <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105597:	0f be d2             	movsbl %dl,%edx
f010559a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010559d:	3b 55 10             	cmp    0x10(%ebp),%edx
f01055a0:	7d 0f                	jge    f01055b1 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01055a2:	83 c1 01             	add    $0x1,%ecx
f01055a5:	0f af 45 10          	imul   0x10(%ebp),%eax
f01055a9:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01055ab:	eb b9                	jmp    f0105566 <strtol+0x7e>
f01055ad:	89 c2                	mov    %eax,%edx
f01055af:	eb 02                	jmp    f01055b3 <strtol+0xcb>
f01055b1:	89 c2                	mov    %eax,%edx

	if (endptr)
f01055b3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01055b7:	74 0d                	je     f01055c6 <strtol+0xde>
		*endptr = (char *) s;
f01055b9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01055bc:	89 0e                	mov    %ecx,(%esi)
f01055be:	eb 06                	jmp    f01055c6 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01055c0:	84 c0                	test   %al,%al
f01055c2:	75 92                	jne    f0105556 <strtol+0x6e>
f01055c4:	eb 98                	jmp    f010555e <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01055c6:	f7 da                	neg    %edx
f01055c8:	85 ff                	test   %edi,%edi
f01055ca:	0f 45 c2             	cmovne %edx,%eax
}
f01055cd:	5b                   	pop    %ebx
f01055ce:	5e                   	pop    %esi
f01055cf:	5f                   	pop    %edi
f01055d0:	5d                   	pop    %ebp
f01055d1:	c3                   	ret    
f01055d2:	66 90                	xchg   %ax,%ax

f01055d4 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01055d4:	fa                   	cli    

	xorw    %ax, %ax
f01055d5:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01055d7:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055d9:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055db:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01055dd:	0f 01 16             	lgdtl  (%esi)
f01055e0:	74 70                	je     f0105652 <mpsearch1+0x3>
	movl    %cr0, %eax
f01055e2:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01055e5:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01055e9:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01055ec:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01055f2:	08 00                	or     %al,(%eax)

f01055f4 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01055f4:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01055f8:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055fa:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055fc:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01055fe:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105602:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105604:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105606:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f010560b:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f010560e:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105611:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105616:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105619:	8b 25 c4 9e 20 f0    	mov    0xf0209ec4,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f010561f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105624:	b8 c8 01 10 f0       	mov    $0xf01001c8,%eax
	call    *%eax
f0105629:	ff d0                	call   *%eax

f010562b <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010562b:	eb fe                	jmp    f010562b <spin>
f010562d:	8d 76 00             	lea    0x0(%esi),%esi

f0105630 <gdt>:
	...
f0105638:	ff                   	(bad)  
f0105639:	ff 00                	incl   (%eax)
f010563b:	00 00                	add    %al,(%eax)
f010563d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105644:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105648 <gdtdesc>:
f0105648:	17                   	pop    %ss
f0105649:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f010564e <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f010564e:	90                   	nop

f010564f <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f010564f:	55                   	push   %ebp
f0105650:	89 e5                	mov    %esp,%ebp
f0105652:	57                   	push   %edi
f0105653:	56                   	push   %esi
f0105654:	53                   	push   %ebx
f0105655:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105658:	8b 0d c8 9e 20 f0    	mov    0xf0209ec8,%ecx
f010565e:	89 c3                	mov    %eax,%ebx
f0105660:	c1 eb 0c             	shr    $0xc,%ebx
f0105663:	39 cb                	cmp    %ecx,%ebx
f0105665:	72 12                	jb     f0105679 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105667:	50                   	push   %eax
f0105668:	68 e4 60 10 f0       	push   $0xf01060e4
f010566d:	6a 57                	push   $0x57
f010566f:	68 3d 7e 10 f0       	push   $0xf0107e3d
f0105674:	e8 c7 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105679:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f010567f:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105681:	89 c2                	mov    %eax,%edx
f0105683:	c1 ea 0c             	shr    $0xc,%edx
f0105686:	39 d1                	cmp    %edx,%ecx
f0105688:	77 12                	ja     f010569c <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010568a:	50                   	push   %eax
f010568b:	68 e4 60 10 f0       	push   $0xf01060e4
f0105690:	6a 57                	push   $0x57
f0105692:	68 3d 7e 10 f0       	push   $0xf0107e3d
f0105697:	e8 a4 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010569c:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01056a2:	eb 2f                	jmp    f01056d3 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056a4:	83 ec 04             	sub    $0x4,%esp
f01056a7:	6a 04                	push   $0x4
f01056a9:	68 4d 7e 10 f0       	push   $0xf0107e4d
f01056ae:	53                   	push   %ebx
f01056af:	e8 de fd ff ff       	call   f0105492 <memcmp>
f01056b4:	83 c4 10             	add    $0x10,%esp
f01056b7:	85 c0                	test   %eax,%eax
f01056b9:	75 15                	jne    f01056d0 <mpsearch1+0x81>
f01056bb:	89 da                	mov    %ebx,%edx
f01056bd:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01056c0:	0f b6 0a             	movzbl (%edx),%ecx
f01056c3:	01 c8                	add    %ecx,%eax
f01056c5:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01056c8:	39 fa                	cmp    %edi,%edx
f01056ca:	75 f4                	jne    f01056c0 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056cc:	84 c0                	test   %al,%al
f01056ce:	74 0e                	je     f01056de <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01056d0:	83 c3 10             	add    $0x10,%ebx
f01056d3:	39 f3                	cmp    %esi,%ebx
f01056d5:	72 cd                	jb     f01056a4 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01056d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01056dc:	eb 02                	jmp    f01056e0 <mpsearch1+0x91>
f01056de:	89 d8                	mov    %ebx,%eax
}
f01056e0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056e3:	5b                   	pop    %ebx
f01056e4:	5e                   	pop    %esi
f01056e5:	5f                   	pop    %edi
f01056e6:	5d                   	pop    %ebp
f01056e7:	c3                   	ret    

f01056e8 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01056e8:	55                   	push   %ebp
f01056e9:	89 e5                	mov    %esp,%ebp
f01056eb:	57                   	push   %edi
f01056ec:	56                   	push   %esi
f01056ed:	53                   	push   %ebx
f01056ee:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01056f1:	c7 05 e0 a3 20 f0 40 	movl   $0xf020a040,0xf020a3e0
f01056f8:	a0 20 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056fb:	83 3d c8 9e 20 f0 00 	cmpl   $0x0,0xf0209ec8
f0105702:	75 16                	jne    f010571a <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105704:	68 00 04 00 00       	push   $0x400
f0105709:	68 e4 60 10 f0       	push   $0xf01060e4
f010570e:	6a 6f                	push   $0x6f
f0105710:	68 3d 7e 10 f0       	push   $0xf0107e3d
f0105715:	e8 26 a9 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010571a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105721:	85 c0                	test   %eax,%eax
f0105723:	74 16                	je     f010573b <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
f0105725:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105728:	ba 00 04 00 00       	mov    $0x400,%edx
f010572d:	e8 1d ff ff ff       	call   f010564f <mpsearch1>
f0105732:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105735:	85 c0                	test   %eax,%eax
f0105737:	75 3c                	jne    f0105775 <mp_init+0x8d>
f0105739:	eb 20                	jmp    f010575b <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f010573b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105742:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105745:	2d 00 04 00 00       	sub    $0x400,%eax
f010574a:	ba 00 04 00 00       	mov    $0x400,%edx
f010574f:	e8 fb fe ff ff       	call   f010564f <mpsearch1>
f0105754:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105757:	85 c0                	test   %eax,%eax
f0105759:	75 1a                	jne    f0105775 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010575b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105760:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105765:	e8 e5 fe ff ff       	call   f010564f <mpsearch1>
f010576a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f010576d:	85 c0                	test   %eax,%eax
f010576f:	0f 84 5a 02 00 00    	je     f01059cf <mp_init+0x2e7>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105775:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105778:	8b 70 04             	mov    0x4(%eax),%esi
f010577b:	85 f6                	test   %esi,%esi
f010577d:	74 06                	je     f0105785 <mp_init+0x9d>
f010577f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105783:	74 15                	je     f010579a <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105785:	83 ec 0c             	sub    $0xc,%esp
f0105788:	68 b0 7c 10 f0       	push   $0xf0107cb0
f010578d:	e8 8f e0 ff ff       	call   f0103821 <cprintf>
f0105792:	83 c4 10             	add    $0x10,%esp
f0105795:	e9 35 02 00 00       	jmp    f01059cf <mp_init+0x2e7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010579a:	89 f0                	mov    %esi,%eax
f010579c:	c1 e8 0c             	shr    $0xc,%eax
f010579f:	3b 05 c8 9e 20 f0    	cmp    0xf0209ec8,%eax
f01057a5:	72 15                	jb     f01057bc <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01057a7:	56                   	push   %esi
f01057a8:	68 e4 60 10 f0       	push   $0xf01060e4
f01057ad:	68 90 00 00 00       	push   $0x90
f01057b2:	68 3d 7e 10 f0       	push   $0xf0107e3d
f01057b7:	e8 84 a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01057bc:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01057c2:	83 ec 04             	sub    $0x4,%esp
f01057c5:	6a 04                	push   $0x4
f01057c7:	68 52 7e 10 f0       	push   $0xf0107e52
f01057cc:	53                   	push   %ebx
f01057cd:	e8 c0 fc ff ff       	call   f0105492 <memcmp>
f01057d2:	83 c4 10             	add    $0x10,%esp
f01057d5:	85 c0                	test   %eax,%eax
f01057d7:	74 15                	je     f01057ee <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01057d9:	83 ec 0c             	sub    $0xc,%esp
f01057dc:	68 e0 7c 10 f0       	push   $0xf0107ce0
f01057e1:	e8 3b e0 ff ff       	call   f0103821 <cprintf>
f01057e6:	83 c4 10             	add    $0x10,%esp
f01057e9:	e9 e1 01 00 00       	jmp    f01059cf <mp_init+0x2e7>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057ee:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01057f2:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01057f6:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01057f9:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01057fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0105803:	eb 0d                	jmp    f0105812 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105805:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f010580c:	f0 
f010580d:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010580f:	83 c0 01             	add    $0x1,%eax
f0105812:	39 c7                	cmp    %eax,%edi
f0105814:	75 ef                	jne    f0105805 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105816:	84 d2                	test   %dl,%dl
f0105818:	74 15                	je     f010582f <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f010581a:	83 ec 0c             	sub    $0xc,%esp
f010581d:	68 14 7d 10 f0       	push   $0xf0107d14
f0105822:	e8 fa df ff ff       	call   f0103821 <cprintf>
f0105827:	83 c4 10             	add    $0x10,%esp
f010582a:	e9 a0 01 00 00       	jmp    f01059cf <mp_init+0x2e7>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f010582f:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105833:	3c 04                	cmp    $0x4,%al
f0105835:	74 1d                	je     f0105854 <mp_init+0x16c>
f0105837:	3c 01                	cmp    $0x1,%al
f0105839:	74 19                	je     f0105854 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010583b:	83 ec 08             	sub    $0x8,%esp
f010583e:	0f b6 c0             	movzbl %al,%eax
f0105841:	50                   	push   %eax
f0105842:	68 38 7d 10 f0       	push   $0xf0107d38
f0105847:	e8 d5 df ff ff       	call   f0103821 <cprintf>
f010584c:	83 c4 10             	add    $0x10,%esp
f010584f:	e9 7b 01 00 00       	jmp    f01059cf <mp_init+0x2e7>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105854:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105858:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f010585c:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105861:	b8 00 00 00 00       	mov    $0x0,%eax
f0105866:	01 ce                	add    %ecx,%esi
f0105868:	eb 0d                	jmp    f0105877 <mp_init+0x18f>
		sum += ((uint8_t *)addr)[i];
f010586a:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105871:	f0 
f0105872:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105874:	83 c0 01             	add    $0x1,%eax
f0105877:	39 c7                	cmp    %eax,%edi
f0105879:	75 ef                	jne    f010586a <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010587b:	89 d0                	mov    %edx,%eax
f010587d:	02 43 2a             	add    0x2a(%ebx),%al
f0105880:	74 15                	je     f0105897 <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105882:	83 ec 0c             	sub    $0xc,%esp
f0105885:	68 58 7d 10 f0       	push   $0xf0107d58
f010588a:	e8 92 df ff ff       	call   f0103821 <cprintf>
f010588f:	83 c4 10             	add    $0x10,%esp
f0105892:	e9 38 01 00 00       	jmp    f01059cf <mp_init+0x2e7>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105897:	85 db                	test   %ebx,%ebx
f0105899:	0f 84 30 01 00 00    	je     f01059cf <mp_init+0x2e7>
		return;
	ismp = 1;
f010589f:	c7 05 00 a0 20 f0 01 	movl   $0x1,0xf020a000
f01058a6:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01058a9:	8b 43 24             	mov    0x24(%ebx),%eax
f01058ac:	a3 00 b0 24 f0       	mov    %eax,0xf024b000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01058b1:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01058b4:	be 00 00 00 00       	mov    $0x0,%esi
f01058b9:	e9 85 00 00 00       	jmp    f0105943 <mp_init+0x25b>
		switch (*p) {
f01058be:	0f b6 07             	movzbl (%edi),%eax
f01058c1:	84 c0                	test   %al,%al
f01058c3:	74 06                	je     f01058cb <mp_init+0x1e3>
f01058c5:	3c 04                	cmp    $0x4,%al
f01058c7:	77 55                	ja     f010591e <mp_init+0x236>
f01058c9:	eb 4e                	jmp    f0105919 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01058cb:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01058cf:	74 11                	je     f01058e2 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01058d1:	6b 05 e4 a3 20 f0 74 	imul   $0x74,0xf020a3e4,%eax
f01058d8:	05 40 a0 20 f0       	add    $0xf020a040,%eax
f01058dd:	a3 e0 a3 20 f0       	mov    %eax,0xf020a3e0
			if (ncpu < NCPU) {
f01058e2:	a1 e4 a3 20 f0       	mov    0xf020a3e4,%eax
f01058e7:	83 f8 07             	cmp    $0x7,%eax
f01058ea:	7f 13                	jg     f01058ff <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01058ec:	6b d0 74             	imul   $0x74,%eax,%edx
f01058ef:	88 82 40 a0 20 f0    	mov    %al,-0xfdf5fc0(%edx)
				ncpu++;
f01058f5:	83 c0 01             	add    $0x1,%eax
f01058f8:	a3 e4 a3 20 f0       	mov    %eax,0xf020a3e4
f01058fd:	eb 15                	jmp    f0105914 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01058ff:	83 ec 08             	sub    $0x8,%esp
f0105902:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105906:	50                   	push   %eax
f0105907:	68 88 7d 10 f0       	push   $0xf0107d88
f010590c:	e8 10 df ff ff       	call   f0103821 <cprintf>
f0105911:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105914:	83 c7 14             	add    $0x14,%edi
			continue;
f0105917:	eb 27                	jmp    f0105940 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105919:	83 c7 08             	add    $0x8,%edi
			continue;
f010591c:	eb 22                	jmp    f0105940 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010591e:	83 ec 08             	sub    $0x8,%esp
f0105921:	0f b6 c0             	movzbl %al,%eax
f0105924:	50                   	push   %eax
f0105925:	68 b0 7d 10 f0       	push   $0xf0107db0
f010592a:	e8 f2 de ff ff       	call   f0103821 <cprintf>
			ismp = 0;
f010592f:	c7 05 00 a0 20 f0 00 	movl   $0x0,0xf020a000
f0105936:	00 00 00 
			i = conf->entry;
f0105939:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f010593d:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105940:	83 c6 01             	add    $0x1,%esi
f0105943:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105947:	39 c6                	cmp    %eax,%esi
f0105949:	0f 82 6f ff ff ff    	jb     f01058be <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010594f:	a1 e0 a3 20 f0       	mov    0xf020a3e0,%eax
f0105954:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010595b:	83 3d 00 a0 20 f0 00 	cmpl   $0x0,0xf020a000
f0105962:	75 26                	jne    f010598a <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105964:	c7 05 e4 a3 20 f0 01 	movl   $0x1,0xf020a3e4
f010596b:	00 00 00 
		lapicaddr = 0;
f010596e:	c7 05 00 b0 24 f0 00 	movl   $0x0,0xf024b000
f0105975:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105978:	83 ec 0c             	sub    $0xc,%esp
f010597b:	68 d0 7d 10 f0       	push   $0xf0107dd0
f0105980:	e8 9c de ff ff       	call   f0103821 <cprintf>
		return;
f0105985:	83 c4 10             	add    $0x10,%esp
f0105988:	eb 45                	jmp    f01059cf <mp_init+0x2e7>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010598a:	83 ec 04             	sub    $0x4,%esp
f010598d:	ff 35 e4 a3 20 f0    	pushl  0xf020a3e4
f0105993:	0f b6 00             	movzbl (%eax),%eax
f0105996:	50                   	push   %eax
f0105997:	68 57 7e 10 f0       	push   $0xf0107e57
f010599c:	e8 80 de ff ff       	call   f0103821 <cprintf>

	if (mp->imcrp) {
f01059a1:	83 c4 10             	add    $0x10,%esp
f01059a4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01059a7:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01059ab:	74 22                	je     f01059cf <mp_init+0x2e7>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01059ad:	83 ec 0c             	sub    $0xc,%esp
f01059b0:	68 fc 7d 10 f0       	push   $0xf0107dfc
f01059b5:	e8 67 de ff ff       	call   f0103821 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059ba:	ba 22 00 00 00       	mov    $0x22,%edx
f01059bf:	b8 70 00 00 00       	mov    $0x70,%eax
f01059c4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01059c5:	b2 23                	mov    $0x23,%dl
f01059c7:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01059c8:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059cb:	ee                   	out    %al,(%dx)
f01059cc:	83 c4 10             	add    $0x10,%esp
	}
}
f01059cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01059d2:	5b                   	pop    %ebx
f01059d3:	5e                   	pop    %esi
f01059d4:	5f                   	pop    %edi
f01059d5:	5d                   	pop    %ebp
f01059d6:	c3                   	ret    

f01059d7 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01059d7:	55                   	push   %ebp
f01059d8:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01059da:	8b 0d 04 b0 24 f0    	mov    0xf024b004,%ecx
f01059e0:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01059e3:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01059e5:	a1 04 b0 24 f0       	mov    0xf024b004,%eax
f01059ea:	8b 40 20             	mov    0x20(%eax),%eax
}
f01059ed:	5d                   	pop    %ebp
f01059ee:	c3                   	ret    

f01059ef <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01059ef:	55                   	push   %ebp
f01059f0:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01059f2:	a1 04 b0 24 f0       	mov    0xf024b004,%eax
f01059f7:	85 c0                	test   %eax,%eax
f01059f9:	74 08                	je     f0105a03 <cpunum+0x14>
		return lapic[ID] >> 24;
f01059fb:	8b 40 20             	mov    0x20(%eax),%eax
f01059fe:	c1 e8 18             	shr    $0x18,%eax
f0105a01:	eb 05                	jmp    f0105a08 <cpunum+0x19>
	return 0;
f0105a03:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105a08:	5d                   	pop    %ebp
f0105a09:	c3                   	ret    

f0105a0a <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105a0a:	a1 00 b0 24 f0       	mov    0xf024b000,%eax
f0105a0f:	85 c0                	test   %eax,%eax
f0105a11:	0f 84 21 01 00 00    	je     f0105b38 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105a17:	55                   	push   %ebp
f0105a18:	89 e5                	mov    %esp,%ebp
f0105a1a:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105a1d:	68 00 10 00 00       	push   $0x1000
f0105a22:	50                   	push   %eax
f0105a23:	e8 85 b9 ff ff       	call   f01013ad <mmio_map_region>
f0105a28:	a3 04 b0 24 f0       	mov    %eax,0xf024b004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105a2d:	ba 27 01 00 00       	mov    $0x127,%edx
f0105a32:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105a37:	e8 9b ff ff ff       	call   f01059d7 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105a3c:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105a41:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105a46:	e8 8c ff ff ff       	call   f01059d7 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105a4b:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105a50:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105a55:	e8 7d ff ff ff       	call   f01059d7 <lapicw>
	lapicw(TICR, 10000000); 
f0105a5a:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105a5f:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105a64:	e8 6e ff ff ff       	call   f01059d7 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105a69:	e8 81 ff ff ff       	call   f01059ef <cpunum>
f0105a6e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a71:	05 40 a0 20 f0       	add    $0xf020a040,%eax
f0105a76:	83 c4 10             	add    $0x10,%esp
f0105a79:	39 05 e0 a3 20 f0    	cmp    %eax,0xf020a3e0
f0105a7f:	74 0f                	je     f0105a90 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105a81:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a86:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105a8b:	e8 47 ff ff ff       	call   f01059d7 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105a90:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a95:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105a9a:	e8 38 ff ff ff       	call   f01059d7 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105a9f:	a1 04 b0 24 f0       	mov    0xf024b004,%eax
f0105aa4:	8b 40 30             	mov    0x30(%eax),%eax
f0105aa7:	c1 e8 10             	shr    $0x10,%eax
f0105aaa:	3c 03                	cmp    $0x3,%al
f0105aac:	76 0f                	jbe    f0105abd <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105aae:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105ab3:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105ab8:	e8 1a ff ff ff       	call   f01059d7 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105abd:	ba 33 00 00 00       	mov    $0x33,%edx
f0105ac2:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105ac7:	e8 0b ff ff ff       	call   f01059d7 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105acc:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ad1:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105ad6:	e8 fc fe ff ff       	call   f01059d7 <lapicw>
	lapicw(ESR, 0);
f0105adb:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ae0:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105ae5:	e8 ed fe ff ff       	call   f01059d7 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105aea:	ba 00 00 00 00       	mov    $0x0,%edx
f0105aef:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105af4:	e8 de fe ff ff       	call   f01059d7 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105af9:	ba 00 00 00 00       	mov    $0x0,%edx
f0105afe:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b03:	e8 cf fe ff ff       	call   f01059d7 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105b08:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105b0d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b12:	e8 c0 fe ff ff       	call   f01059d7 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105b17:	8b 15 04 b0 24 f0    	mov    0xf024b004,%edx
f0105b1d:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105b23:	f6 c4 10             	test   $0x10,%ah
f0105b26:	75 f5                	jne    f0105b1d <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105b28:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b2d:	b8 20 00 00 00       	mov    $0x20,%eax
f0105b32:	e8 a0 fe ff ff       	call   f01059d7 <lapicw>
}
f0105b37:	c9                   	leave  
f0105b38:	f3 c3                	repz ret 

f0105b3a <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105b3a:	83 3d 04 b0 24 f0 00 	cmpl   $0x0,0xf024b004
f0105b41:	74 13                	je     f0105b56 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105b43:	55                   	push   %ebp
f0105b44:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105b46:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b4b:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b50:	e8 82 fe ff ff       	call   f01059d7 <lapicw>
}
f0105b55:	5d                   	pop    %ebp
f0105b56:	f3 c3                	repz ret 

f0105b58 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105b58:	55                   	push   %ebp
f0105b59:	89 e5                	mov    %esp,%ebp
f0105b5b:	56                   	push   %esi
f0105b5c:	53                   	push   %ebx
f0105b5d:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b60:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105b63:	ba 70 00 00 00       	mov    $0x70,%edx
f0105b68:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105b6d:	ee                   	out    %al,(%dx)
f0105b6e:	b2 71                	mov    $0x71,%dl
f0105b70:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105b75:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105b76:	83 3d c8 9e 20 f0 00 	cmpl   $0x0,0xf0209ec8
f0105b7d:	75 19                	jne    f0105b98 <lapic_startap+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105b7f:	68 67 04 00 00       	push   $0x467
f0105b84:	68 e4 60 10 f0       	push   $0xf01060e4
f0105b89:	68 98 00 00 00       	push   $0x98
f0105b8e:	68 74 7e 10 f0       	push   $0xf0107e74
f0105b93:	e8 a8 a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105b98:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105b9f:	00 00 
	wrv[1] = addr >> 4;
f0105ba1:	89 d8                	mov    %ebx,%eax
f0105ba3:	c1 e8 04             	shr    $0x4,%eax
f0105ba6:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105bac:	c1 e6 18             	shl    $0x18,%esi
f0105baf:	89 f2                	mov    %esi,%edx
f0105bb1:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bb6:	e8 1c fe ff ff       	call   f01059d7 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105bbb:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105bc0:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bc5:	e8 0d fe ff ff       	call   f01059d7 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105bca:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105bcf:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bd4:	e8 fe fd ff ff       	call   f01059d7 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bd9:	c1 eb 0c             	shr    $0xc,%ebx
f0105bdc:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105bdf:	89 f2                	mov    %esi,%edx
f0105be1:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105be6:	e8 ec fd ff ff       	call   f01059d7 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105beb:	89 da                	mov    %ebx,%edx
f0105bed:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bf2:	e8 e0 fd ff ff       	call   f01059d7 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105bf7:	89 f2                	mov    %esi,%edx
f0105bf9:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bfe:	e8 d4 fd ff ff       	call   f01059d7 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c03:	89 da                	mov    %ebx,%edx
f0105c05:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c0a:	e8 c8 fd ff ff       	call   f01059d7 <lapicw>
		microdelay(200);
	}
}
f0105c0f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105c12:	5b                   	pop    %ebx
f0105c13:	5e                   	pop    %esi
f0105c14:	5d                   	pop    %ebp
f0105c15:	c3                   	ret    

f0105c16 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105c16:	55                   	push   %ebp
f0105c17:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105c19:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c1c:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105c22:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c27:	e8 ab fd ff ff       	call   f01059d7 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105c2c:	8b 15 04 b0 24 f0    	mov    0xf024b004,%edx
f0105c32:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c38:	f6 c4 10             	test   $0x10,%ah
f0105c3b:	75 f5                	jne    f0105c32 <lapic_ipi+0x1c>
		;
}
f0105c3d:	5d                   	pop    %ebp
f0105c3e:	c3                   	ret    

f0105c3f <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105c3f:	55                   	push   %ebp
f0105c40:	89 e5                	mov    %esp,%ebp
f0105c42:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105c45:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105c4b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c4e:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105c51:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105c58:	5d                   	pop    %ebp
f0105c59:	c3                   	ret    

f0105c5a <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105c5a:	55                   	push   %ebp
f0105c5b:	89 e5                	mov    %esp,%ebp
f0105c5d:	56                   	push   %esi
f0105c5e:	53                   	push   %ebx
f0105c5f:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105c62:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105c65:	74 14                	je     f0105c7b <spin_lock+0x21>
f0105c67:	8b 73 08             	mov    0x8(%ebx),%esi
f0105c6a:	e8 80 fd ff ff       	call   f01059ef <cpunum>
f0105c6f:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c72:	05 40 a0 20 f0       	add    $0xf020a040,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105c77:	39 c6                	cmp    %eax,%esi
f0105c79:	74 07                	je     f0105c82 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105c7b:	ba 01 00 00 00       	mov    $0x1,%edx
f0105c80:	eb 20                	jmp    f0105ca2 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105c82:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105c85:	e8 65 fd ff ff       	call   f01059ef <cpunum>
f0105c8a:	83 ec 0c             	sub    $0xc,%esp
f0105c8d:	53                   	push   %ebx
f0105c8e:	50                   	push   %eax
f0105c8f:	68 84 7e 10 f0       	push   $0xf0107e84
f0105c94:	6a 41                	push   $0x41
f0105c96:	68 e8 7e 10 f0       	push   $0xf0107ee8
f0105c9b:	e8 a0 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105ca0:	f3 90                	pause  
f0105ca2:	89 d0                	mov    %edx,%eax
f0105ca4:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105ca7:	85 c0                	test   %eax,%eax
f0105ca9:	75 f5                	jne    f0105ca0 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105cab:	e8 3f fd ff ff       	call   f01059ef <cpunum>
f0105cb0:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cb3:	05 40 a0 20 f0       	add    $0xf020a040,%eax
f0105cb8:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105cbb:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0105cbe:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105cc0:	b8 00 00 00 00       	mov    $0x0,%eax
f0105cc5:	eb 0b                	jmp    f0105cd2 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105cc7:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105cca:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105ccd:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105ccf:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105cd2:	83 f8 09             	cmp    $0x9,%eax
f0105cd5:	7f 14                	jg     f0105ceb <spin_lock+0x91>
f0105cd7:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105cdd:	77 e8                	ja     f0105cc7 <spin_lock+0x6d>
f0105cdf:	eb 0a                	jmp    f0105ceb <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105ce1:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105ce8:	83 c0 01             	add    $0x1,%eax
f0105ceb:	83 f8 09             	cmp    $0x9,%eax
f0105cee:	7e f1                	jle    f0105ce1 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105cf0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105cf3:	5b                   	pop    %ebx
f0105cf4:	5e                   	pop    %esi
f0105cf5:	5d                   	pop    %ebp
f0105cf6:	c3                   	ret    

f0105cf7 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105cf7:	55                   	push   %ebp
f0105cf8:	89 e5                	mov    %esp,%ebp
f0105cfa:	57                   	push   %edi
f0105cfb:	56                   	push   %esi
f0105cfc:	53                   	push   %ebx
f0105cfd:	83 ec 4c             	sub    $0x4c,%esp
f0105d00:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105d03:	83 3e 00             	cmpl   $0x0,(%esi)
f0105d06:	74 18                	je     f0105d20 <spin_unlock+0x29>
f0105d08:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105d0b:	e8 df fc ff ff       	call   f01059ef <cpunum>
f0105d10:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d13:	05 40 a0 20 f0       	add    $0xf020a040,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105d18:	39 c3                	cmp    %eax,%ebx
f0105d1a:	0f 84 a5 00 00 00    	je     f0105dc5 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105d20:	83 ec 04             	sub    $0x4,%esp
f0105d23:	6a 28                	push   $0x28
f0105d25:	8d 46 0c             	lea    0xc(%esi),%eax
f0105d28:	50                   	push   %eax
f0105d29:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105d2c:	53                   	push   %ebx
f0105d2d:	e8 e5 f6 ff ff       	call   f0105417 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105d32:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105d35:	0f b6 38             	movzbl (%eax),%edi
f0105d38:	8b 76 04             	mov    0x4(%esi),%esi
f0105d3b:	e8 af fc ff ff       	call   f01059ef <cpunum>
f0105d40:	57                   	push   %edi
f0105d41:	56                   	push   %esi
f0105d42:	50                   	push   %eax
f0105d43:	68 b0 7e 10 f0       	push   $0xf0107eb0
f0105d48:	e8 d4 da ff ff       	call   f0103821 <cprintf>
f0105d4d:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105d50:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105d53:	eb 54                	jmp    f0105da9 <spin_unlock+0xb2>
f0105d55:	83 ec 08             	sub    $0x8,%esp
f0105d58:	57                   	push   %edi
f0105d59:	50                   	push   %eax
f0105d5a:	e8 d5 eb ff ff       	call   f0104934 <debuginfo_eip>
f0105d5f:	83 c4 10             	add    $0x10,%esp
f0105d62:	85 c0                	test   %eax,%eax
f0105d64:	78 27                	js     f0105d8d <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105d66:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105d68:	83 ec 04             	sub    $0x4,%esp
f0105d6b:	89 c2                	mov    %eax,%edx
f0105d6d:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105d70:	52                   	push   %edx
f0105d71:	ff 75 b0             	pushl  -0x50(%ebp)
f0105d74:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105d77:	ff 75 ac             	pushl  -0x54(%ebp)
f0105d7a:	ff 75 a8             	pushl  -0x58(%ebp)
f0105d7d:	50                   	push   %eax
f0105d7e:	68 f8 7e 10 f0       	push   $0xf0107ef8
f0105d83:	e8 99 da ff ff       	call   f0103821 <cprintf>
f0105d88:	83 c4 20             	add    $0x20,%esp
f0105d8b:	eb 12                	jmp    f0105d9f <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105d8d:	83 ec 08             	sub    $0x8,%esp
f0105d90:	ff 36                	pushl  (%esi)
f0105d92:	68 0f 7f 10 f0       	push   $0xf0107f0f
f0105d97:	e8 85 da ff ff       	call   f0103821 <cprintf>
f0105d9c:	83 c4 10             	add    $0x10,%esp
f0105d9f:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105da2:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105da5:	39 c3                	cmp    %eax,%ebx
f0105da7:	74 08                	je     f0105db1 <spin_unlock+0xba>
f0105da9:	89 de                	mov    %ebx,%esi
f0105dab:	8b 03                	mov    (%ebx),%eax
f0105dad:	85 c0                	test   %eax,%eax
f0105daf:	75 a4                	jne    f0105d55 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105db1:	83 ec 04             	sub    $0x4,%esp
f0105db4:	68 17 7f 10 f0       	push   $0xf0107f17
f0105db9:	6a 67                	push   $0x67
f0105dbb:	68 e8 7e 10 f0       	push   $0xf0107ee8
f0105dc0:	e8 7b a2 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105dc5:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105dcc:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0105dd3:	b8 00 00 00 00       	mov    $0x0,%eax
f0105dd8:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105ddb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105dde:	5b                   	pop    %ebx
f0105ddf:	5e                   	pop    %esi
f0105de0:	5f                   	pop    %edi
f0105de1:	5d                   	pop    %ebp
f0105de2:	c3                   	ret    
f0105de3:	66 90                	xchg   %ax,%ax
f0105de5:	66 90                	xchg   %ax,%ax
f0105de7:	66 90                	xchg   %ax,%ax
f0105de9:	66 90                	xchg   %ax,%ax
f0105deb:	66 90                	xchg   %ax,%ax
f0105ded:	66 90                	xchg   %ax,%ax
f0105def:	90                   	nop

f0105df0 <__udivdi3>:
f0105df0:	55                   	push   %ebp
f0105df1:	57                   	push   %edi
f0105df2:	56                   	push   %esi
f0105df3:	83 ec 10             	sub    $0x10,%esp
f0105df6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0105dfa:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0105dfe:	8b 74 24 24          	mov    0x24(%esp),%esi
f0105e02:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0105e06:	85 d2                	test   %edx,%edx
f0105e08:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105e0c:	89 34 24             	mov    %esi,(%esp)
f0105e0f:	89 c8                	mov    %ecx,%eax
f0105e11:	75 35                	jne    f0105e48 <__udivdi3+0x58>
f0105e13:	39 f1                	cmp    %esi,%ecx
f0105e15:	0f 87 bd 00 00 00    	ja     f0105ed8 <__udivdi3+0xe8>
f0105e1b:	85 c9                	test   %ecx,%ecx
f0105e1d:	89 cd                	mov    %ecx,%ebp
f0105e1f:	75 0b                	jne    f0105e2c <__udivdi3+0x3c>
f0105e21:	b8 01 00 00 00       	mov    $0x1,%eax
f0105e26:	31 d2                	xor    %edx,%edx
f0105e28:	f7 f1                	div    %ecx
f0105e2a:	89 c5                	mov    %eax,%ebp
f0105e2c:	89 f0                	mov    %esi,%eax
f0105e2e:	31 d2                	xor    %edx,%edx
f0105e30:	f7 f5                	div    %ebp
f0105e32:	89 c6                	mov    %eax,%esi
f0105e34:	89 f8                	mov    %edi,%eax
f0105e36:	f7 f5                	div    %ebp
f0105e38:	89 f2                	mov    %esi,%edx
f0105e3a:	83 c4 10             	add    $0x10,%esp
f0105e3d:	5e                   	pop    %esi
f0105e3e:	5f                   	pop    %edi
f0105e3f:	5d                   	pop    %ebp
f0105e40:	c3                   	ret    
f0105e41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105e48:	3b 14 24             	cmp    (%esp),%edx
f0105e4b:	77 7b                	ja     f0105ec8 <__udivdi3+0xd8>
f0105e4d:	0f bd f2             	bsr    %edx,%esi
f0105e50:	83 f6 1f             	xor    $0x1f,%esi
f0105e53:	0f 84 97 00 00 00    	je     f0105ef0 <__udivdi3+0x100>
f0105e59:	bd 20 00 00 00       	mov    $0x20,%ebp
f0105e5e:	89 d7                	mov    %edx,%edi
f0105e60:	89 f1                	mov    %esi,%ecx
f0105e62:	29 f5                	sub    %esi,%ebp
f0105e64:	d3 e7                	shl    %cl,%edi
f0105e66:	89 c2                	mov    %eax,%edx
f0105e68:	89 e9                	mov    %ebp,%ecx
f0105e6a:	d3 ea                	shr    %cl,%edx
f0105e6c:	89 f1                	mov    %esi,%ecx
f0105e6e:	09 fa                	or     %edi,%edx
f0105e70:	8b 3c 24             	mov    (%esp),%edi
f0105e73:	d3 e0                	shl    %cl,%eax
f0105e75:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105e79:	89 e9                	mov    %ebp,%ecx
f0105e7b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105e7f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105e83:	89 fa                	mov    %edi,%edx
f0105e85:	d3 ea                	shr    %cl,%edx
f0105e87:	89 f1                	mov    %esi,%ecx
f0105e89:	d3 e7                	shl    %cl,%edi
f0105e8b:	89 e9                	mov    %ebp,%ecx
f0105e8d:	d3 e8                	shr    %cl,%eax
f0105e8f:	09 c7                	or     %eax,%edi
f0105e91:	89 f8                	mov    %edi,%eax
f0105e93:	f7 74 24 08          	divl   0x8(%esp)
f0105e97:	89 d5                	mov    %edx,%ebp
f0105e99:	89 c7                	mov    %eax,%edi
f0105e9b:	f7 64 24 0c          	mull   0xc(%esp)
f0105e9f:	39 d5                	cmp    %edx,%ebp
f0105ea1:	89 14 24             	mov    %edx,(%esp)
f0105ea4:	72 11                	jb     f0105eb7 <__udivdi3+0xc7>
f0105ea6:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105eaa:	89 f1                	mov    %esi,%ecx
f0105eac:	d3 e2                	shl    %cl,%edx
f0105eae:	39 c2                	cmp    %eax,%edx
f0105eb0:	73 5e                	jae    f0105f10 <__udivdi3+0x120>
f0105eb2:	3b 2c 24             	cmp    (%esp),%ebp
f0105eb5:	75 59                	jne    f0105f10 <__udivdi3+0x120>
f0105eb7:	8d 47 ff             	lea    -0x1(%edi),%eax
f0105eba:	31 f6                	xor    %esi,%esi
f0105ebc:	89 f2                	mov    %esi,%edx
f0105ebe:	83 c4 10             	add    $0x10,%esp
f0105ec1:	5e                   	pop    %esi
f0105ec2:	5f                   	pop    %edi
f0105ec3:	5d                   	pop    %ebp
f0105ec4:	c3                   	ret    
f0105ec5:	8d 76 00             	lea    0x0(%esi),%esi
f0105ec8:	31 f6                	xor    %esi,%esi
f0105eca:	31 c0                	xor    %eax,%eax
f0105ecc:	89 f2                	mov    %esi,%edx
f0105ece:	83 c4 10             	add    $0x10,%esp
f0105ed1:	5e                   	pop    %esi
f0105ed2:	5f                   	pop    %edi
f0105ed3:	5d                   	pop    %ebp
f0105ed4:	c3                   	ret    
f0105ed5:	8d 76 00             	lea    0x0(%esi),%esi
f0105ed8:	89 f2                	mov    %esi,%edx
f0105eda:	31 f6                	xor    %esi,%esi
f0105edc:	89 f8                	mov    %edi,%eax
f0105ede:	f7 f1                	div    %ecx
f0105ee0:	89 f2                	mov    %esi,%edx
f0105ee2:	83 c4 10             	add    $0x10,%esp
f0105ee5:	5e                   	pop    %esi
f0105ee6:	5f                   	pop    %edi
f0105ee7:	5d                   	pop    %ebp
f0105ee8:	c3                   	ret    
f0105ee9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105ef0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0105ef4:	76 0b                	jbe    f0105f01 <__udivdi3+0x111>
f0105ef6:	31 c0                	xor    %eax,%eax
f0105ef8:	3b 14 24             	cmp    (%esp),%edx
f0105efb:	0f 83 37 ff ff ff    	jae    f0105e38 <__udivdi3+0x48>
f0105f01:	b8 01 00 00 00       	mov    $0x1,%eax
f0105f06:	e9 2d ff ff ff       	jmp    f0105e38 <__udivdi3+0x48>
f0105f0b:	90                   	nop
f0105f0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105f10:	89 f8                	mov    %edi,%eax
f0105f12:	31 f6                	xor    %esi,%esi
f0105f14:	e9 1f ff ff ff       	jmp    f0105e38 <__udivdi3+0x48>
f0105f19:	66 90                	xchg   %ax,%ax
f0105f1b:	66 90                	xchg   %ax,%ax
f0105f1d:	66 90                	xchg   %ax,%ax
f0105f1f:	90                   	nop

f0105f20 <__umoddi3>:
f0105f20:	55                   	push   %ebp
f0105f21:	57                   	push   %edi
f0105f22:	56                   	push   %esi
f0105f23:	83 ec 20             	sub    $0x20,%esp
f0105f26:	8b 44 24 34          	mov    0x34(%esp),%eax
f0105f2a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105f2e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105f32:	89 c6                	mov    %eax,%esi
f0105f34:	89 44 24 10          	mov    %eax,0x10(%esp)
f0105f38:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105f3c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0105f40:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105f44:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105f48:	89 74 24 18          	mov    %esi,0x18(%esp)
f0105f4c:	85 c0                	test   %eax,%eax
f0105f4e:	89 c2                	mov    %eax,%edx
f0105f50:	75 1e                	jne    f0105f70 <__umoddi3+0x50>
f0105f52:	39 f7                	cmp    %esi,%edi
f0105f54:	76 52                	jbe    f0105fa8 <__umoddi3+0x88>
f0105f56:	89 c8                	mov    %ecx,%eax
f0105f58:	89 f2                	mov    %esi,%edx
f0105f5a:	f7 f7                	div    %edi
f0105f5c:	89 d0                	mov    %edx,%eax
f0105f5e:	31 d2                	xor    %edx,%edx
f0105f60:	83 c4 20             	add    $0x20,%esp
f0105f63:	5e                   	pop    %esi
f0105f64:	5f                   	pop    %edi
f0105f65:	5d                   	pop    %ebp
f0105f66:	c3                   	ret    
f0105f67:	89 f6                	mov    %esi,%esi
f0105f69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105f70:	39 f0                	cmp    %esi,%eax
f0105f72:	77 5c                	ja     f0105fd0 <__umoddi3+0xb0>
f0105f74:	0f bd e8             	bsr    %eax,%ebp
f0105f77:	83 f5 1f             	xor    $0x1f,%ebp
f0105f7a:	75 64                	jne    f0105fe0 <__umoddi3+0xc0>
f0105f7c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0105f80:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0105f84:	0f 86 f6 00 00 00    	jbe    f0106080 <__umoddi3+0x160>
f0105f8a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0105f8e:	0f 82 ec 00 00 00    	jb     f0106080 <__umoddi3+0x160>
f0105f94:	8b 44 24 14          	mov    0x14(%esp),%eax
f0105f98:	8b 54 24 18          	mov    0x18(%esp),%edx
f0105f9c:	83 c4 20             	add    $0x20,%esp
f0105f9f:	5e                   	pop    %esi
f0105fa0:	5f                   	pop    %edi
f0105fa1:	5d                   	pop    %ebp
f0105fa2:	c3                   	ret    
f0105fa3:	90                   	nop
f0105fa4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105fa8:	85 ff                	test   %edi,%edi
f0105faa:	89 fd                	mov    %edi,%ebp
f0105fac:	75 0b                	jne    f0105fb9 <__umoddi3+0x99>
f0105fae:	b8 01 00 00 00       	mov    $0x1,%eax
f0105fb3:	31 d2                	xor    %edx,%edx
f0105fb5:	f7 f7                	div    %edi
f0105fb7:	89 c5                	mov    %eax,%ebp
f0105fb9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0105fbd:	31 d2                	xor    %edx,%edx
f0105fbf:	f7 f5                	div    %ebp
f0105fc1:	89 c8                	mov    %ecx,%eax
f0105fc3:	f7 f5                	div    %ebp
f0105fc5:	eb 95                	jmp    f0105f5c <__umoddi3+0x3c>
f0105fc7:	89 f6                	mov    %esi,%esi
f0105fc9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105fd0:	89 c8                	mov    %ecx,%eax
f0105fd2:	89 f2                	mov    %esi,%edx
f0105fd4:	83 c4 20             	add    $0x20,%esp
f0105fd7:	5e                   	pop    %esi
f0105fd8:	5f                   	pop    %edi
f0105fd9:	5d                   	pop    %ebp
f0105fda:	c3                   	ret    
f0105fdb:	90                   	nop
f0105fdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105fe0:	b8 20 00 00 00       	mov    $0x20,%eax
f0105fe5:	89 e9                	mov    %ebp,%ecx
f0105fe7:	29 e8                	sub    %ebp,%eax
f0105fe9:	d3 e2                	shl    %cl,%edx
f0105feb:	89 c7                	mov    %eax,%edi
f0105fed:	89 44 24 18          	mov    %eax,0x18(%esp)
f0105ff1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105ff5:	89 f9                	mov    %edi,%ecx
f0105ff7:	d3 e8                	shr    %cl,%eax
f0105ff9:	89 c1                	mov    %eax,%ecx
f0105ffb:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105fff:	09 d1                	or     %edx,%ecx
f0106001:	89 fa                	mov    %edi,%edx
f0106003:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106007:	89 e9                	mov    %ebp,%ecx
f0106009:	d3 e0                	shl    %cl,%eax
f010600b:	89 f9                	mov    %edi,%ecx
f010600d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106011:	89 f0                	mov    %esi,%eax
f0106013:	d3 e8                	shr    %cl,%eax
f0106015:	89 e9                	mov    %ebp,%ecx
f0106017:	89 c7                	mov    %eax,%edi
f0106019:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f010601d:	d3 e6                	shl    %cl,%esi
f010601f:	89 d1                	mov    %edx,%ecx
f0106021:	89 fa                	mov    %edi,%edx
f0106023:	d3 e8                	shr    %cl,%eax
f0106025:	89 e9                	mov    %ebp,%ecx
f0106027:	09 f0                	or     %esi,%eax
f0106029:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010602d:	f7 74 24 10          	divl   0x10(%esp)
f0106031:	d3 e6                	shl    %cl,%esi
f0106033:	89 d1                	mov    %edx,%ecx
f0106035:	f7 64 24 0c          	mull   0xc(%esp)
f0106039:	39 d1                	cmp    %edx,%ecx
f010603b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010603f:	89 d7                	mov    %edx,%edi
f0106041:	89 c6                	mov    %eax,%esi
f0106043:	72 0a                	jb     f010604f <__umoddi3+0x12f>
f0106045:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0106049:	73 10                	jae    f010605b <__umoddi3+0x13b>
f010604b:	39 d1                	cmp    %edx,%ecx
f010604d:	75 0c                	jne    f010605b <__umoddi3+0x13b>
f010604f:	89 d7                	mov    %edx,%edi
f0106051:	89 c6                	mov    %eax,%esi
f0106053:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0106057:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010605b:	89 ca                	mov    %ecx,%edx
f010605d:	89 e9                	mov    %ebp,%ecx
f010605f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0106063:	29 f0                	sub    %esi,%eax
f0106065:	19 fa                	sbb    %edi,%edx
f0106067:	d3 e8                	shr    %cl,%eax
f0106069:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010606e:	89 d7                	mov    %edx,%edi
f0106070:	d3 e7                	shl    %cl,%edi
f0106072:	89 e9                	mov    %ebp,%ecx
f0106074:	09 f8                	or     %edi,%eax
f0106076:	d3 ea                	shr    %cl,%edx
f0106078:	83 c4 20             	add    $0x20,%esp
f010607b:	5e                   	pop    %esi
f010607c:	5f                   	pop    %edi
f010607d:	5d                   	pop    %ebp
f010607e:	c3                   	ret    
f010607f:	90                   	nop
f0106080:	8b 74 24 10          	mov    0x10(%esp),%esi
f0106084:	29 f9                	sub    %edi,%ecx
f0106086:	19 c6                	sbb    %eax,%esi
f0106088:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010608c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0106090:	e9 ff fe ff ff       	jmp    f0105f94 <__umoddi3+0x74>
