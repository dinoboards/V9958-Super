#ifndef __CPMCALLS
#define __CPMCALLS

#include <ez80.h>
#include <stdbool.h>
#include <stdint.h>

/**
 * @file cpm.h
 * @brief CP/M system calls and data structures.
 *
 * The cpm library provides structures, constants, and function declarations for
 * interacting with the CP/M operating system on the eZ80 platform. It includes
 * definitions for the File Control Block (FCB), BDOS calls, IOBYTE handling,
 * and various CP/M error codes and macros.
 *
 * All functions will be marshalled from eZ80's ADL execution environment to
 * the Z80 compatibility environment.  All pointers supplied to functions must reference
 * an address within the Z80 compatibility segement - for the `eZ80 for RC` module
 * this is typically at address range: 0x03XXXX.
 *
 * To ensure any structure if within this segment, you can allocate variables/arrays within
 * the `bss_z80` segment.
 */

/**
 * @brief CP/M's File Control Block structure
 *
 */
typedef struct cpm_fcb {
  // 36 bytes of standard FCB
  uint8_t drive;       /* drive code 0*/
  char    name[8];     /* file name 1*/
  char    ext[3];      /* file type 9*/
  uint8_t extent;      /* file extent 12*/
  char    filler[2];   /* not used 14*/
  char    records;     /* number of records in present extent 15*/
  char    discmap[16]; /* CP/M disc map 16 */
  char    next_record; /* next record to read or write 32*/
  uint8_t ranrec[3];   /* random record number (24 bit no. ) */
} CPM_FCB;

extern CPM_FCB *const CPM_SYS_FCB; // typically 0x03005C;
// extern CPM_FCB CPM_DMABUF;  // typically 0x030080;

// assigned to the start of the 64k CPM page (typically 0x030000)
extern void const *const cpm_mbase;

#define __MBASE (((uint8_t *)&cpm_mbase)[2])

#define AS_CPM_PTR(a) as_near_ptr_safe(a, __MBASE, __FILE__, __LINE__)

typedef uint8_t cpm_f_error_t;

/**
 * @brief Call the BDOS function with specified register values.
 *
 * This function calls the BDOS with register pair BC set to `bc` and DE set to `de`.
 * The value returned in register A is the return value of the function
 *
 * @param bc The value to set in the BC register pair.
 * @param de The value to set in the DE register pair.
 *
 * @return The value returned in register A.
 */
extern uint8_t bdos(uint16_t bc, uint16_t de);

/**
 * @brief Quit the current program and return to the command prompt.
 */
extern void cpm_term(void);

/**
 * @brief Wait for a character from the keyboard, echo it to the screen, and return it.
 *
 * This function waits for a character input from the keyboard, echoes it to the screen,
 * and then returns the character.
 *
 * @return The character read from the keyboard.
 */
extern uint8_t cpm_c_read(void);

/**
 * @brief Send the character to the screen.
 *
 * This function sends the character `c` to the screen. Tabs are expanded to spaces.
 * Output can be paused with ^S and restarted with ^Q (or any key under versions prior to CP/M 3).
 * While the output is paused, the program can be terminated with ^C.
 *
 * @param[in] c The character to send to the screen.
 */
extern void cpm_c_write(uint8_t c);

/**
 * @brief Wait for a character from the auxiliary reader.
 *
 * This function waits for a character input from the auxiliary reader and returns it.
 *
 * @return The character read from the auxiliary reader.
 */
extern uint8_t cpm_a_read(void);

/**
 * @brief Send the character to the Auxiliary (Punch) output.
 *
 * This function sends the character `c` to the Auxiliary (Punch) output.
 *
 * @param[in] c The character to send to the Auxiliary output.
 */
extern void cpm_a_write(uint8_t c);

/**
 * @brief Send the character to the printer.
 *
 * This function sends the character `c` to the printer.
 *
 * @param[in] c The character to send to the printer.
 */
extern void cpm_l_write(uint8_t c);

