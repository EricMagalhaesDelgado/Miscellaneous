#define _CRT_SECURE_NO_WARNINGS

#include <cstdio>
#include <iostream>
#include <format>
#include <fstream>
#include <string>
#include <process.h>
#include "CellPlan_dBmFile.h"

using namespace std;

int main(int argc, char* argv[]) {
	if ((argc == 2) || (argc == 3)) {
		if (!isfile(argv[1])) {
			cout << "ERROR: unreadable file";
			return -1;
		}

		try {
			if (IQ_dBm_FileReader::Load_Library()) {
				string InputFile = argv[1];
				string OutputFile;
					
				if (argc == 2) {
					SYSTEMTIME st;
					GetSystemTime(&st);
					OutputFile = format("~{:4}{:02}{:02}_T{:02}{:02}{:02}_CellSpec.bin", st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
				}
				else {
					OutputFile = argv[2];
				}

				read_CellWireless_dBm_File(InputFile.c_str(), OutputFile.c_str());
				IQ_dBm_FileReader::Unload_Library();
			}
			else {
				cout << "ERROR: IQ_dBm_FileReader::Load_Library()";
				return -1;
			}
		}
		catch (const exception& ex) {
			cerr << "ERROR: " << ex.what() << endl;
			return -1;
		}
	}
	else {
		cout << "ERROR: Syntax CellPlan_dBReader.exe 'InputFileName' 'OutputFileName'";
		return -1;
	}

	return 0;
}

bool isfile(const char* filename) {
	FILE* file;
	
	if ((file = fopen(filename, "r"))) {
		fclose(file);
		return true;
	}
	return false;
}

void read_CellWireless_dBm_File(const char* InputFile, const char* OutputFile) {
	string fname = InputFile;
	int nBlocks;

	if (IQ_dBm_FileReader::OpenFile((char*)fname.c_str(), &nBlocks)) {
		FILE* pTempFile = FileCreation(OutputFile);
		
		CapturedRawBuffer Buffer;
		fvec dBm_buf;
		int BlockNumber;

		while (IQ_dBm_FileReader::MoreBlocksAvailable()) {
			if (IQ_dBm_FileReader::dBm_FR_NextBlock(&Buffer, &dBm_buf, &BlockNumber)) {
				FileMetadata(pTempFile, nBlocks, Buffer, dBm_buf.size(), BlockNumber);
				FileBody(pTempFile, Buffer, dBm_buf);
			}
		}
		fclose(pTempFile);
	}
	else {
		throw invalid_argument("read_CellWireless_dBm_File");
	}
}

FILE* FileCreation(const char* OutputFile) {
	FILE* pTempFile;
	pTempFile = fopen(OutputFile, "wb");

	return pTempFile;
}

void FileMetadata(FILE* pTempFile, int nBlocks, CapturedRawBuffer Buffer, int DataPoints, int BlockNumber) {
	string startBlock = "StArT";	
	fwrite(startBlock.c_str(),              1, 5, pTempFile);

	fwrite(&nBlocks,                        4, 1, pTempFile); // int32
	fwrite(&DataPoints,						4, 1, pTempFile); // int32
	fwrite(&Buffer.ext_NoiseLevelOffset,    8, 1, pTempFile); // float64 (double)
	fwrite(&Buffer.ext_freq,				8, 1, pTempFile);
	fwrite(&Buffer.ext_ReducedFreqSpan_MHz, 8, 1, pTempFile);
	fwrite(&Buffer.ext_FullFreqSpan_MHz,	8, 1, pTempFile);
	fwrite(&Buffer.ext_ResBw_kHz,			8, 1, pTempFile);
	fwrite(&Buffer.ext_Decimation,			4, 1, pTempFile);
	fwrite(&Buffer.ext_SamplesPerPacket,	4, 1, pTempFile);
	fwrite(&Buffer.ext_PacketsPerBlock,		4, 1, pTempFile);
	fwrite(&Buffer.ext_ppm,					8, 1, pTempFile);
	fwrite(&Buffer.ext_NominalGain,			4, 1, pTempFile);
	fwrite(&Buffer.RecordSize,				4, 1, pTempFile);
	fwrite(&Buffer.Buffer_nElems,			4, 1, pTempFile);
}

void FileBody(FILE* pTempFile, CapturedRawBuffer Buffer, fvec dBm_buf) {
	/*
	           8 bytes: timestamp
	DataPoints*4 bytes: array of float32 
	*/

	UINT8  wYear   = Buffer.system_timeStamp.wYear - 2000;
	UINT8  wMonth  = Buffer.system_timeStamp.wMonth;
	UINT8  wDay    = Buffer.system_timeStamp.wDay;
	UINT8  wHour   = Buffer.system_timeStamp.wHour;
	UINT8  wMinute = Buffer.system_timeStamp.wMinute;
	UINT8  wSecond = Buffer.system_timeStamp.wSecond;
	UINT16 wMilli  = Buffer.system_timeStamp.wMilliseconds;

	fwrite(&wYear,   1, 1, pTempFile);
	fwrite(&wMonth,  1, 1, pTempFile);
	fwrite(&wDay,    1, 1, pTempFile);
	fwrite(&wHour,   1, 1, pTempFile);
	fwrite(&wMinute, 1, 1, pTempFile);
	fwrite(&wSecond, 1, 1, pTempFile);
	fwrite(&wMilli,  2, 1, pTempFile);

	fwrite(&Buffer.latitude,  8, 1, pTempFile); // float64 (double)
	fwrite(&Buffer.longitude, 8, 1, pTempFile);

	for (int ii = 0; ii < dBm_buf.size(); ii++)
		fwrite(&dBm_buf(ii), 4, 1, pTempFile);

	string stopBlock = "StOp";
	fwrite(stopBlock.c_str(), 1, 4, pTempFile);
}