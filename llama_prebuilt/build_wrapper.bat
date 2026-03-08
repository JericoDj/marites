@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo    Llama Wrapper DLL Build Script
echo ==========================================
echo.
echo This script compiles the C++ wrapper (llama_wrapper.cpp)
echo into a dynamic library (llama_wrapper.dll) that Flutter can use.
echo.

:: 1. Check for MSVC Compiler
where cl.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] MSVC Compiler ^(cl.exe^) not found!
    echo Please run this script inside the "x64 Native Tools Command Prompt for VS".
    exit /b 1
)

:: 2. Create DEF file for the pre-built llama.dll
echo [1/3] Extracting exported functions from llama.dll...
dumpbin /EXPORTS llama.dll > exports.txt

echo EXPORTS > llama.def
for /f "tokens=4" %%A in ('findstr "llama_" exports.txt') do (
    echo %%A >> llama.def
)

:: 3. Generate the Import Library (.lib)
echo [2/3] Generating Import Library ^(llama.lib^)...
lib /def:llama.def /out:llama.lib /machine:x64 >nul

:: 4. Compile the Wrapper
echo [3/3] Compiling llama_wrapper.cpp into llama_wrapper.dll...
cl.exe /LD /O2 /EHsc /I..\native ..\native\llama_wrapper.cpp /link llama.lib /OUT:llama_wrapper.dll

:: 5. Cleanup temporary files
del exports.txt
del llama.def
del llama_wrapper.obj
del llama_wrapper.exp
del llama_wrapper.lib

echo.
echo ==========================================
echo    Build Complete! llama_wrapper.dll created.
echo ==========================================