/**
 * @brief Return a character without echoing if one is waiting; zero if none is available.
 *
 * This function returns a character if one is waiting in the input buffer without echoing it.
 * If no character is available, it returns zero.
 *
 * @return The character if available, otherwise zero.
 */
extern uint8_t cpm_c_rawio(void);

/**
 * @brief Returns the current IOBYTE.
 *
 * This function returns the current IOBYTE, which is bit mapped as follows:
 *
 *     Bits      Bits 6,7    Bits 4,5    Bits 2,3    Bits 0,1
 *     Device    LIST        PUNCH       READER      CONSOLE
 *
 *     Value
 *       00      TTY:        TTY:        TTY:        TTY:
 *       01      CRT:        PTP:        PTR:        CRT:
 *       10      LPT:        UP1:        UR1:        BAT:
 *       11      UL1:        UP2:        UR2:        UC1:
 *
 * BAT = batch mode. Use the current Reader for console input, and the current List (printer) device as the console output.
 * CRT = Standard console (keyboard and terminal screen).
 * LPT = Standard line printer.
 * PTP = Standard Paper Tape Punch.
 * PTR = Standard Paper Tape Reader.
 * TTY = Teletype device, e.g., a serial port.
 * UC1 = User defined (i.e., implementation dependent) console device.
 * UL1 = User defined (i.e., implementation dependent) printer device.
 * UPn = User defined (i.e., implementation dependent) output device.
 * URn = User defined (i.e., implementation dependent) input device.
 *
 * @return The current IOBYTE.
 */
extern uint8_t cpm_get_iobyte(void);

// Bit masks for each device in the iobyte
#define CPM_IOBYTE_CONSOLE_MASK ((uint8_t)0x03) // 00000011
#define CPM_IOBYTE_READER_MASK  ((uint8_t)0x0C) // 00001100
#define CPM_IOBYTE_PUNCH_MASK   ((uint8_t)0x30) // 00110000
#define CPM_IOBYTE_LIST_MASK    ((uint8_t)0xC0) // 11000000

// Bit shift values for each device in the iobyte
#define CPM_IOBYTE_CONSOLE_SHIFT 0
#define CPM_IOBYTE_READER_SHIFT  2
#define CPM_IOBYTE_PUNCH_SHIFT   4
#define CPM_IOBYTE_LIST_SHIFT    6

// Macros to extract each device from the iobyte
#define CPM_IOBYTE_GET_CONSOLE(iobyte) ((iobyte & CPM_IOBYTE_CONSOLE_MASK) >> CPM_IOBYTE_CONSOLE_SHIFT)
#define CPM_IOBYTE_GET_READER(iobyte)  ((iobyte & CPM_IOBYTE_READER_MASK) >> CPM_IOBYTE_READER_SHIFT)
#define CPM_IOBYTE_GET_PUNCH(iobyte)   ((iobyte & CPM_IOBYTE_PUNCH_MASK) >> CPM_IOBYTE_PUNCH_SHIFT)
#define CPM_IOBYTE_GET_LIST(iobyte)    ((iobyte & CPM_IOBYTE_LIST_MASK) >> CPM_IOBYTE_LIST_SHIFT)

// Macros to set each device in the iobyte
#define CPM_IOBYTE_SET_CONSOLE(iobyte, value)                                                                                      \
  (iobyte = (iobyte & ~CPM_IOBYTE_CONSOLE_MASK) | ((value << CPM_IOBYTE_CONSOLE_SHIFT) & CPM_IOBYTE_CONSOLE_MASK))
#define CPM_IOBYTE_SET_READER(iobyte, value)                                                                                       \
  (iobyte = (iobyte & ~CPM_IOBYTE_READER_MASK) | ((value << CPM_IOBYTE_READER_SHIFT) & CPM_IOBYTE_READER_MASK))
#define CPM_IOBYTE_SET_PUNCH(iobyte, value)                                                                                        \
  (iobyte = (iobyte & ~CPM_IOBYTE_PUNCH_MASK) | ((value << CPM_IOBYTE_PUNCH_SHIFT) & CPM_IOBYTE_PUNCH_MASK))
