@echo off
set "PATH=C:\Program Files\nodejs\;%PATH%"
set "PATH=C:\Users\shalo\AppData\Roaming\npm;%PATH%"
echo Building Flutter Web...
call flutter build web --release --no-wasm-dry-run
if %errorlevel% neq 0 (
    echo Build failed! Aborting deployment.
    exit /b %errorlevel%
)
echo Deploying to Firebase...
call firebase deploy --only hosting,firestore,storage,functions
