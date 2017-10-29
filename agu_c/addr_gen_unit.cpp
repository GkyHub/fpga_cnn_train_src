#include "addr_gen_unit.hpp"
#include <iostream>

#define CEIL_DIV_2(X) ((X) / 2 + ((X) % 2))

AddrGenUnit::AddrGenUnit(ap_uint<4> group_id_x, ap_uint<4> group_id_y)
{
	_grp_id_x = group_id_x;
	_grp_id_y = group_id_y;
}

void AddrGenUnit::Config(agu_mode_t mode, cnt_t idx_cnt, cnt_t trip_cnt, bool is_new)
{
	_idx_cnt 	= idx_cnt;
	_trip_cnt 	= trip_cnt;
	_mode		= mode;
	_is_new		= is_new;
	return;
}

void AddrGenUnit::PadConfig(ap_uint<4> pad_code, bool cut_y)
{
	_pad_u = pad_code.get_bit(0);
	_lim_d = (pad_code.get_bit(1) ? (pad_code.get_bit(0) ? 1 : 2) : (pad_code.get_bit(0) ? 2 : 3)) - cut_y;
	_pad_l = pad_code.get_bit(2);
	_lim_r = pad_code.get_bit(3) ?
			(pad_code.get_bit(2) ? ap_int<6>(_trip_cnt - 1) : ap_int<6>(_trip_cnt)) :
			(pad_code.get_bit(2) ? ap_int<6>(_trip_cnt) : ap_int<6>(_trip_cnt + 1));
	return;
}

void AddrGenUnit::Run(idx2d_t idx_buf[IDX_MAX_NUM],
			hls::stream<rd_a_info_t> &rd_a,
			hls::stream<rd_b_info_t> &rd_b,
			hls::stream<wr_c_info_t> &wr_c)
{

	switch(_mode)
	{
	case MODE_FC: {
		// merged with fc_u mode to reduce resource consumption
	}
	case MODE_FC_U: {
		_RunFc(idx_buf, rd_a, rd_b, wr_c);
		break;
	}
	case MODE_CONV: {
		_RunConv(idx_buf, rd_a, rd_b, wr_c);
	}
	default:{

	}
	}
	return;
}

void AddrGenUnit::_RunFc(idx2d_t idx_buf[IDX_MAX_NUM],
			hls::stream<rd_a_info_t> &rd_a,
			hls::stream<rd_b_info_t> &rd_b,
			hls::stream<wr_c_info_t> &wr_c)
{
	idx2d_t idx2d;
	ap_uint<4> idx_x, idx_y;
	rd_a_info_t rd_a_info;
	rd_b_info_t rd_b_info;
	wr_c_info_t wr_c_info;

	// rd_a_addr._mux = 0;

	for (cnt_t i = 0; i <= _idx_cnt; i++) {
		idx2d = idx_buf[i];
		idx_x = idx2d & 0x0f;
		idx_y = idx2d >> 4;
		// read port a
		rd_a_info = ConcatInfoA(addr_t(idx_x), true, 0);
		// read port b
		if (_mode == MODE_FC) {
			rd_b_info = ConcatInfoB(i / 32, (1 << (i % 32)));
		}
		else {
			rd_b_info = ConcatInfoB(addr_t(idx_y), 0xffffffff);
		}
		// write port c
		if (_mode == MODE_FC) {
			wr_c_info = ConcatInfoC(addr_t(idx_y), 0xffffffff, _is_new);
		}
		else {
			wr_c_info = ConcatInfoC(i / 32, (1 << (i % 32)), false);
		}

		// send to stream
		rd_a << rd_a_info;
		rd_b << rd_b_info;
		wr_c << wr_c_info;
	}
	return;
}

void AddrGenUnit::_RunConv(idx2d_t idx_buf[IDX_MAX_NUM],
			hls::stream<rd_a_info_t> &rd_a,
			hls::stream<rd_b_info_t> &rd_b,
			hls::stream<wr_c_info_t> &wr_c)
{
	idx2d_t idx2d;
	ap_uint<4> idx_x, idx_y;

    ap_uint<16> ker_cnt = 0;
    addr_t addr_a;
    bool pad_mask;
    ap_uint<2> mux;
    rd_a_info_t rd_a_info;
    rd_b_info_t rd_b_info;
    wr_c_info_t wr_c_info;

    // the core idea is to maintain the position of the window
    // and the position of this PE
    ap_int<6> win_x, win_y;
    ap_int<6> pe_x, pe_y;

    ap_int<6> row_cnt = CEIL_DIV_2(_trip_cnt);

    IDX_LOOP: for (cnt_t i = 0; i < _idx_cnt; i++) {
    	idx2d = idx_buf[i];
    	idx_x = idx2d & 0x0f;
    	idx_y = idx2d >> 4;

    	PIX_LOOP: for (ap_int<6> j = 0; j < row_cnt; j++) {
    	    KER_Y_LOOP: for (ap_uint<4> ky = 0; ky < 3; ky++) {

    	    	// y axis window and pe position
    	    	win_y = ky - (_pad_u ? 1 : 0);
    	    	pe_y = (win_y % 2) ? ap_int<6>(win_y + 1 - _grp_id_y) : ap_int<6>(win_y + _grp_id_y);

    	        KER_X_LOOP: for (ap_uint<4> kx = 0; kx < 3; kx++) {

    	        	// x axis window and pe position
    	        	win_x = kx - (_pad_l ? 1 : 0) + j * 2;
    	        	pe_x = (win_x % 2) ? ap_int<6>(win_x + 1 - _grp_id_x) : ap_int<6>(win_x + _grp_id_x);

    	        	std::cout << "window: (" << win_x << "," << win_y << ")\t";
    	        	std::cout << "pe: (" << pe_x << "," << pe_y << ")\n";

    	        	// mask by compare pe coordinates with bounds
    	        	if (pe_x >= 0 && pe_x <= _lim_r && pe_y >= 0 && pe_y <= _lim_d) {
    	        	    pad_mask = true;
    	        	}
    	        	else {
    	        	    pad_mask = false;
    	        	}
    	        	// get address by pe coordinates
    	        	addr_a = ((pe_y - _grp_id_y) << 2) + (pe_x - _grp_id_x) / 2 + idx_x << 4;
    	        	// get mux by window coordinates
    	        	mux = (win_x % 2) ? ((win_y % 2) ? 0 : 2) : ((win_y % 2) ? 1 : 3);

    	        	// rd_a_info
    	        	rd_a_info = ConcatInfoA(addr_a, pad_mask, mux);
    	        	rd_a << rd_a_info;

    	        	// rd_b_info
    	        	rd_b_info = ConcatInfoB(ker_cnt / 32, 1 << (ker_cnt % 32));
    	        	rd_b << rd_b_info;

    	        	// state update
    	            ker_cnt = (kx == 2 && ky == 2 && j < (row_cnt - 1)) ? ker_cnt - 8 : ker_cnt + 1;
    	        }
    	    }

    	    // wr_c_info
    	    wr_c_info = ConcatInfoC(((idx_y << 4) + j), 0xffffffff, _is_new);
    	    wr_c << wr_c_info;
    	}
    }


    return;
}
