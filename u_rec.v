`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.05.2026 10:51:12
// Design Name: 
// Module Name: u_rec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module u_rec #(parameter data_width = 8) (
    input rst,             // rst is active low
    input baud_clk,        // 16x oversampled baud clock
    input uart_rec_data_H, // serial input (idle HIGH)
    output reg [data_width-1:0] rec_data_H, // received parallel data
    output reg rec_ready,       // pulses HIGH when byte ready
    output reg rec_busy,        // HIGH during reception
    input rx_en,           // enable receiver
    input ready_clr        // clear rec_ready flag
);

    localparam idle = 2'b00;
    localparam start= 2'b01;
    localparam r_data = 2'b10;
    localparam stop = 2'b11;


    reg [1:0] state;
    reg [3:0] sample; // counts the no of the sample 
    reg [2:0]  bit_pos; // data index
    reg [data_width-1:0] temp_data;   
    reg rxd_ff1;     
    reg rxd_ff2;     


    always @(posedge baud_clk or negedge rst) begin
        if (!rst) begin
            rxd_ff1 <= 1'b1;   
            rxd_ff2 <= 1'b1;
        end
        else begin
            rxd_ff1 <= uart_rec_data_H;
            rxd_ff2 <= rxd_ff1;
        end
    end

    always @(posedge baud_clk or negedge rst) begin

        if (!rst) begin
            state <= idle;
            sample <= 4'd0;
            bit_pos <= 3'd0;
            rec_ready <= 1'b0;
            rec_busy <= 1'b0;
            temp_data <= {data_width{1'b0}};
            rec_data_H <= {data_width{1'b0}};
        end

        else begin

            if (ready_clr)
                rec_ready <= 1'b0;

            if (!rx_en) begin
                state <= idle;
                sample <= 4'd0;
                bit_pos <= 3'd0;
                rec_busy <= 1'b0;
            end

            else begin
                case (state)

                    idle: begin
                        rec_busy <= 1'b0;
                        sample <= 4'd0;
                        if (rxd_ff2 == 1'b0) begin

                            state <= start;
                            rec_busy <= 1'b1;
                            sample <= 4'd1; 
                        end
                    end
                    
                    start: begin
                        sample <= sample + 4'd1;

                        if (sample == 4'd6) begin
                            if (rxd_ff2 != 1'b0) begin
                                state <= idle;
                                sample <= 4'd0;
                                rec_busy <= 1'b0;
                            end
                        end

                        else if (sample == 4'd15) begin
                            state <= r_data;
                            sample <= 4'd0;
                            //rec_data_H <= {data_width{1'b0}};
                            temp_data <= {data_width{1'b0}};
                            bit_pos <= 3'd0;
                        end
                    end


                    r_data: begin
                        sample <= sample + 4'd1;

                        if (sample == 4'd6) begin
                            temp_data[bit_pos] <= rxd_ff2;
                        end

                        if (sample == 4'd15) begin
                            sample <= 4'd0;
                            if (bit_pos == (data_width - 1)) begin
                                state <= stop;
                                bit_pos <= 3'd0;
                            end
                            else begin
                                bit_pos <= bit_pos + 3'd1;
                            end
                        end
                    end

                    stop: begin
                        sample <= sample + 4'd1;
                        if (sample == 4'd8) begin
                            if (rxd_ff2 != 1'b1) begin
                                state <= idle;
                                sample <= 4'd0;
                                rec_busy <= 1'b0;
                            end
                        end

                        else if (sample == 4'd15) begin
                            state <= idle;
                            rec_data_H <= temp_data;
                            rec_ready <= 1'b1;
                            rec_busy <= 1'b0;
                            sample <= 4'd0;
                        end
                    end

                    default: begin
                        state <= idle;
                        sample <= 4'd0;
                        bit_pos <= 3'd0;
                        rec_busy <= 1'b0;
                    end

                endcase
            end
        end
    end

endmodule