#define CPM_IOBYTE_SET_LIST(iobyte, value)                                                                                         \
  (iobyte = (iobyte & ~CPM_IOBYTE_LIST_MASK) | ((value << CPM_IOBYTE_LIST_SHIFT) & CPM_IOBYTE_LIST_MASK))

extern const char *cpm_get_console_device(void);
extern const char *cpm_get_reader_device(void);
extern const char *cpm_get_punch_device(void);
extern const char *cpm_get_list_device(void);

/**
 * @brief Sets the IOBYTE to the specified value.
 *
 * This function sets the IOBYTE to the given value.
 *
 * @param[in] iobyte The value to set the IOBYTE to.
 */
extern void cpm_set_iobyte(uint8_t iobyte);

/**
 * @brief Writes a $ terminated string to the console.
 *
 * This function writes the $ terminated string pointed to by `str` to the console.
 *
 * @param[in] str The near pointer to the $ terminated string to be written.
 */
extern void cpm_c_writestr(near_ptr_t str);

/**
 * @brief Reads a string from the console.
 *
 * This function reads characters from the keyboard into a memory buffer until RETURN is pressed. The Delete key is handled
 * correctly. In later versions of CP/M, more features can be used at this point; ZPM3 includes a full line editor with recall of
 * previous lines typed.
 *
 * If `str` is NULL, the DMA address is used (CP/M 3 and later) and the buffer already contains data:
 *
 * buffer: DEFB    size
 *         DEFB    len
 *         DEFB    bytes
 *
 * The value at buffer+0 is the amount of bytes available in the buffer. Once the limit has been reached, no more can be added,
 * although the line editor can still be used. If `str` is NULL the next byte contains the number of bytes already in the buffer;
 * otherwise this is ignored. On return from the function, it contains the number of bytes present in the buffer.
 *
 * The bytes typed then follow. There is no end marker.
 *
 * @param[out] str The near pointer to the buffer where the string and its header will be stored.
 */
extern void cpm_c_readstr(near_ptr_t str);

/**
 * @brief Sets the DMA address for the next file operation.
 *
 * This function sets the DMA address to `addr` for the next file operation.
 *
 * @param[in] addr The near pointer to the DMA address.
 */
extern void cpm_f_dmaoff(near_ptr_t addr);

/**
 * @brief Returns 0 if no characters are waiting, nonzero if a character is waiting.
 *
 * @return The console status
 */
extern uint8_t cpm_c_stat(void);

/**
 * @brief Returns the BDOS version.
 *
 * This function returns the BDOS version.
 *
 * @return The BDOS version.
 */
extern uint16_t cpm_s_bdosver(void);

/**
 * @brief Resets all disk drives and logs out all disks.
 *
 * This function resets all disk drives, logs out all disks, and empties disk buffers. It sets the currently selected drive to A:.
 * Any drives set to Read-Only in software* become Read-Write; replacement BDOS implementations may leave them Read-Only.
 *
 * In CP/M versions 1 and 2, it logs in drive A: and returns 0xFF if there is a file present whose name begins with a `$`, otherwise
 * it returns 0. Replacement BDOS* implementations may modify this behavior.
 *
 * In multitasking versions, it returns 0 if succeeded, or 0xFF if other processes have files open on removable or read-only drives.
 *
 * When the Digital Research CP/M 2 BDOS is started from cold, it is not properly initialized until this function is called; disk
 * operations may fail or crash.  Normally, this is done by the CCP and other programs don't need to worry, but if you are writing
 * an alternative CCP or a program that runs instead of the CCP, it's something to bear in mind.
 *
 * @return 0 if succeeded, or 0xFF if there are issues.
 */
extern uint8_t cpm_drv_allreset(void);

