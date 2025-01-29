#pragma once

#include <string>
#include "IQ_dBm_FileReader.h"

bool isfile(const char* filename);
void read_CellWireless_dBm_File(const char* InputFile, const char* OutputFile);

FILE* FileCreation(const char* OutputFile);
void FileMetadata(FILE* pTempFile, int nBlocks, CapturedRawBuffer Buffer, int DataPoints, int BlockNumber);
void FileBody(FILE* pTempFile, CapturedRawBuffer Buffer, fvec dBm_buf);