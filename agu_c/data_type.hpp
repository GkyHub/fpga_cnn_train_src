#ifndef DATA_TYPE_HPP
#define DATA_TYPE_HPP

#include "hls_stream.h"
#include "ap_int.h"
#include <iostream>

const int BATCH 		= 32;
const int IDX_MAX_NUM	= 256;
const int MUX_W			= 2;
const int ADDR_W		= 10;

typedef ap_uint<8>  	idx2d_t;
typedef ap_uint<ADDR_W> addr_t;
typedef ap_uint<8>  	cnt_t;
typedef ap_uint<BATCH> 	mask_t;

// {lo - hi}
// {address, pad_mask, mux}
typedef ap_uint<ADDR_W + 1 + MUX_W> rd_a_info_t;

inline rd_a_info_t ConcatInfoA(addr_t addr, bool mask, ap_uint<2> mux)
{
	rd_a_info_t info = 0;
	info |= addr;
	info |= rd_a_info_t(mask) << ADDR_W;
	info |= rd_a_info_t(mux)  << (ADDR_W + 1);
	return info;
}

// {lo - hi}
// {address, sel_mask}
typedef ap_uint<ADDR_W + BATCH> 	rd_b_info_t;

inline rd_b_info_t ConcatInfoB(addr_t addr, mask_t mask)
{
	rd_b_info_t info = 0;
	info |= addr;
	info |= rd_b_info_t(mask) << ADDR_W;
	return info;
}

// {lo - hi}
// {address, acc_en, acc_new}
typedef ap_uint<ADDR_W + BATCH + 1> wr_c_info_t;

inline wr_c_info_t ConcatInfoC(addr_t addr, mask_t mask, bool acc_new)
{
	wr_c_info_t info;
	info |= addr;
	info |= wr_c_info_t(mask) << ADDR_W;
	info |= wr_c_info_t(acc_new) << (ADDR_W + BATCH);
	return info;
}

/*
typedef struct _rd_a_addr_t {
	addr_t 		_addr;
	bool		_pad_mask;
	// ap_uint<2> 	_mux;
} rd_a_addr_t;

typedef struct _rd_b_addr_t {
	addr_t 	_addr;
	mask_t 	_mask;
} rd_b_addr_t;

typedef struct _wr_c_addr_t {
	addr_t  _addr;
	mask_t  _acc_en;
	bool	_acc_new;
} wr_c_addr_t;
*/
enum agu_mode_t {
	MODE_FC	= 0,	// forward and backward fc
	MODE_CONV,		// forward and backward conv
	MODE_FC_U,		// update fc parameter
	MODE_CONV_U		// update conv parameter
};

#endif
