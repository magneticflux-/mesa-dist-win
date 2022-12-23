@setlocal
@rem Create distribution.
@rem Keep both clover standalone and ICD intact
@IF EXIST "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\*penCL-1.dll" IF EXIST "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\*penCL.dll" del /Q "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\*penCL.dll"
@IF EXIST "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\MesaOpenCL-1.dll" REN "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\MesaOpenCL-1.dll" MesaOpenCL.dll
@IF EXIST "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\OpenCL-1.dll" REN "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\OpenCL-1.dll" OpenCL.dll
@IF EXIST "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\libMesaOpenCL-1.dll" REN "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\libMesaOpenCL-1.dll" MesaOpenCL.dll
@IF EXIST "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\libOpenCL-1.dll" REN "%devroot%\mesa\build\%toolchain%-%abi%\src\gallium\targets\opencl\libOpenCL-1.dll" OpenCL.dll

@set dist=n
@set /p dist=Create or update Mesa3D distribution package (y/n):
@echo.
@if /I NOT "%dist%"=="y" GOTO donedist
@cd "%devroot%\%projectname%"

@rem Normal distribution vs Meson install
@set normaldist=1
@IF %normaldist% EQU 1 GOTO normaldist

@IF %toolchain%==msvc GOTO donedist
@%mesonloc% install --no-rebuild --skip-subprojects -C "%devroot%\mesa\build\%toolchain%-%abi%"
@echo.
@GOTO donedist

:normaldist
@set keeplastbuild=n
@IF %toolchain%==msvc IF EXIST lib\%abi%\*.lib set /p keeplastbuild=Keep binaries and libraries from previous build (y/n):
@IF %toolchain%==msvc IF EXIST lib\%abi%\*.lib echo.
@if NOT EXIST "bin\" MD bin
@if NOT EXIST "lib\" MD lib
@IF /I NOT "%keeplastbuild%"=="y" if EXIST "bin\%abi%\" RD /S /Q bin\%abi%
@IF /I NOT "%keeplastbuild%"=="y" if EXIST "lib\%abi%\" RD /S /Q lib\%abi%
@IF /I NOT "%keeplastbuild%"=="y" if EXIST "debug\%abi%\" RD /S /Q debug\%abi%
@IF /I NOT "%keeplastbuild%"=="y" if EXIST "include\" RD /S /Q include
@if NOT EXIST "bin\%abi%\" MD bin\%abi%
@if NOT EXIST "lib\%abi%\" MD lib\%abi%
@if NOT EXIST "lib\%abi%\pkgconfig\" MD lib\%abi%\pkgconfig
@if NOT EXIST "debug\%abi%\" MD debug\%abi%
@if NOT EXIST "include\" MD include

:mesondist
@echo Copying Mesa3D shared libraries and PDBs...
@for /R "%devroot%\mesa\build\%toolchain%-%abi%\src" %%a IN (*.dll) do @(
@IF EXIST "%%a" copy "%%a" "%devroot%\%projectname%\bin\%abi%"
@IF EXIST "%%~dpna.pdb" copy "%%~dpna.pdb" "%devroot%\%projectname%\debug\%abi%"
)
@IF EXIST "%devroot%\%projectname%\bin\%abi%\libclon12compiler.dll" REN "%devroot%\%projectname%\bin\%abi%\libclon12compiler.dll" clon12compiler.dll
@echo.

@echo Copying runtimes for Microsoft drivers if needed...
@IF EXIST "%devroot%\%projectname%\bin\%abi%\*on12compiler.dll" for /R "%devroot%\clon12\out\%abi%\bin" %%a IN (*.dll) do @IF EXIST "%%a" copy "%%a" "%devroot%\%projectname%\bin\%abi%"
@IF EXIST "%devroot%\%projectname%\bin\%abi%\*pirv_to_dxil.dll" IF NOT EXIST "%devroot%\%projectname%\bin\%abi%\dxil.dll" for /f delims^=^ eol^= %%a in ('@call "%devroot%\%projectname%\buildscript\modules\dxil.cmd"') do @IF EXIST %%a copy %%a "%devroot%\%projectname%\bin\%abi%"
@IF EXIST "%devroot%\%projectname%\bin\%abi%\openglon12.dll" IF NOT EXIST "%devroot%\%projectname%\bin\%abi%\dxil.dll" for /f delims^=^ eol^= %%a in ('@call "%devroot%\%projectname%\buildscript\modules\dxil.cmd"') do @IF EXIST %%a copy %%a "%devroot%\%projectname%\bin\%abi%"
@IF EXIST "%devroot%\%projectname%\bin\%abi%\openclon12.dll" IF NOT EXIST "%devroot%\%projectname%\bin\%abi%\dxil.dll" for /f delims^=^ eol^= %%a in ('@call "%devroot%\%projectname%\buildscript\modules\dxil.cmd"') do @IF EXIST %%a copy %%a "%devroot%\%projectname%\bin\%abi%"
@IF EXIST "%devroot%\%projectname%\bin\%abi%\vulkan_dzn.dll" IF NOT EXIST "%devroot%\%projectname%\bin\%abi%\dxil.dll" for /f delims^=^ eol^= %%a in ('@call "%devroot%\%projectname%\buildscript\modules\dxil.cmd"') do @IF EXIST %%a copy %%a "%devroot%\%projectname%\bin\%abi%"
@IF EXIST "%devroot%\%projectname%\bin\%abi%\*aon12_drv_video.dll" IF NOT EXIST "%devroot%\%projectname%\bin\%abi%\dxil.dll" for /f delims^=^ eol^= %%a in ('@call "%devroot%\%projectname%\buildscript\modules\dxil.cmd"') do @IF EXIST %%a copy %%a "%devroot%\%projectname%\bin\%abi%"
@echo.