/**
 * @brief Sets the currently selected drive.
 *
 * This function sets the currently selected drive to the specified drive number and logs in the disk. The drive number passed to
 * this routine is 0 for A:, 1 for B:, up to 15 for P:.
 *
 * CP/M 1975 and 1.3 are limited to two drives. CP/M 1.4 is limited to four drives.
 *
 * @param[in] drive The drive number to set (0 for A:, 1 for B:, ..., 15 for P:).
 *
 * @return 0 if successful, or 0xFF if there is an error. Under MP/M II and later versions, H can contain a physical error number.
 */
extern uint8_t cpm_drv_set(uint8_t drive);

/**
 * @brief Returns the currently selected drive.
 *
 * Returns currently selected drive. 0 => A:, 1 => B: etc.
 *
 * @return The currently selected drive.
 */
extern uint8_t cpm_drv_get(void);

/**
 * @brief Opens a file for reading or reading/writing.
 *
 * This function opens a file for reading or reading/writing using the File Control Block (FCB). The FCB is a 36-byte data
 * structure, most of which is maintained by CP/M.
 *
 * The FCB should have its DR, Fn, and Tn fields filled in, and the four fields EX, S1, S2, and RC set to zero. Under CP/M 3 and
 * later, if CR is set to 0xFF, then on return CR will contain the last record byte count.  Note that CR should normally be reset to
 * zero if sequential access is to be used.
 *
 * Under MP/M II, the file is normally opened exclusively - no other process can access it.
 * Two bits in the FCB control the mode the file is opened in:
 * - F5': Set to 1 for "unlocked" mode - other programs can use the file.
 * - F6': Set to 1 to open the file in read-only mode - other programs can use the file read-only.
 *   If both F6' and F5' are set, F6' wins.
 * If the file is opened in "unlocked" mode, the file's identifier (used for record locking) will be returned at FCB+21h.
 *
 * Under MP/M II and later versions, a password can be supplied to this function by pointing the DMA address at the password.
 *
 * On return from this function, A is 0xFF for error, or 0-3 for success. Some versions (including CP/M 3) always return zero;
 * others return 0-3 to indicate that an image of the directory entry is to be found at (80h+20h*A).
 *
 * If result is 0xFF, CP/M 3 returns a hardware error (stored in errno). It also sets some bits in the FCB:
 * - F7': Set if the file is read-only because writing is password protected and no password was supplied.
 * - F8': Set if the file is read-only because it is a User 0 system file opened from another user area.
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0-3 for success, or 0xFF for error.
 */
extern cpm_f_error_t cpm_f_open(near_ptr_t fcb);

/**
 * @brief Write a record to the previously specified DMA address.
 *
 * @details The record is normally 128 bytes, but can be a multiple of 128 bytes.
 * Update byte returned values are:
 * - 0: OK
 * - 1: Directory full
 * - 2: Disc full
 * - 8: (MP/M) Record locked by another process
 * - 9: Invalid FCB
 * - 10: (CP/M) Media changed; (MP/M) FCB checksum error
 * - 11: (MP/M) Unlocked file verification error
 * - 0xFF: Hardware error??
 *
 * Lower byte, contains the number of 128-byte records written, before any error (CP/M 3 only).
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0 for success, or an error code as described above.
 */
extern cpm_f_error_t cpm_f_write(near_ptr_t fcb);

/**
 * @brief Creates the file specified by the FCB.
 *
 * @details Returns error codes in BA and HL.
 *
 * If the directory is full, the function return an upper byte of 0xFF.
 *
 * If the file already exists, the default action is to return to the command prompt. However, CP/M 3 may return a hardware error in
 * the lower byte
 *
 * Under MP/M II, set F5' to open the file in "unlocked" mode.
 *
 * Under MP/M II and later versions, set F6' to create the file with a password; the DMA address should point at a 9-byte buffer:
 *
 * @code
 * DEFS    8   ;Password
 * DEFB    1   ;Password mode
 * @endcode
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0 for success, or an error code as described above.
 */
extern cpm_f_error_t cpm_f_make(near_ptr_t fcb);

