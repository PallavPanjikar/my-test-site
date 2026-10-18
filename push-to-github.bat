@echo off
title Push to GitHub - my-test-site
echo ===================================================
echo Pushing scroll-poc to github.com/PallavPanjikar/my-test-site
echo ===================================================
set "PATH=%PATH%;C:\Users\Dell\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd"
git push -u origin main
echo.
echo If prompted, complete GitHub authentication in your browser.
pause
