module uart #(parameter baud=2400 , xtal_clk=50000000, data_width=8) (sys_clk,sys_rst_l, xmit_H,xmit_data,uart_rec_data_H,uart_xmit_data_H,xmit_done,rec_ready,rec_data_H,rec_busy,xmit_active);
 
 
input sys_clk;
input sys_rst_l;
input xmit_H;
input [7:0]xmit_data;
input uart_rec_data_H;
 
 
output uart_xmit_data_H;
output xmit_done;
output rec_ready;
output [7:0]rec_data_H;
output rec_busy;
output  xmit_active;
//wire baud_clk;
 
 
reg rx_en, ready_clr;
 
u_baud #(.baud(baud),.xtal_clk(xtal_clk)) baud_dut (.clk(sys_clk) , .baud_clk(baud_clk), .sys_rst_l(sys_rst_l)) ;
 
u_xmit #(.data_width(data_width)) tx_dut (.rst(sys_rst_l),.baud_clk(baud_clk),.xmit_H(xmit_H),.xmit_data(xmit_data), .uart_xmit_data_H(uart_xmit_data_H) ,.xmit_active(xmit_active),.xmit_done(xmit_done));
 
 
//u_rec #(.data_width(data_width)) rx_dut (.baud_clk(baud_clk),.uart_rec_data_H(uart_rec_data_H),.rst(sys_rst_l),.rec_data_H(rec_data_H), .rec_ready(rec_ready), .rec_busy(rec_busy),.rx_en(rx_en),.ready_clr(ready_clr));
 
u_rec #(.data_width(data_width)) rx_dut (.baud_clk(baud_clk),.uart_rec_data_H(uart_rec_data_H),.rst(sys_rst_l),.rec_data_H(rec_data_H), .rec_ready(rec_ready), .rec_busy(rec_busy));
endmodule
