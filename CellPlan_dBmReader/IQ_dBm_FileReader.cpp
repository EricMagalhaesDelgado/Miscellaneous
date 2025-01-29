#include "pch.h"
#include "IQ_dBm_FileReader.h"
#include <stdio.h>

namespace IQ_dBm_FileReader {
	typedef void(__cdecl* T_DLL_DefineExternalLogMsg)(char* msg);

	//DLL interface	
	typedef bool(__cdecl* FR_OpenFile)(char* fname, int* nBlocks);
	typedef void(__cdecl* FR_CloseFile)(void);
	typedef bool(__cdecl* FR_NextBlock)(HGLOBAL* NextBlock, HGLOBAL* NextSpecData, int* Spec_nElems, int* BlockNumber);
	typedef void(__cdecl* FR_DefineExternalLogMsg)(T_DLL_DefineExternalLogMsg External_Function);
	typedef bool(__cdecl* FR_MoreBlocksAvailable)(void);
	typedef bool(__cdecl* FR_SetNextBlockNumber)(int BlockNumber);
	typedef bool(__cdecl* FR_SetTotalBlocksToRead)(int TotalBlocks);
	typedef int(__cdecl* FR_Get_DLL_Version)(void);

	static FR_OpenFile DLL_OpenFile = NULL;
	static FR_CloseFile DLL_CloseFile = NULL;
	static FR_NextBlock DLL_NextBlock = NULL;
	static FR_DefineExternalLogMsg DLL_DefineExternalLogMsg = NULL;
	static FR_MoreBlocksAvailable DLL_MoreBlocksAvailable = NULL;
	static FR_SetNextBlockNumber DLL_SetNextBlockNumber = NULL;
	static FR_SetTotalBlocksToRead DLL_SetTotalBlocksToRead = NULL;
	static FR_Get_DLL_Version DLL_Get_DLL_Version = NULL;

	static HMODULE Handle = NULL;

	// Optional function to display messages from the DLL
	void Log_DLL_Msg(char *msg)
	{
		string strg = msg;
		std::cout << "--> from DLL:" + strg + "\n";
	}

	// Optional function to display messages from the DLL
	void DefineExternalLogMsg(void) {
	  if (DLL_DefineExternalLogMsg != NULL)
	    DLL_DefineExternalLogMsg(Log_DLL_Msg);
	}

	bool Load_Library() {
		if (Handle == NULL) {
			Handle = LoadLibrary("IQ_dBm_FileReader.dll");
			if (Handle == NULL) {
				MessageBox(NULL, "IQ_dBm_FileReader.DLL --> Loading library failed", "Load IQ/dBm File Reader failed", MB_OK | MB_ICONERROR);
				return false;
			}
			else {
				DLL_OpenFile = (FR_OpenFile)GetProcAddress(Handle, "IQ_dBm_OpenFile");
				DLL_CloseFile = (FR_CloseFile)GetProcAddress(Handle, "IQ_dBm_CloseFile");
				DLL_NextBlock = (FR_NextBlock)GetProcAddress(Handle, "IQ_dBm_NextBlock");
				DLL_DefineExternalLogMsg = (FR_DefineExternalLogMsg)GetProcAddress(Handle, "IQ_dBm_DefineExternalLogMsg");
				DLL_MoreBlocksAvailable = (FR_MoreBlocksAvailable)GetProcAddress(Handle, "IQ_dBm_MoreBlocksAvailable");
				DLL_SetNextBlockNumber = (FR_SetNextBlockNumber)GetProcAddress(Handle, "IQ_dBm_SetNextBlockNumber");
				DLL_SetTotalBlocksToRead = (FR_SetTotalBlocksToRead)GetProcAddress(Handle, "IQ_dBm_SetTotalBlocksToRead");
				DLL_Get_DLL_Version = (FR_Get_DLL_Version)GetProcAddress(Handle, "IQ_dBm_Get_DLL_Version");

				if ((DLL_OpenFile == NULL) || (DLL_CloseFile == NULL) || (DLL_NextBlock == NULL) || (DLL_DefineExternalLogMsg == NULL) ||
					(DLL_MoreBlocksAvailable == NULL) || (DLL_SetNextBlockNumber == NULL) || (DLL_SetTotalBlocksToRead == NULL) || (DLL_Get_DLL_Version == NULL)) {
					Unload_Library();
					MessageBox(NULL, "IQ_dBm_FileReader.DLL --> Library functions not found", "Load IQ/dBm File Reader failed", MB_OK | MB_ICONERROR);
					return false;
				}
				DefineExternalLogMsg(); // optional function to display messages from the DLL

				int DLL_Version = Get_DLL_Version();
				if (DLL_Version != IQ_dBm_FR_LATEST_DLL_VERSION) {
					Unload_Library();
					string strg = "IQ_dBm_FileReader.DLL --> invalid DLL version\n\nExpected version = " + to_string(IQ_dBm_FR_LATEST_DLL_VERSION) + "\nVersion found = " + to_string(DLL_Version) + "\n";
					MessageBox(NULL, strg.c_str(),"Load IQ/dBm File Reader failed", MB_OK | MB_ICONERROR);
					return false;
				}
			}
		}
		return true;
	} // Load_DLL_FileReader

