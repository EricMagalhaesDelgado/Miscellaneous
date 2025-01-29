#pragma once

#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers

#include <Windows.h>
#include <stdlib.h> 
#include <iostream>
#include <fstream>
#include <string>
#include "armadillo"

using namespace std;
using namespace arma;

#define IQ_file_ext	"IQ"
#define dBm_file_ext "DBM"

#define IQ_dBm_FR_LATEST_DLL_VERSION 1001 // 1.0-01

enum CellScannerTechnology { 
	CST_LTE  = 0, 
	CST_UMTS = 1, 
	CST_GSM  = 2, 
	CST_5GNR = 3
};

enum CellScannerDuplexingMode { 
	DM_FDD = 0, 
	DM_TDD = 1, 
	DM_NotApplicable = 2
};

struct int16_IQ {
	int16_t real;
	int16_t imag;
};

struct Compressed_dBm_2bytes {
	int16_t dBm1;
	int16_t dBm2;
};

struct Compressed_dBm_1byte {
	int8_t dBm[4];
};

union RawBufferElemType {	 
	int16_IQ IQ_Elem;                        // first representation (member of union)
	float dBm_Elem;                          // second representation (member of union) 
	Compressed_dBm_2bytes Compressed_2bytes; // third representation (member of union) 
	Compressed_dBm_1byte Compressed_1byte;   // fourth representation (member of union) 
};

struct wsa_packet_time {
	uint32_t sec;
	uint64_t psec;
};

typedef struct CapturedRawBuffer
{
	double latitude;
	double longitude;
	double altitude; 
	SYSTEMTIME system_timeStamp;
	wsa_packet_time packet_timeStamp;
	double ext_NoiseLevelOffset;
	CellScannerTechnology ext_Tech; 
	int ext_Band, ext_Channel; 
	double ext_freq;
	double ext_ReducedFreqSpan_MHz;
	double ext_FullFreqSpan_MHz; 
	double ext_ResBw_kHz; 
	int ext_Decimation; 
	int ext_SamplesPerPacket; 
	int ext_PacketsPerBlock; 
	double ext_ppm;
	int ext_NominalGain;
	int RecordSize;
	int Buffer_nElems;
	int ext_SCS_kHz;
	CellScannerDuplexingMode DuplexMode;
	RawBufferElemType Buffer[];
};

namespace IQ_dBm_FileReader {
	extern bool Load_Library(); // load IQ/dBm File Reader DLL
	extern void Unload_Library(); // unload IQ/dBm File Reader DLL

	extern bool OpenFile(char* fname, int* nBlocks); // open a IQ or dBm data file
	extern void CloseFile(void); // close last opened file

	extern bool dBm_FR_NextBlock(CapturedRawBuffer* dBm_Buffer, fvec* capbuf_raw, int* BlockNumber); // get the next data block from a dBm file
	extern bool IQ_FR_NextBlock(CapturedRawBuffer* IQ_Buffer, cx_vec* capbuf_raw, int* BlockNumber); // get the next data block from a IQ file
	extern bool MoreBlocksAvailable(void); // check if there are more blocks available from the file

	extern bool SetNextBlockNumber(int BlockNumber); // optional function to define a specific block number to be read by "NextBlock" function
	extern bool SetTotalBlocksToRead(int TotalBlocks); // optional function to define total blocks available to be checked by "MoreBlocksAvailable" function

	extern int Get_DLL_Version(void); // provide the DLL version (e.g. 1001 --> version 1.0-01)
}