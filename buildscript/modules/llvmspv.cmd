@setlocal

@rem Updating SPIRV LLVM translator source code
@IF EXIST "%devroot%\SPIRV-LLVM-Translator\" IF %gitstate% GTR 0 (
@cd "%devroot%\SPIRV-LLVM-Translator"
@echo Updating SPIRV LLVM translator...
@git pull --progress --tags --recurse-submodules origin
@FOR /F tokens^=^1^,2^ eol^= %%a IN ('type "%llvminstloc%\%abi%\lib\cmake\llvm\LLVMConfig.cmake"') DO @IF "%%a"=="set(LLVM_PACKAGE_VERSION" FOR /F tokens^=^1^,2^ delims^=^.^ eol^= %%c IN ("%%b") DO @git checkout llvm_release_%%c%%d
@git pull --progress --tags --recurse-submodules origin
@echo.
)
@IF EXIST "%devroot%\SPIRV-LLVM-Translator\spirv-headers-tag.conf" IF EXIST "%devroot%\SPIRV-Headers\" IF %gitstate% GTR 0 for /f delims^=^ eol^= %%a IN ('type "%devroot%\SPIRV-LLVM-Translator\spirv-headers-tag.conf"') do @for /f delims^=^ eol^= %%b IN ('type "%devroot%\SPIRV-Headers\.git\HEAD"') do @IF NOT %%a==%%b (
@echo Updating SPIRV headers used by SPIRV LLVM translator...
@cd "%devroot%\SPIRV-Headers"
@for /f tokens^=2^ delims^=/^ eol^= %%c in ('git symbolic-ref --short refs/remotes/origin/HEAD 2^>^&^1') do @git checkout %%c
@git pull --progress --tags --recurse-submodules origin
@git checkout %%a
@echo.
)

@set canllvmspirv=1
@if NOT EXIST "%devroot%\llvm-project\" set canllvmspirv=0
@IF %cmakestate%==0 set canllvmspirv=0
@IF NOT EXIST "%devroot%\SPIRV-LLVM-Translator\" IF %gitstate% EQU 0 set canllvmspirv=0
@IF EXIST "%devroot%\SPIRV-LLVM-Translator\spirv-headers-tag.conf" IF NOT EXIST "%devroot%\SPIRV-Headers\" IF %gitstate% EQU 0 set canllvmspirv=0
@IF %canllvmspirv% EQU 1 set /p buildllvmspirv=Build SPIRV LLVM Translator - required for OpenCL (y/n):
@IF %canllvmspirv% EQU 1 echo.
@if /I NOT "%buildllvmspirv%"=="y" GOTO skipspvllvm

@IF NOT EXIST "%devroot%\SPIRV-LLVM-Translator\" (
@echo Getting SPIRV LLVM translator source code...
@FOR /F tokens^=^1^,2^ eol^= %%a IN ('type "%llvminstloc%\%abi%\lib\cmake\llvm\LLVMConfig.cmake"') DO @IF "%%a"=="set(LLVM_PACKAGE_VERSION" FOR /F tokens^=^1^,2^ delims^=^.^ eol^= %%c IN ("%%b") DO @git clone -b llvm_release_%%c%%d https://github.com/KhronosGroup/SPIRV-LLVM-Translator "%devroot%\SPIRV-LLVM-Translator"
@echo.
)
@IF EXIST "%devroot%\SPIRV-LLVM-Translator\spirv-headers-tag.conf" IF NOT EXIST "%devroot%\SPIRV-Headers\" (
@echo Getting source code of SPIRV headers used by SPIRV LLVM translator...
@git clone https://github.com/KhronosGroup/SPIRV-Headers "%devroot%\SPIRV-Headers"
@cd "%devroot%\SPIRV-Headers"
@for /f delims^=^ eol^= %%a IN ('type "%devroot%\SPIRV-LLVM-Translator\spirv-headers-tag.conf"') do @git checkout %%a
@echo.
)

@rem SPIRV Tools integration for SPIRV LLVM translator. This is a feature introduced in SPIRV LLVM translator 14.x.
@rem However it fails to link SPIRV Tools for some reason.
@rem IF %canllvmspirv% EQU 1 IF EXIST "%devroot%\spirv-tools\build\%abi%\" IF %pkgconfigstate% GTR 0 set /p integratespvtools=Build with SPIRV Tools integration (y/n):
@rem IF %canllvmspirv% EQU 1 IF EXIST "%devroot%\spirv-tools\build\%abi%\" IF %pkgconfigstate% GTR 0 echo.
@IF /I "%integratespvtools%"=="y" set PATH=%pkgconfigloc%\;%PATH%
@IF /I "%integratespvtools%"=="y" set PKG_CONFIG_PATH=%devroot:\=/%/spirv-tools/build/%abi%/lib/pkgconfig
@IF /I NOT "%integratespvtools%"=="y" set PKG_CONFIG_PATH=

@set buildconf=%buildconf% -DLLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR="%devroot%\SPIRV-Headers" -DCMAKE_INSTALL_PREFIX="%llvminstloc%\spv-%abi%" -DCMAKE_PREFIX_PATH="%llvminstloc%\%abi%" -DLLVM_SPIRV_INCLUDE_TESTS=OFF "%devroot%\SPIRV-LLVM-Translator"
@echo SPIRV LLVM translator build configuration command^: %buildconf%
@echo.
@pause
@echo.
@echo Cleanning SPIRV LLVM translator build. Please wait...
@echo.
@if EXIST "%llvminstloc%\spv-%abi%\" RD /S /Q "%llvminstloc%\spv-%abi%"
@if EXIST "%devroot%\llvm-project\build\bldspv-%abi%\" RD /S /Q "%devroot%\llvm-project\build\bldspv-%abi%"
@pause
@echo.
@if NOT EXIST "%devroot%\llvm-project\build\" MD "%devroot%\llvm-project\build"
@cd "%devroot%\llvm-project\build"
@if NOT EXIST "bldspv-%abi%\" md bldspv-%abi%
@cd bldspv-%abi%

@rem Load Visual Studio environment. Can only be loaded in the background when using MsBuild.
@if /I "%useninja%"=="y" call %vsenv% %vsabi%
@if /I "%useninja%"=="y" cd "%devroot%\llvm-project\build\bldspv-%abi%"
@if /I "%useninja%"=="y" echo.

@rem Configure and execute the build with the configuration made above.
@%buildconf%
@echo.
@pause
@echo.
@if /I NOT "%useninja%"=="y" cmake --build . -j %throttle% --config Release --target install
@if /I "%useninja%"=="y" ninja -j %throttle% install
@echo.

:skipspvllvm
@rem Reset environment after SPIRV LLVM translator build.
@endlocal
@cd "%devroot%"