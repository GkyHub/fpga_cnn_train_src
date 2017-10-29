#include "addr_gen_unit.hpp"
#include "data_type.hpp"

void addr_gen_unit_top(agu_mode_t mode,
		cnt_t idx_cnt, cnt_t trip_cnt,
		idx2d_t idx_buf[IDX_MAX_NUM],
		hls::stream<rd_a_info_t> &rd_a,
		hls::stream<rd_b_info_t> &rd_b,
		hls::stream<wr_c_info_t> &wr_c,
		bool is_new, ap_uint<4> pad_code, bool cut_y)
{
	AddrGenUnit agu(1, 0);
	agu.Config(mode, idx_cnt, trip_cnt, is_new);
	if (mode == MODE_CONV) {
		agu.PadConfig(pad_code, cut_y);
	}
	agu.Run(idx_buf, rd_a, rd_b, wr_c);
	return;
}