/**
 * @brief Set or retrieve the current user number.
 *
 * @details If number=0xFF, returns the current user number.
 *
 * Set the current user number. number should be 0-15, or 255 to retrieve the current user number. Some versions can use user areas
 * 16-31, but these should be avoided for compatibility reasons.
 *
 * @param[in] number The user number to set (0-15) or 255 to retrieve the current user number.
 *
 * @return The current user number if number is 255, otherwise the number set.
 */
extern uint8_t cpm_f_usernum(const uint8_t number);

/**
 * @brief Close a file and write any pending data.
 *
 * @details This function closes a file and writes any pending data. It should always be used when a file has been written to.
 *
 * On return from this function, A is 0xFF for error, or 0-3 for success. Some versions always return zero; others return 0-3 to
 * indicate that an image of the directory entry is to be found at (80h+20h*A).
 *
 * Under CP/M 3, if F5' is set to 1, the pending data are written and the file is made consistent, but it remains open.
 *
 * If A=0xFF, CP/M 3 returns a hardware error in H and B.
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0-3 for success, or 0xFF for error.
 */
extern cpm_f_error_t cpm_f_close(near_ptr_t fcb);

/**
 * @brief Search for the first occurrence of the specified file.
 *
 * BDOS function 17 (F_SFIRST) - search for first
 * Supported by: All versions
 *
 * Searches for the first occurrence of the specified file. The filename should be stored in the supplied FCB.  The filename can
 * include '?' marks, which match any character on the disk. If the first byte of the FCB is '?',  then any directory entry
 * (including disk labels, date stamps, etc.) will match. The EX byte is also checked; normally it should be set to zero, but if it
 * is set to '?', then all suitable extents are matched.
 *
 * @param fcb The address of the FCB.
 * @return cpm_f_error_t Error codes in BA and HL.
 *
 * Returns 0xFF in the upper byte if an error occurs (CP/M 3 returns a hardware error in lower byte), or A=0-3 un upper byte if
 * successful.
 *
 * Under CP/M-86 v4, if the first byte of the FCB is '?' or bit 7 of the byte is set, subdirectories as well as files will be
 * returned by this search.
 */
extern cpm_f_error_t cpm_f_sfirst(near_ptr_t fcb);

/**
 * @brief Search for the next occurrence of the specified file.
 *
 * BDOS function 18 (F_SNEXT) - search for next
 * Supported by: All versions
 * Entered with C=0x12, DE=address of FCB. Returns error codes in BA and HL.
 *
 * This function should only be executed immediately after function 17 or another invocation of function 18.  No other disk access
 * functions should have been used.
 *
 * Function 18 behaves exactly as function 17, but finds the next occurrence of the specified file after the one returned last time.
 * The FCB parameter is not documented, but Jim Lopushinsky states in LD301.DOC:
 *
 *   In none of the official Programmer's Guides for any version of CP/M does it say that an FCB is required for Search Next
 *   (function 18). However, if the FCB passed to Search First contains an unambiguous file reference (i.e. no question marks), then
 *   the Search Next function requires an FCB passed in reg DE (for CP/M-80) or DX (for CP/M-86).
 *
 * @param fcb The address of the FCB.
 * @return cpm_f_error_t Error codes in BA and HL.
 */
extern cpm_f_error_t cpm_f_snext(near_ptr_t fcb);

/**
 * @brief Deletes a file.
 *
 * BDOS function 19 (F_DELETE) - delete file.
 * Supported by: All versions.
 *
 * @param fcb Address of the FCB.
 * @return Error codes in BA and HL.
 *
 * Deletes all directory entries matching the specified filename. The name can contain '?' marks.
 * Returns 0xFF in the upper byte if an error occurs (CP/M 3 returns a hardware error in lower byte), or 0-3 in upper byte if
 * successful.
 *
 * Under CP/M 3, if bit F5' is set to 1, the file remains but any password protection is removed.
 * If the file has any password protection at all, the DMA address must be pointing at the password when this function is called.
 */
extern cpm_f_error_t cpm_f_delete(near_ptr_t fcb);

