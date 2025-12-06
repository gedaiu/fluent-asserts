/// Cross-platform memory utilities for fluent-asserts.
/// Provides functions to query process memory usage across different operating systems.
module fluentasserts.core.memory;

import core.memory : GC;

version (OSX) {
    private extern (C) nothrow @nogc {
        alias mach_port_t = uint;
        alias task_info_t = int*;
        alias mach_msg_type_number_t = uint;
        alias kern_return_t = int;

        enum MACH_TASK_BASIC_INFO = 20;
        enum KERN_SUCCESS = 0;

        struct mach_task_basic_info {
            int suspend_count;
            size_t virtual_size;
            size_t resident_size;
            ulong user_time;
            ulong system_time;
            int policy;
        }

        enum MACH_TASK_BASIC_INFO_COUNT = mach_task_basic_info.sizeof / uint.sizeof;

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

/// Returns an estimate of non-GC heap memory used by the process.
/// Calculated as total process memory minus the GC heap size.
/// Note: This is an approximation as process memory includes code, stack, and shared libraries.
/// Returns: Estimated non-GC memory in bytes.
size_t getNonGCMemory() @trusted nothrow {
    auto total = getProcessMemory();
    auto gcStats = GC.stats();
    auto gcTotal = gcStats.usedSize + gcStats.freeSize;
    return total > gcTotal ? total - gcTotal : 0;
}

/// Returns the current GC heap usage.
/// Returns: GC used memory in bytes.
size_t getGCMemory() @trusted nothrow {
    return GC.stats().usedSize;
}
