// -----------------------------------------------------------------------------
// DOS HEADER related types and constants

type
  TLARGE_INTEGER = TLargeInteger;

const
  IMAGE_DOS_SIGNATURE = $5a4d;  // 'MZ'

type
  PIMAGE_DOS_HEADER   = ^TIMAGE_DOS_HEADER;
  TIMAGE_DOS_HEADER   = packed record
    Signature              : word;
    BytesOnLastPage        : word;
    PageCount              : word;
    RelocationsCount       : word;
    HeaderInParagraphs     : word;
    ExtraParagraphsNeeded  : word;
    MaximumMemory          : word;
    InitialSS              : word;
    InitialSP              : word;
    Checksum               : word;
    InitialIp              : word;
    InitialCs              : word;
    RelocationsTableOffset : word;
    OverlayNumber          : word;
    ReservedWordsA         : packed array[0..3] of word;
    OEMidentifier          : word;
    OEMinformation         : word;
    ReservedWordsB         : packed array[0..9] of word;
    OffsetToNewExecutable  : DWORD;
  end;

// -----------------------------------------------------------------------------
// IMAGE FILE HEADER related types and constants

const
  IMAGE_FILE_MACHINE_UNKNOWN     =     0;
  IMAGE_FILE_MACHINE_I386        = $014c;  // Intel 386.

  IMAGE_FILE_MACHINE_R3000       = $0162;  // MIPS little-endian,
                                           // = $160 big-endian

  IMAGE_FILE_MACHINE_R4000       = $0166;  // MIPS little-endian
  IMAGE_FILE_MACHINE_R10000      = $0168;  // MIPS little-endian
  IMAGE_FILE_MACHINE_WCEMIPSV2   = $0169;  // MIPS little-endian WCE v2

  IMAGE_FILE_MACHINE_ALPHA       = $0184;  // Alpha_AXP

  IMAGE_FILE_MACHINE_SH3         = $01a2;  // SH3 little-endian
  IMAGE_FILE_MACHINE_SH3DSP      = $01a3;
  IMAGE_FILE_MACHINE_SH3E        = $01a4;  // SH3E little-endian
  IMAGE_FILE_MACHINE_SH4         = $01a6;  // SH4 little-endian
  IMAGE_FILE_MACHINE_SH5         = $01a8;  // SH5

  IMAGE_FILE_MACHINE_ARM         = $01c0;  // ARM Little-Endian
  IMAGE_FILE_MACHINE_THUMB       = $01c2;
  IMAGE_FILE_MACHINE_AM33        = $01d3;
  IMAGE_FILE_MACHINE_POWERPC     = $01F0;  // IBM PowerPC Little-Endian
  IMAGE_FILE_MACHINE_POWERPCFP   = $01f1;
  IMAGE_FILE_MACHINE_IA64        = $0200;  // Intel 64
  IMAGE_FILE_MACHINE_MIPS16      = $0266;  // MIPS
  IMAGE_FILE_MACHINE_ALPHA64     = $0284;  // ALPHA64
  IMAGE_FILE_MACHINE_MIPSFPU     = $0366;  // MIPS
  IMAGE_FILE_MACHINE_MIPSFPU16   = $0466;  // MIPS
  IMAGE_FILE_MACHINE_AXP64       = IMAGE_FILE_MACHINE_ALPHA64;
  IMAGE_FILE_MACHINE_TRICORE     = $0520;  // Infineon
  IMAGE_FILE_MACHINE_CEF         = $0CEF;
  IMAGE_FILE_MACHINE_EBC         = $0EBC;  // EFI Byte Code
  IMAGE_FILE_MACHINE_AMD64       = $8664;  // AMD64 (K8)
  IMAGE_FILE_MACHINE_M32R        = $9041;  // M32R little-endian
  IMAGE_FILE_MACHINE_CEE         = $C0EE;

const
  // characteristic flags

  IMAGE_FILE_LARGE_ADDRESS_AWARE =   $20;

type
  PIMAGE_FILE_HEADER = ^TIMAGE_FILE_HEADER;
  TIMAGE_FILE_HEADER = packed record
    Machine              :  word;
    NumberOfSections     :  word;
    TimeDateStamp        : DWORD;
    PointerToSymbolTable : DWORD;
    NumberOfSymbols      : DWORD;
    SizeOfOptionalHeader :  word;
    Characteristics      :  word;
  end;

  IMAGE_FILE_HEADER = TIMAGE_FILE_HEADER;


// -----------------------------------------------------------------------------
// DATA DIRECTORY related types and constants

const
  IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16;

type
  TDATA_DIRECTORY_RANGE = 0 .. IMAGE_NUMBEROF_DIRECTORY_ENTRIES - 1;

  PIMAGE_DATA_DIRECTORY = ^TIMAGE_DATA_DIRECTORY;
  TIMAGE_DATA_DIRECTORY = record
    VirtualAddress          : DWORD;
    Size                    : DWORD;
  end;

// -----------------------------------------------------------------------------
// OPTIONAL HEADER related types and constants

