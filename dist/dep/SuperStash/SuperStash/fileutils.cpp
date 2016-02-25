#include <shlobj.h>
#include "fileutils.h"

std::string GetSSDirectory()
{
	char path[MAX_PATH];
	if (!SUCCEEDED(SHGetFolderPath(NULL, CSIDL_MYDOCUMENTS | CSIDL_FLAG_CREATE, NULL, SHGFP_TYPE_CURRENT, path)))
	{
		return std::string();
	}
	strcat_s(path, sizeof(path), "\\My Games\\Skyrim\\SuperStash\\");
	return path;
}

bool isReadable(const std::string& name) {
	FILE *file;

	if (fopen_s(&file, name.c_str(), "r") == 0) {
		fclose(file);
		return true;
	}
	else {
		return false;
	}
}

bool isInSSDir(LPCSTR lpFileName)
{
	char ssPath[MAX_PATH];
	sprintf_s(ssPath, "%s", GetSSDirectory().c_str());

	char testPath[MAX_PATH];
	sprintf_s(testPath, "%s", lpFileName);

	char ssDrive[_MAX_DRIVE];
	char ssDir[_MAX_DIR];
	char drive[_MAX_DRIVE];
	char dir[_MAX_DIR];
	char fname[_MAX_FNAME];
	char ext[_MAX_EXT];
	errno_t err;

	err = _splitpath_s(ssPath, ssDrive, _MAX_DRIVE, ssDir, _MAX_DIR, fname, _MAX_FNAME, ext, _MAX_EXT);
	if (err != 0)
	{
		_ERROR("%s - error splitting path %s (Error %d)", __FUNCTION__, testPath, err);
		return false;
	}

	err = _splitpath_s(testPath, drive, _MAX_DRIVE, dir, _MAX_DIR, fname, _MAX_FNAME, ext, _MAX_EXT);
	if (err != 0)
	{
		_ERROR("%s - error splitting path %s (Error %d)", __FUNCTION__, testPath, err);
		return false;
	}

	if (_strcmpi(ssDir, dir))
	{
		return true;
	}

	return false;
}

UInt32 SSCopyFile(LPCSTR lpExistingFileName, LPCSTR lpNewFileName)
{
	UInt32 ret = 0;
	if (!isReadable(lpExistingFileName))
	{
		return ERROR_FILE_NOT_FOUND;
	}
	IFileStream::MakeAllDirs(lpNewFileName);
	if (!CopyFile(lpExistingFileName, lpNewFileName, false)) {
		UInt32 lastError = GetLastError();
		ret = lastError;
		switch (lastError) {
		case ERROR_FILE_NOT_FOUND: // We don't need to display a message for this
			break;
		default:
			_ERROR("%s - error copying file %s (Error %d)", __FUNCTION__, lpExistingFileName, lastError);
			break;
		}
	}
	return ret;
}

UInt32 SSMoveFile(LPCSTR lpExistingFileName, LPCSTR lpNewFileName)
{
	UInt32 ret = 0;
	if (!isReadable(lpExistingFileName))
	{
		return ERROR_FILE_NOT_FOUND;
	}
	IFileStream::MakeAllDirs(lpNewFileName);
	if (!MoveFile(lpExistingFileName, lpNewFileName)) {
		UInt32 lastError = GetLastError();
		ret = lastError;
		switch (lastError) {
		case ERROR_FILE_NOT_FOUND: // We don't need to display a message for this
			break;
		default:
			_ERROR("%s - error moving file %s (Error %d)", __FUNCTION__, lpExistingFileName, lastError);
			break;
		}
	}
	return ret;
}

UInt32 SSDeleteFile(LPCSTR lpExistingFileName)
{
	UInt32 ret = 0;
	if (!isReadable(lpExistingFileName))
	{
		return ERROR_FILE_NOT_FOUND;
	}
	if (!DeleteFile(lpExistingFileName)) {
		UInt32 lastError = GetLastError();
		ret = lastError;
		_ERROR("%s - error deleting file %s (Error %d)", __FUNCTION__, lpExistingFileName, lastError);
	}
	return ret;
}

SInt32 ssRotateFile(const std::string& filename, SInt32 maxCount)
{
	SInt32 ret = 0;

	if (maxCount < 1)
		return ret;

	char sourcePath[MAX_PATH];
	sprintf_s(sourcePath, "%s", filename.data());

	char drive[_MAX_DRIVE];
	char dir[_MAX_DIR];
	char fname[_MAX_FNAME];
	char ext[_MAX_EXT];
	errno_t err;

	err = _splitpath_s(sourcePath, drive, _MAX_DRIVE, dir, _MAX_DIR, fname, _MAX_FNAME, ext, _MAX_EXT);
	if (err != 0)
	{
		_ERROR("%s - error splitting path %s (Error %d)", __FUNCTION__, sourcePath, err);
		return err;
	}

	char prevPath[MAX_PATH];
	char targetPath[MAX_PATH];
	char prevFilename[_MAX_FNAME];
	char targetFilename[_MAX_FNAME];

	//delete file.maxCount
	sprintf_s(targetFilename, "%s.%d", fname, maxCount);
	_makepath_s(targetPath, _MAX_PATH, drive, dir, targetFilename, ext);
	err = SSDeleteFile(targetPath);
	if (err && err != ERROR_FILE_NOT_FOUND)
	{
		_ERROR("%s - error deleting file %s (Error %d)", __FUNCTION__, targetFilename, err);
		return err;
	}

	//do file rotation
	for (int i = maxCount - 1; i >= 0; i--) {
		sprintf_s(targetFilename, "%s.%d", fname, i + 1);
		sprintf_s(prevFilename, "%s.%d", fname, i);
		_makepath_s(targetPath, _MAX_PATH, drive, dir, targetFilename, ext);
		_makepath_s(prevPath, _MAX_PATH, drive, dir, prevFilename, ext);
		//_DMESSAGE("Moving %s to %s", prevPath, targetPath);
		SSMoveFile(prevPath, targetPath);
	}

	//move file.x to file.1.x
	sprintf_s(targetFilename, "%s.%d", fname, 1);
	_makepath_s(targetPath, _MAX_PATH, drive, dir, targetFilename, ext);
	SSMoveFile(sourcePath, targetPath);

	return ret;
}
