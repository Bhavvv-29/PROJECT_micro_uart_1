module u_xmit #(parameter baud=2400 , parameter data_width=8)(rst,baud_clk, xmit_H, xmit_data, uart_xmit_data_H ,xmit_active, xmit_done);
 
input wire baud_clk;
input wire rst ;
input wire xmit_H;
input wire [data_width-1:0] xmit_data;
output reg xmit_active;
output reg uart_xmit_data_H;
output reg xmit_done;
 
 
reg [1:0]state;
 
localparam idle = 2'd0;
localparam start = 2'd1;
localparam t_data = 2'd2;
localparam stop = 2'd3;
 
reg [data_width-1:0]data_temp ;
 
reg [3:0] bit_cnt;
reg [$clog2(data_width)-1:0]data_cnt;
 
always @(posedge baud_clk or negedge rst)
begin
if (!rst) begin
	state <= idle;
	xmit_active <= 1'b0;
	xmit_done <= 1'b1;
	bit_cnt <= 4'b0;
	data_cnt <= 0;
	uart_xmit_data_H <=1'b1;
	data_temp <=0;
end
else
begin
       case (state )
                idle : begin
                        xmit_active<=1'b0;
                        xmit_done<=1'b1;
                        if (xmit_H && xmit_active ==1'b0) begin
                                data_temp <= xmit_data;
                                state <= start ;
                        end
                        else state <=idle ;
                end
 
                start : begin
                        xmit_active<=1'b1;
                        xmit_done <=1'b0;
                        uart_xmit_data_H <= 1'b0;
                        if (bit_cnt < 4'd15) begin
                                bit_cnt <= bit_cnt + 1;
                        end
                        else begin
                                bit_cnt <= 4'd0;
                                state <=t_data;
                        end
                end
 
                t_data: begin
                        xmit_active <= 1'b1;
                        uart_xmit_data_H <= data_temp[data_cnt];
                        if (bit_cnt <15) begin
                                bit_cnt <=bit_cnt+1;
                        end
                        else begin
                                bit_cnt <=0;
                                if (data_cnt < data_width - 1) begin
                                        data_cnt <= data_cnt + 1;
                                end
                                else begin
                                        data_cnt <= 0;
                                        state <= stop;
                                end
                        end
                end
 
 
                stop: begin
                        uart_xmit_data_H <= 1'b1;
                        if (bit_cnt < 4'd15) begin
                                bit_cnt <= bit_cnt + 1;
                        end
                        else begin
                                bit_cnt <= 4'd0;
                                xmit_done <= 1'b1;
                                xmit_active <= 1'b0;
                                //if (xmit_H) begin state <= start ; end
                                //else
                                state <= idle;
                        end
                end
 
                default :begin
                        state <= idle ;
                        xmit_active <= 1'b0;
                        xmit_done <= 1'b0;
                end
        endcase
        end
end
endmodule