@echo Copying test suite and commandline utilities...
@for /R "%devroot%\mesa\build\%toolchain%-%abi%\src" %%a IN (*.exe) do @IF EXIST "%%a" copy "%%a" "%devroot%\%projectname%\bin\%abi%"
@echo.

@echo Copying Vulkan drivers initialization configuration files if needed...
@IF EXIST "%devroot%\%projectname%\bin\%abi%\vulkan_lvp.dll" for /R "%devroot%\mesa\build\%toolchain%-%abi%\src" %%a IN (lvp_icd.*.json) do @IF EXIST "%%a" copy "%%a" "%devroot%\%projectname%\bin\%abi%"
@IF EXIST "%devroot%\%projectname%\bin\%abi%\*ulkan_radeon.dll" for /R "%devroot%\mesa\build\%toolchain%-%abi%\src" %%a IN (radeon_icd.*.json) do @IF EXIST "%%a" copy "%%a" "%devroot%\%projectname%\bin\%abi%"
@IF EXIST "%devroot%\%projectname%\bin\%abi%\vulkan_dzn.dll" for /R "%devroot%\mesa\build\%toolchain%-%abi%\src" %%a IN (dzn_icd.*.json) do @IF EXIST "%%a" copy "%%a" "%devroot%\%projectname%\bin\%abi%"
@echo.

@rem Patch Vulkan drivers JSONs
@IF EXIST "%devroot%\%projectname%\bin\%abi%\lvp_icd.*.json" call "%devroot%\%projectname%\buildscript\modules\fixvulkanjsons.cmd" lvp
@IF EXIST "%devroot%\%projectname%\bin\%abi%\radeon_icd.*.json" call "%devroot%\%projectname%\buildscript\modules\fixvulkanjsons.cmd" radeon
@IF EXIST "%devroot%\%projectname%\bin\%abi%\dzn_icd.*.json" call "%devroot%\%projectname%\buildscript\modules\fixvulkanjsons.cmd" dzn

@echo Copying static libraries...
@for /R "%devroot%\mesa\build\%toolchain%-%abi%" %%a IN (*.lib) do @IF EXIST "%%a" copy "%%a" "%devroot%\%projectname%\lib\%abi%"
@for /R "%devroot%\mesa\build\%toolchain%-%abi%" %%a IN (*.dll.a) do @IF EXIST "%%a" copy "%%a" "%devroot%\%projectname%\lib\%abi%"
@echo.

@echo Copying pkg-config scripts...
@for /R "%devroot%\mesa\build\%toolchain%-%abi%\meson-private" %%a IN (*.pc) do @IF EXIST "%%a" IF /I NOT "%%~na"=="DirectX-Headers" IF /I NOT "%%~na"=="libelf" IF /I NOT "%%~na"=="zlib" copy "%%a" "%devroot%\%projectname%\lib\%abi%\pkgconfig"
@echo.

@IF /I NOT "%keeplastbuild%"=="y" echo Copying headers...
@IF /I NOT "%keeplastbuild%"=="y" ROBOCOPY "%devroot%\mesa\include" "%devroot%\%projectname%\include" /E
@IF /I NOT "%keeplastbuild%"=="y" echo.

:donedist
@IF EXIST "%devroot%\%projectname%\bin\%abi%\*.dll" IF NOT EXIST "%devroot%\%projectname%\lib\%abi%\*.lib" set /p getdebugbin=Collect MinGW debug binaries (y/n):
@IF EXIST "%devroot%\%projectname%\bin\%abi%\*.dll" IF NOT EXIST "%devroot%\%projectname%\lib\%abi%\*.lib" echo.
@if /I "%getdebugbin%"=="y" echo Moving debug binaries to distinct location...
@if /I "%getdebugbin%"=="y" MOVE "%devroot%\%projectname%\bin\%abi%\*.dll" "%devroot%\%projectname%\debug\%abi%\"
@if /I "%getdebugbin%"=="y" IF EXIST "%devroot%\%projectname%\bin\%abi%\*.json" MOVE "%devroot%\%projectname%\bin\%abi%\*.json" "%devroot%\%projectname%\debug\%abi%\"
@if /I "%getdebugbin%"=="y" echo.
@endlocal