const
  IMAGE_NT_OPTIONAL_HDR32_MAGIC = $10b;
  IMAGE_NT_OPTIONAL_HDR64_MAGIC = $20b;
  IMAGE_ROM_OPTIONAL_HDR_MAGIC  = $107;

type
  PIMAGE_OPTIONAL_HEADER32 = ^TIMAGE_OPTIONAL_HEADER32;
  TIMAGE_OPTIONAL_HEADER32 = packed record

    // common fields.

    Magic                       :  word;
    MajorLinkerVersion          :  byte;
    MinorLinkerVersion          :  byte;
    SizeOfCode                  : DWORD;
    SizeOfInitializedData       : DWORD;
    SizeOfUninitializedData     : DWORD;
    AddressOfEntryPoint         : DWORD;
    BaseOfCode                  : DWORD;

    BaseOfData                  : DWORD;             // not present in 64bit

    ImageBase                   : DWORD;
    SectionAlignment            : DWORD;
    FileAlignment               : DWORD;
    MajorOperatingSystemVersion :  word;
    MinorOperatingSystemVersion :  word;
    MajorImageVersion           :  word;
    MinorImageVersion           :  word;
    MajorSubsystemVersion       :  word;
    MinorSubsystemVersion       :  word;
    Win32VersionValue           : DWORD;
    SizeOfImage                 : DWORD;
    SizeOfHeaders               : DWORD;
    CheckSum                    : DWORD;
    Subsystem                   :  word;
    DllCharacteristics          :  word;

    SizeOfStackReserve          : DWORD;             // different size in 64bit
    SizeOfStackCommit           : DWORD;
    SizeOfHeapReserve           : DWORD;
    SizeOfHeapCommit            : DWORD;

    LoaderFlags                 : DWORD;
    NumberOfRvaAndSizes         : DWORD;
    DataDirectory               : array [TDATA_DIRECTORY_RANGE]
                                     of  TIMAGE_DATA_DIRECTORY;
  end;

type
  PIMAGE_OPTIONAL_HEADER64 = ^TIMAGE_OPTIONAL_HEADER64;
  TIMAGE_OPTIONAL_HEADER64 = packed record
    Magic                       :  word;
    MajorLinkerVersion          :  byte;
    MinorLinkerVersion          :  byte;
    SizeOfCode                  : DWORD;
    SizeOfInitializedData       : DWORD;
    SizeOfUninitializedData     : DWORD;
    AddressOfEntryPoint         : DWORD;
    BaseOfCode                  : DWORD;
                                                     // no BaseOfData field
    ImageBase                   : TLARGE_INTEGER;
    SectionAlignment            : DWORD;
    FileAlignment               : DWORD;
    MajorOperatingSystemVersion :  word;
    MinorOperatingSystemVersion :  word;
    MajorImageVersion           :  word;
    MinorImageVersion           :  word;
    MajorSubsystemVersion       :  word;
    MinorSubsystemVersion       :  word;
    Win32VersionValue           : DWORD;
    SizeOfImage                 : DWORD;
    SizeOfHeaders               : DWORD;
    CheckSum                    : DWORD;
    Subsystem                   :  word;
    DllCharacteristics          :  word;
    SizeOfStackReserve          : TLARGE_INTEGER;    // different size in 32bit
    SizeOfStackCommit           : TLARGE_INTEGER;
    SizeOfHeapReserve           : TLARGE_INTEGER;
    SizeOfHeapCommit            : TLARGE_INTEGER;

    LoaderFlags                 : DWORD;
    NumberOfRvaAndSizes         : DWORD;
    DataDirectory               : array [TDATA_DIRECTORY_RANGE]
                                     of  TIMAGE_DATA_DIRECTORY;
  end;

type
  TIMAGE_OPTIONAL_HEADER = TIMAGE_OPTIONAL_HEADER64;
  PIMAGE_OPTIONAL_HEADER = PIMAGE_OPTIONAL_HEADER64;


// -----------------------------------------------------------------------------
// NT Header related types and constants

const
  IMAGE_NT_SIGNATURE = DWORD($4550);

type
  PIMAGE_NT_HEADERS64 = ^TIMAGE_NT_HEADERS64;
  TIMAGE_NT_HEADERS64 = packed record
    Signature             : DWORD;
    FileHeader            : TIMAGE_FILE_HEADER;
    OptionalHeader        : TIMAGE_OPTIONAL_HEADER64;
  end;

type
  PIMAGE_NT_HEADERS32 = ^TIMAGE_NT_HEADERS32;
  TIMAGE_NT_HEADERS32 = packed record
    Signature             : DWORD;
    FileHeader            : TIMAGE_FILE_HEADER;
    OptionalHeader        : TIMAGE_OPTIONAL_HEADER32;
  end;

type
  TIMAGE_NT_HEADERS = TIMAGE_NT_HEADERS64;
  PIMAGE_NT_HEADERS = PIMAGE_NT_HEADERS64;

// end of file
// -----------------------------------------------------------------------------