	void Unload_Library() {
		DLL_OpenFile = NULL;
		DLL_CloseFile = NULL;
		DLL_NextBlock = NULL;
		DLL_DefineExternalLogMsg = NULL;
		DLL_MoreBlocksAvailable = NULL;
		DLL_SetNextBlockNumber = NULL;
		DLL_SetTotalBlocksToRead = NULL;
		DLL_Get_DLL_Version = NULL;
		if (Handle != NULL) {
			FreeLibrary(Handle);
			Handle = NULL;
		}
	} // Unload_Library

	bool OpenFile(char* fname, int* nBlocks) {
		if (DLL_OpenFile != NULL)
			return DLL_OpenFile(fname, nBlocks);
		else
			return false;
	}

	void CloseFile(void) {
		if (DLL_CloseFile != NULL)
			DLL_CloseFile();
	}

	bool dBm_FR_NextBlock(CapturedRawBuffer* DLL_Buffer, fvec* capbuf_raw, int* BlockNumber) {
		if ((DLL_NextBlock != NULL) && (DLL_Buffer != NULL)) {
			HGLOBAL NextBlock, NextSpecData;
			int Spec_nElems;
			if (DLL_NextBlock(&NextBlock, &NextSpecData, &Spec_nElems, BlockNumber)) {
				if (NextBlock != 0) {
					CapturedRawBuffer* DLL_BufferPtr = (CapturedRawBuffer*)GlobalLock(NextBlock);
					if (DLL_BufferPtr != NULL) {
						memcpy(DLL_Buffer, DLL_BufferPtr, sizeof(CapturedRawBuffer));
						if (GlobalUnlock(NextBlock) == 0)
							GlobalFree(NextBlock);

						float* SpecBufferPtr = (float*)GlobalLock(NextSpecData);
						if (SpecBufferPtr != NULL) {
							(*capbuf_raw).set_size(Spec_nElems);
							for (int32_t t = 0; t < Spec_nElems;t++)
								(*capbuf_raw)(t) = SpecBufferPtr[t];
							if (GlobalUnlock(NextSpecData) == 0)
								GlobalFree(NextSpecData);
							return true;
						}
					}
				}
			}
		}
		return false;
	}

	bool IQ_FR_NextBlock(CapturedRawBuffer* IQ_Buffer, cx_vec* capbuf_raw, int* BlockNumber) {
		if ((DLL_NextBlock != NULL) && (IQ_Buffer != NULL)) {
			HGLOBAL NextBlock, NextSpecData;
			int Spec_nElems;
			if (DLL_NextBlock(&NextBlock, &NextSpecData, &Spec_nElems, BlockNumber)) {
				if (NextBlock != 0) {
					CapturedRawBuffer* IQ_BufferPtr = (CapturedRawBuffer*)GlobalLock(NextBlock);
					if (IQ_BufferPtr != NULL) {
						memcpy(IQ_Buffer, IQ_BufferPtr, sizeof(CapturedRawBuffer));

						(*capbuf_raw).set_size((*IQ_BufferPtr).Buffer_nElems);
						int32_t len = (*IQ_BufferPtr).Buffer_nElems;
						for (int32_t t = 0; t < len;t++) {
							((*capbuf_raw)(t)).real((*IQ_BufferPtr).Buffer[t].IQ_Elem.real);
							((*capbuf_raw)(t)).imag((*IQ_BufferPtr).Buffer[t].IQ_Elem.imag);
						}

						if (GlobalUnlock(NextBlock) == 0)
							GlobalFree(NextBlock);

						return true;
					}
				}
			}
		}
		return false;
	}

	bool MoreBlocksAvailable(void) {
		if (DLL_MoreBlocksAvailable != NULL)
			return DLL_MoreBlocksAvailable();
		else
			return false;
	}

	bool SetNextBlockNumber(int BlockNumber) {
		if (DLL_SetNextBlockNumber != NULL)
			return DLL_SetNextBlockNumber(BlockNumber);
		else
			return false;
	}

	bool SetTotalBlocksToRead(int TotalBlocks) {
		if (DLL_SetTotalBlocksToRead != NULL)
			return DLL_SetTotalBlocksToRead(TotalBlocks);
		else
			return false;
	}

	int Get_DLL_Version(void) {
		if (DLL_Get_DLL_Version != NULL)
			return DLL_Get_DLL_Version();
		else
			return -1;
	}
}