

module u_baud #(parameter baud=2400 ,parameter xtal_clk= 50000000  ) (clk , baud_clk, sys_rst_l) ;
	input wire clk ;
	input wire sys_rst_l;
	output reg baud_clk;

	 localparam tx_max= (xtal_clk/(baud* 16 * 2));
	 localparam tx_count= $clog2(tx_max);

	reg [tx_count:0]count = 0;

always @(posedge clk or negedge sys_rst_l) 
begin 
	if (!sys_rst_l) begin 
		baud_clk <= 0;
		count <= 0;
	end
 
	else begin 
		if (count == tx_max) begin 
			baud_clk =~baud_clk;
			count <= 0 ;
		end 
		else count = count +1;
	end 
end 

endmodule 