/**
 * @brief Load a record at the previously specified DMA address.
 *
 * @details Loads a record (normally 128 bytes, but under CP/M 3 this can be a multiple of 128 bytes) at the previously specified
 * DMA address.
 *
 * BDOS function 20 (F_READ) read record
 * Supported by all versions.
 *
 * Values returned in upper byte are:
 * - 0: OK
 * - 1: End of file
 * - 9: Invalid FCB
 * - 10: (CP/M) Media changed; (MP/M) FCB checksum error
 * - 11: (MP/M) Unlocked file verification error
 * - 0xFF: Hardware error
 *
 * If on return upper byte is not 0xFF, the lower byte contains the number of 128-byte records read before the error (MP/M II and
 * later).
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0 for success, or an error code as described above.
 */
extern cpm_f_error_t cpm_f_read(near_ptr_t fcb);

/**
 * @brief Rename a file.
 *
 * @details BDOS function 23 (F_RENAME) - Supported by all versions.
 *
 * Renames the file specified to the new name, stored at FCB+16. This function cannot rename across drives, so the "drive" bytes of
 * both filenames should be identical. Returns A=0-3 if successful; A=0xFF if error. Under CP/M 3, if H is zero then the file could
 * not be found; if it is nonzero it contains a hardware error number.
 *
 * Under Concurrent CP/M, set F5' if an extended lock on the file should be held through the rename. Otherwise, the lock will be
 * released.
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0-3 for success, or 0xFF for error.
 */
extern cpm_f_error_t cpm_f_rename(near_ptr_t fcb);

/**
 * @brief Set file attributes.
 *
 * @details BDOS function 30 (F_ATTRIB) - Supported by CP/M 2 and later.
 *
 * Sets and resets the bits required. Standard CP/M versions allow the bits F1', F2', F3', F4', T1' (read-only), T2' (system), and
 * T3' (archive) to be changed. Some alternative BDOS versions allow F5', F6', F7', and F8' to be set, but this is not encouraged
 * since setting these bits can cause CP/M 3 to behave differently.
 *
 * Under Concurrent CP/M, if the F5' bit is not set and the file has an extended file lock, the lock will be released when the
 * attributes are set. If F5' is set, the lock stays.
 *
 * Under CP/M 3, the Last Record Byte Count is set by storing the required value at FCB+32 (FCB+20h) and setting the F6' bit.
 *
 * The code returned in A is 0-3 if the operation was successful, or 0xFF if there was an error. Under CP/M 3, if A is 0xFF and H is
 * nonzero, H contains a hardware error.
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0-3 for success, or 0xFF for error.
 */
extern cpm_f_error_t cpm_f_attrib(near_ptr_t fcb);

/**
 * @brief Random access read record.
 *
 * @details BDOS function 33 (F_READRAND) - Supported by CP/M 2 and later.
 *
 * Reads the record specified in the random record count area of the FCB, at the DMA address. The pointers in the FCB will be
 * updated so that the next record to read using the sequential I/O calls will be the record just read.
 *
 * Error numbers returned are:
 * - 0: OK
 * - 1: Reading unwritten data
 * - 4: Reading unwritten extent (a 16k portion of file does not exist)
 * - 6: Record number out of range
 * - 9: Invalid FCB
 * - 10: Media changed (CP/M); FCB checksum error (MP/M)
 * - 11: Unlocked file verification error (MP/M)
 * - 0xFF: [MP/M II, CP/M 3] Hardware error in H.
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0 for success, or an error code as described above.
 */
extern cpm_f_error_t cpm_f_readrand(near_ptr_t fcb);

