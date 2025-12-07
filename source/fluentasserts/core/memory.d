/// Cross-platform memory utilities for fluent-asserts.
/// Provides functions to query process memory usage across different operating systems.
module fluentasserts.core.memory;

import core.memory : GC;

version (linux) {
    private extern (C) nothrow @nogc {
        struct mallinfo {
            int arena;     // Non-mmapped space allocated (bytes)
            int ordblks;   // Number of free chunks
            int smblks;    // Number of free fastbin blocks
            int hblks;     // Number of mmapped regions
            int hblkhd;    // Space allocated in mmapped regions (bytes)
            int usmblks;   // Unused
            int fsmblks;   // Space in freed fastbin blocks (bytes)
            int uordblks;  // Total allocated space (bytes)
            int fordblks;  // Total free space (bytes)
            int keepcost;  // Top-most, releasable space (bytes)
        }

        mallinfo mallinfo();
    }
}

version (OSX) {
    private extern (C) nothrow @nogc {
        alias mach_port_t = uint;
        alias task_info_t = int*;
        alias mach_msg_type_number_t = uint;
        alias kern_return_t = int;

        enum MACH_TASK_BASIC_INFO = 20;
        enum TASK_VM_INFO = 22;
        enum KERN_SUCCESS = 0;

        struct mach_task_basic_info {
            int suspend_count;
            size_t virtual_size;
            size_t resident_size;
            ulong user_time;
            ulong system_time;
            int policy;
        }

        // TASK_VM_INFO structure - phys_footprint is what top/Xcode use
        // Using ulong (64-bit) for mach_vm_size_t fields, uint for natural_t
        struct task_vm_info {
            ulong virtual_size;          // mach_vm_size_t
            uint region_count;           // natural_t
            int page_size;               // int
            ulong resident_size;         // mach_vm_size_t
            ulong resident_size_peak;    // mach_vm_size_t
            ulong device;                // mach_vm_size_t
            ulong device_peak;           // mach_vm_size_t
            ulong internal;              // mach_vm_size_t
            ulong internal_peak;         // mach_vm_size_t
            ulong external;              // mach_vm_size_t
            ulong external_peak;         // mach_vm_size_t
            ulong reusable;              // mach_vm_size_t
            ulong reusable_peak;         // mach_vm_size_t
            ulong purgeable_volatile_pmap;
            ulong purgeable_volatile_resident;
            ulong purgeable_volatile_virtual;
            ulong compressed;            // mach_vm_size_t
            ulong compressed_peak;       // mach_vm_size_t
            ulong compressed_lifetime;   // mach_vm_size_t
            ulong phys_footprint;        // mach_vm_size_t - This is what we want
            ulong min_address;           // mach_vm_address_t
            ulong max_address;           // mach_vm_address_t
        }

        enum MACH_TASK_BASIC_INFO_COUNT = mach_task_basic_info.sizeof / uint.sizeof;
        enum TASK_VM_INFO_COUNT = task_vm_info.sizeof / uint.sizeof;

        mach_port_t mach_task_self();
        kern_return_t task_info(mach_port_t, int, task_info_t, mach_msg_type_number_t*);
    }
}

version (Windows) {
    private extern (Windows) nothrow @nogc {
        alias HANDLE = void*;
        alias DWORD = uint;
        alias BOOL = int;

        struct PROCESS_MEMORY_COUNTERS {
            DWORD cb;
            DWORD PageFaultCount;
            size_t PeakWorkingSetSize;
            size_t WorkingSetSize;
            size_t QuotaPeakPagedPoolUsage;
            size_t QuotaPagedPoolUsage;
            size_t QuotaPeakNonPagedPoolUsage;
            size_t QuotaNonPagedPoolUsage;
            size_t PagefileUsage;
            size_t PeakPagefileUsage;
        }

        HANDLE GetCurrentProcess();
        BOOL GetProcessMemoryInfo(HANDLE, PROCESS_MEMORY_COUNTERS*, DWORD);
    }
}

/// Returns the total resident memory used by the current process in bytes.
/// Uses platform-specific APIs: /proc/self/status on Linux, task_info on macOS,
/// GetProcessMemoryInfo on Windows.
/// Returns: Process resident memory in bytes, or 0 if unavailable.
size_t getProcessMemory() @trusted nothrow {
    version (linux) {
        import std.stdio : File;
        import std.conv : to;
        import std.algorithm : startsWith;
        import std.array : split;

        try {
            auto f = File("/proc/self/status", "r");
            foreach (line; f.byLine) {
                if (line.startsWith("VmRSS:")) {
                    auto parts = line.split();
                    if (parts.length >= 2) {
                        return parts[1].to!size_t * 1024;
                    }
                }
            }
        } catch (Exception) {}
        return 0;
    }
    else version (OSX) {
        mach_task_basic_info info;
        mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
        if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, cast(task_info_t)&info, &count) == KERN_SUCCESS) {
            return info.resident_size;
        }
        return 0;
    }
    else version (Windows) {
        PROCESS_MEMORY_COUNTERS pmc;
        pmc.cb = PROCESS_MEMORY_COUNTERS.sizeof;
        if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, pmc.cb)) {
            return pmc.WorkingSetSize;
        }
        return 0;
    }
    else {
        return 0;
    }
}

/// Returns the C heap (malloc) memory currently in use.
/// Uses platform-specific APIs for accurate measurement:
/// - Linux: mallinfo() for malloc arena statistics
/// - macOS: malloc_zone_statistics() for zone-based allocation stats
/// - Windows: Falls back to process memory estimation
/// Returns: Malloc heap usage in bytes.
size_t getNonGCMemory() @trusted nothrow {
    version (linux) {
        auto info = mallinfo();
        // uordblks = total allocated space, hblkhd = mmap'd space
        return cast(size_t)(info.uordblks + info.hblkhd);
    }
    else version (OSX) {
        // Use phys_footprint from TASK_VM_INFO - this is what top/Xcode use.
        // It tracks dirty (written to) memory, which captures malloc allocations.
        // We return raw phys_footprint since evaluation.d takes a delta.
        task_vm_info info;
        mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
        if (task_info(mach_task_self(), TASK_VM_INFO, cast(task_info_t)&info, &count) == KERN_SUCCESS) {
            return cast(size_t)info.phys_footprint;
        }
        return 0;
    }
    else version (Windows) {
        // Windows: fall back to process memory estimation
        auto total = getProcessMemory();
        auto gcStats = GC.stats();
        auto gcTotal = gcStats.usedSize + gcStats.freeSize;
        return total > gcTotal ? total - gcTotal : 0;
    }
    else {
        return 0;
    }
}

/// Returns the current GC heap usage.
/// Returns: GC used memory in bytes.
size_t getGCMemory() @trusted nothrow {
    return GC.stats().usedSize;
}
