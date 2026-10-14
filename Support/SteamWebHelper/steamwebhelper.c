/*
 * SPDX-License-Identifier: MIT
 * Adapted from https://github.com/notpop/steam-on-m1-wine/tree/main/wrapper
 * Copyright (c) 2026 notpop
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>

static int32_t report_failure(const wchar_t* const operation, const DWORD error)
{
    wchar_t diagnostic[256];
    swprintf(diagnostic, 256, L"Mythic Steam web helper: %ls failed (%lu).", operation, error);
    OutputDebugStringW(diagnostic);
    const wchar_t* const message = L"Unable to start Steam's browser. Close Steam and launch it again from Mythic.";
#ifndef NDEBUG
    wchar_t details[512];
    swprintf(details, 512, L"%ls\n\n%ls", message, diagnostic);
    MessageBoxW(NULL, details, L"Steam", MB_OK | MB_ICONERROR);
#else
    MessageBoxW(NULL, message, L"Steam", MB_OK | MB_ICONERROR);
#endif
    return 1;
}

int32_t WINAPI wWinMain(HINSTANCE instance, HINSTANCE previous, PWSTR arguments, int32_t show)
{
    (void)instance;
    (void)previous;
    (void)show;

    // CreateProcessW limits the complete command line to 32,767 characters plus its terminator.
    const size_t capacity = 32768;
    wchar_t executable[32768];
    const DWORD length = GetModuleFileNameW(NULL, executable, (DWORD)capacity);
    if (length == 0 || length >= capacity) {
        return report_failure(L"GetModuleFileNameW", length == 0 ? GetLastError() : ERROR_FILENAME_EXCED_RANGE);
    }

    wchar_t* const slash = wcsrchr(executable, L'\\');
    const wchar_t* const original_name = L"steamwebhelper.mythic-original.exe";
    if (slash == NULL || (size_t)(slash + 1 - executable) + wcslen(original_name) >= capacity) {
        return report_failure(L"Resolve original helper", ERROR_BAD_PATHNAME);
    }
    wcscpy(slash + 1, original_name);

    // Steam's parent flags do not reach CEF. Software rendering and one process fix its black window under Wine.
    const wchar_t* const flags = L"--disable-gpu --single-process";
    const size_t command_length = wcslen(executable) + wcslen(flags) + wcslen(arguments) + 5;
    if (command_length > capacity) {
        return report_failure(L"Build command line", ERROR_FILENAME_EXCED_RANGE);
    }
    wchar_t* const command = calloc(command_length, sizeof(wchar_t));
    if (command == NULL) {
        return report_failure(L"Allocate command line", ERROR_NOT_ENOUGH_MEMORY);
    }
    // Forward the CRT's raw argument tail so Unicode paths and Windows quoting remain intact.
    swprintf(command, command_length, L"\"%ls\" %ls %ls", executable, flags, arguments);

    STARTUPINFOW startup = {0};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION child = {0};
    // Steam supplies inheritable IPC handles; the real helper must receive them through the wrapper.
    const BOOL started = CreateProcessW(executable, command, NULL, NULL, TRUE, 0, NULL, NULL, &startup, &child);
    const DWORD launch_error = started ? ERROR_SUCCESS : GetLastError();
    free(command);
    if (!started) {
        return report_failure(L"CreateProcessW", launch_error);
    }
    CloseHandle(child.hThread);

    const DWORD waited = WaitForSingleObject(child.hProcess, INFINITE);
    DWORD exit_code;
    const BOOL retrieved = waited == WAIT_OBJECT_0 && GetExitCodeProcess(child.hProcess, &exit_code);
    const DWORD wait_error = retrieved ? ERROR_SUCCESS : GetLastError();
    CloseHandle(child.hProcess);
    if (!retrieved) {
        return report_failure(L"Wait for browser", wait_error);
    }
    return (int32_t)exit_code;
}