/**
 * @brief Random access write record.
 *
 * @details BDOS function 34 (F_WRITERAND) - Supported by CP/M 2 and later.
 *
 * Writes the record specified in the random record count area of the FCB, at the DMA address. The pointers in the FCB will be
 * updated so that the next record to write using the sequential I/O calls will be the record just written.
 *
 * Error numbers returned are:
 * - 0: OK
 * - 2: Disc full
 * - 3: Cannot close extent
 * - 5: Directory full
 * - 6: Record number out of range
 * - 8: Record is locked by another process (MP/M)
 * - 9: Invalid FCB
 * - 10: Media changed (CP/M); FCB checksum error (MP/M)
 * - 11: Unlocked file verification error (MP/M)
 * - 0xFF: [MP/M II, CP/M 3] Hardware error in H.
 *
 * If the record indicated is beyond the end of the file, the record will be written and the file may contain a gap; attempting to
 * read this gap may give "reading unwritten data" errors, or nonsense.
 *
 * @param[in] fcb The near pointer to the File Control Block (FCB).
 *
 * @return 0 for success, or an error code as described above.
 */
extern cpm_f_error_t cpm_f_writerand(near_ptr_t fcb);

/**
 * @brief Compute the size of a file.
 *
 * @details BDOS function 35 (F_SIZE) - Supported by CP/M 2 and later.
 *
 * Computes the size of a file by setting the random record count bytes of the FCB to the number of 128-byte records in the file.
 *
 * @note Under CP/M 2, the value returned has no meaning;
 * the function does not distinguish between a zero-length file and one that does not exist at all.
 * Under CP/M 3, returns 0xFF if there is an error (file not found, or CP/M 3 hardware error);
 * otherwise, returns A=0.
 *
 * @param[in] fcb A pointer to the File Control Block (FCB).
 * @return  * @return 0 for success, or an error code as described above.
 *
 *
 */
extern cpm_f_error_t cpm_f_size(near_ptr_t fcb);

/* Size of CPM Sector */
#define SECSIZE 128

/* Flags for fcp->use */
#define U_READ  1 /* file open for reading */
#define U_WRITE 2 /* file open for writing */
#define U_RDWR  3 /* open for read and write */
#define U_CON   4 /* device is console */
#define U_RDR   5 /* device is reader */
#define U_PUN   6 /* device is punch */
#define U_LST   7 /* list device */

#define __STDIO_EOFMARKER 26 /* End of file marker (^Z) */
#define __STDIO_BINARY    1  /* We should consider binary/text differences */
#define __STDIO_CRLF      1  /* Automatically convert between CR and CRLF */

#define CPM_ERR_OK               0
#define CPM_ERR_DIR_FULL_        1
#define CPM_ERR_EOF              1
#define CPM_ERR_UNWRITTEN        1
#define CPM_ERR_DISC_FULL        2
#define CPM_ERR_CLOSE_EXTENT     3
#define CPM_ERR_UNWRITTEN_EXTENT 4
#define CPM_ERR_DIR_FULL         5
#define CPM_ERR_REC_OUT_OF_RANGE 6
#define CPM_ERR_REC_LOCKED       8
#define CPM_ERR_INVALID_FCB      9
#define CPM_ERR_MEDIA_CHANGED    10
#define CPM_ERR_UNLOCKED_FILE    11

#define CPM_ERR_GENERAL 255

#define CPM_EXERR_SELECT_ERROR      (128 + 1)
#define CPM_EXERR_READONLY_FILE     (128 + 2)
#define CPM_EXERR_READONLY_DISC     (128 + 3)
#define CPM_EXERR_INVALID_DRIVE     (128 + 4)
#define CPM_EXERR_FILE_ALREADY_OPEN (128 + 5)
#define CPM_EXERR_FCB_CHECKSUM      (128 + 6)
#define CPM_EXERR_PASSWORD          (128 + 7)
#define CPM_EXERR_FILE_EXISTS       (128 + 8)
#define CPM_EXERR_BAD_FILENAME      (128 + 9)
#define CPM_EXERR_WHEEL_PROTECTION  (128 + 10)
#define CPM_EXERR_TOO_MANY_FILES    (128 + 10)
#define CPM_EXERR_NO_ROOM           (128 + 11)
#define CPM_EXERR_NOT_LOGGED_IN     (128 + 12)

#endif
