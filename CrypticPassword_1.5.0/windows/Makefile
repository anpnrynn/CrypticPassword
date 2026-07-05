# NMake Makefile for Visual Studio Developer Command Prompt
# Usage: nmake /f Makefile [CONFIG=Release]

CONFIG = Release
OUTDIR = build\$(CONFIG)
CC = cl
RC = rc
CFLAGS = /nologo /W4 /DUNICODE /D_UNICODE /I..\common /Isrc
LDFLAGS = /nologo /SUBSYSTEM:WINDOWS /MANIFEST:EMBED /MANIFESTINPUT:src\app.manifest comctl32.lib user32.lib gdi32.lib shell32.lib

!IF "$(CONFIG)" == "Debug"
CFLAGS = $(CFLAGS) /Od /Zi /MDd /D_DEBUG
!ELSE
CFLAGS = $(CFLAGS) /O2 /MD /DNDEBUG
!ENDIF

all: $(OUTDIR) $(OUTDIR)\CrypticPassword.exe

$(OUTDIR):
	@if not exist $(OUTDIR) mkdir $(OUTDIR)

$(OUTDIR)\app.res: src\app.rc src\resource.h src\app.manifest
	$(RC) /fo$(OUTDIR)\app.res src\app.rc

$(OUTDIR)\crypticpassword_core.obj: ..\common\crypticpassword_core.c ..\common\crypticpassword_core.h
	$(CC) $(CFLAGS) /Fo$(OUTDIR)\crypticpassword_core.obj /c ..\common\crypticpassword_core.c

$(OUTDIR)\main_win32.obj: src\main_win32.c src\resource.h ..\common\crypticpassword_core.h
	$(CC) $(CFLAGS) /Fo$(OUTDIR)\main_win32.obj /c src\main_win32.c

$(OUTDIR)\CrypticPassword.exe: $(OUTDIR)\main_win32.obj $(OUTDIR)\crypticpassword_core.obj $(OUTDIR)\app.res
	link $(LDFLAGS) /OUT:$(OUTDIR)\CrypticPassword.exe $(OUTDIR)\main_win32.obj $(OUTDIR)\crypticpassword_core.obj $(OUTDIR)\app.res

clean:
	@if exist build rmdir /S /Q build
