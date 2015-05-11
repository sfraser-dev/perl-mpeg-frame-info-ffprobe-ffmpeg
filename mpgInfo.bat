@echo off
SET CONTAINER_EXTN=mpg
SET OUTPUT_FILE="zout.txt"
:: Recursively search for media containers, call function ffmpegConvert on each container
if exist %OUTPUT_FILE%. (
    del /Q %OUTPUT_FILE%.
)
for /f "delims=" %%f in ('dir "*.%CONTAINER_EXTN%" /s/b') do @call:ffmpegConvert "%%f"
goto:eof

:: Function to convert media containers using FFMPEG
:ffmpegConvert
echo. >>%OUTPUT_FILE%
echo.MPEGFileFound >>%OUTPUT_FILE%
:: Resolving filenames
SET THE_ORIGINAL_NAME="%~f1"
SET THE_DRIVE_LETTER=%~d1
SET THE_PATH=%~p1
SET THE_FILE=%~n1
SET THE_EXTN=%~x1
SET THE_NEW_NAME="%THE_DRIVE_LETTER%%THE_PATH%%THE_FILE%.ffmpeg.%CONTAINER_EXTN%"
ffprobe -show_format %THE_ORIGINAL_NAME% >>%OUTPUT_FILE% 2>&1
goto:eof
