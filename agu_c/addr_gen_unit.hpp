#ifndef ADDR_GEN_UNIT_HPP
#define ADDR_GEN_UNIT_HPP

#include "data_type.hpp"

class AddrGenUnit {
private:
	cnt_t		_idx_cnt;
	cnt_t 		_trip_cnt;
	agu_mode_t	_mode;
	bool		_is_new;
	ap_uint<4>	_grp_id_x, _grp_id_y;
	
	bool 		_pad_l, _pad_u;
	ap_int<6> 	_lim_d, _lim_r;

public:
	AddrGenUnit(ap_uint<4> group_id_x, ap_uint<4> group_id_y);

	void Config(agu_mode_t mode, cnt_t idx_cnt, cnt_t trip_cnt, bool is_new);

	void PadConfig(ap_uint<4> pad_code, bool cut_y);

	void Run(idx2d_t idx_buf[IDX_MAX_NUM], 
			hls::stream<rd_a_info_t> &rd_a,
			hls::stream<rd_b_info_t> &rd_b,
			hls::stream<wr_c_info_t> &wr_c);

private:
	void _RunFc(idx2d_t idx_buf[IDX_MAX_NUM],
			hls::stream<rd_a_info_t> &rd_a,
			hls::stream<rd_b_info_t> &rd_b,
			hls::stream<wr_c_info_t> &wr_c);

	void _RunConv(idx2d_t idx_buf[IDX_MAX_NUM],
			hls::stream<rd_a_info_t> &rd_a,
			hls::stream<rd_b_info_t> &rd_b,
			hls::stream<wr_c_info_t> &wr_c);
};

#endif
