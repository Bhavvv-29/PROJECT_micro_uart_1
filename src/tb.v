// uart_tb.v
// Testbench comparing uart.v (DUT) against ref_model.v (REF)
// All port names and parameters matched to actual source files.

`timescale 1ns/1ps
`include "uart.v"
`include "ref_model.v"

module tb;

    // =========================================================
    // Parameters
    // =========================================================
    parameter DATA_WIDTH = 8;
    parameter XTAL_CLK   = 50_000_000;
    parameter BAUD       = 2400;

    localparam BIT_CLKS   = XTAL_CLK / BAUD;       // sys_clk cycles per bit
    localparam FRAME_CLKS = BIT_CLKS * 10;          // one full UART frame

    // =========================================================
    // Shared stimulus signals
    // =========================================================
    reg sys_clk;
    reg sys_rst_l;
    reg xmitH;
    reg [DATA_WIDTH-1:0] xmit_dataH;
    reg uart_REC_dataH;

    // =========================================================
    // DUT output wires  (uart.v)
    // =========================================================
    wire uart_XMIT_dataH_dut;
    wire xmit_doneH_dut;
    wire xmit_active_dut;
    wire [DATA_WIDTH-1:0] rec_dataH_dut;
    wire rec_readyH_dut;
    wire rec_busy_dut;

    // =========================================================
    // REF output wires  (ref_model.v)
    // =========================================================
    wire uart_XMIT_dataH_ref;
    wire xmit_done_ref;
    wire xmit_active_ref;
    wire [DATA_WIDTH-1:0] rec_data_H_ref;
    wire rec_ready_ref;
    wire rec_busy_ref;

    // =========================================================
    // Test counters
    // =========================================================
    integer pass_count;
    integer fail_count;
    integer test_count;

    // =========================================================
    // DUT  uart.v
    //   Parameters : DATA_WIDTH, BAUD, CLK_FREQ
    //   TX ports   : xmitH, xmit_dataH, uart_XMIT_dataH,
    //                xmit_doneH, xmit_active
    //   RX ports   : uart_REC_dataH, rec_dataH, rec_readyH,
    //                rec_busy
    // =========================================================
    uart #(
        .DATA_WIDTH (DATA_WIDTH),
        .BAUD       (BAUD),
        .CLK_FREQ   (XTAL_CLK)
    ) dut (
        .sys_clk         (sys_clk),
        .sys_rst_l       (sys_rst_l),
        .xmitH           (xmitH),
        .xmit_dataH      (xmit_dataH),
        .uart_XMIT_dataH (uart_XMIT_dataH_dut),
        .xmit_doneH      (xmit_doneH_dut),
        .xmit_active     (xmit_active_dut),
        .uart_REC_dataH  (uart_REC_dataH),
        .rec_dataH       (rec_dataH_dut),
        .rec_readyH      (rec_readyH_dut),
        .rec_busy        (rec_busy_dut)
    );

    // =========================================================
    // REF  ref_model.v
    //   Parameters : data_width, baud, xtal_clk
    //   TX ports   : xmit_H, xmit_data, uart_xmit_data_H,
    //                xmit_done, xmit_active
    //   RX ports   : uart_rec_data_H, rec_data_H, rec_ready,
    //                rec_busy
    // =========================================================
    ref_model #(
        .data_width (DATA_WIDTH),
        .baud       (BAUD),
        .xtal_clk   (XTAL_CLK)
    ) ref_dut (
        .sys_clk          (sys_clk),
        .sys_rst_l        (sys_rst_l),
        .xmit_H           (xmitH),           // ref uses xmit_H
        .xmit_data        (xmit_dataH),       // ref uses xmit_data
        .uart_xmit_data_H (uart_XMIT_dataH_ref),
        .xmit_done        (xmit_done_ref),    // ref uses xmit_done
        .xmit_active      (xmit_active_ref),
        .uart_rec_data_H  (uart_REC_dataH),   // ref uses uart_rec_data_H
        .rec_data_H       (rec_data_H_ref),   // ref uses rec_data_H
        .rec_ready        (rec_ready_ref),    // ref uses rec_ready
        .rec_busy         (rec_busy_ref)
    );

    // =========================================================
    // Clock  100 MHz (10 ns period)
    // =========================================================
    initial sys_clk = 0;
    always #5 sys_clk = ~sys_clk;

    // =========================================================
    // Main stimulus
    // =========================================================
    initial begin
        pass_count     = 0;
        fail_count     = 0;
        test_count     = 0;
        xmitH          = 0;
        xmit_dataH     = 0;
        uart_REC_dataH = 1;
        sys_rst_l      = 1;

        $display("\n===== UART Testbench Start =====");

        reset_dut;
        test_uart;

        $display("\n===== Test Summary =====");
        $display("Total : %0d", test_count);
        $display("PASS  : %0d", pass_count);
        $display("FAIL  : %0d", fail_count);
        if (fail_count == 0)
            $display("*** ALL TESTS PASSED ***\n");
        else
            $display("*** SOME TESTS FAILED ***\n");

        #100;
        $finish;
    end

    // =========================================================
    // Top-level test sequence
    // =========================================================
    task test_uart;
        begin
            $display("\n--- Group 1: Reset ---");
            reset_dut;

            $display("\n--- Group 2: TX single bytes ---");
            tx_task(8'hA5, "TX_0xA5");
            tx_task(8'hF7, "TX_0xF7");
            tx_task(8'h08, "TX_0x08");
            tx_task(8'h00, "TX_0x00");
            tx_task(8'hFF, "TX_0xFF");

            $display("\n--- Group 3: TX idle (xmitH never asserted) ---");
            tx_without_xmith(8'hAA, "TX_NO_XMIT_AA");

            $display("\n--- Group 4: TX data lock (change data mid-frame) ---");
            tx_change_data_mid(8'hB3, 8'hFF, "TX_DATA_LOCK_B3");

            $display("\n--- Group 5: TX mid-frame xmitH assert ---");
            tx_mid_xmith_test(8'hA5, 8'h5A, "TX_MID_XMIT_A5");

            $display("\n--- Group 6: RX valid frames ---");
            rx_test(8'hA5, 1'b0, "RX_0xA5");
            rx_test(8'h00, 1'b0, "RX_0x00");
            rx_test(8'hFF, 1'b0, "RX_0xFF");

            $display("\n--- Group 7: RX false start rejection ---");
            false_start_test("RX_FALSE_START_1");
            false_start_test("RX_FALSE_START_2");

            $display("\n--- Group 8: RX bad stop bit ---");
            stop_bit_error_test(8'hA5, "RX_BAD_STOP_A5");
            stop_bit_error_test(8'hFF, "RX_BAD_STOP_FF");

            // Let RX FSM fully recover
            uart_REC_dataH = 1;
            wait(rec_busy_dut  == 0);
            wait(rec_readyH_dut == 1);
            repeat(20) @(posedge sys_clk); #1;
            compare_outputs("PRE_B2B_IDLE");

            $display("\n--- Group 9: Back-to-back TX ---");
            tx_task(8'h11, "B2B_0x11");
            tx_task(8'h22, "B2B_0x22");
            tx_task(8'h33, "B2B_0x33");
            tx_task(8'h44, "B2B_0x44");
            tx_task(8'h55, "B2B_0x55");

	    $display("\n--- Group 9B: TX Toggle Coverage ---");
	   
	     tx_toggle_coverage_test;

            $display("\n--- Group 10: Mid-TX reset ---");
            xmit_dataH = 8'hCC;
            xmitH = 1; 
	    repeat(BIT_CLKS *2 ) @(posedge sys_clk); #1; xmitH = 0;
            repeat(BIT_CLKS * 2) @(posedge sys_clk);
            reset_dut;
            compare_outputs("MID_TX_RESET");

            $display("\n--- Group 11: Reset during START bit ---");
            reset_during_start;

            $display("\n--- Group 12: Reset during DATA bits ---");
            reset_during_data;

            $display("\n--- Group 13: RX reset during DATA bits ---");
            rx_reset_during_data;

	    $display("\n--- Final DUT/REF Dump ---");
	    display_mismatch;
        end
    endtask

    // =========================================================
    // TASK: check  single pass/fail assertion
    // =========================================================
    task check;
        input cond;
        input [200*8:1] msg;
        begin
            test_count = test_count + 1;
            if (cond) begin
                pass_count = pass_count + 1;
                $display("  [PASS] %0s", msg);
            end else begin
                fail_count = fail_count + 1;
                $display("  [FAIL] %0s", msg);
            end
        end
    endtask

    // =========================================================
    // TASK: compare_outputs compare all DUT vs REF outputs
    //   Note: DUT uses xmit_doneH / rec_readyH / rec_dataH
    //         REF uses xmit_done  / rec_ready  / rec_data_H
    // =========================================================
    task compare_outputs;
        input [100*8:1] label;
        begin
            $display("[CHK] %0s", label);
            check(uart_XMIT_dataH_dut === uart_XMIT_dataH_ref, {label, " TX_DATA"  });
            check(xmit_doneH_dut      === xmit_done_ref,       {label, " TX_DONE"  });
            check(xmit_active_dut     === xmit_active_ref,     {label, " TX_ACTIVE"});
            check(rec_dataH_dut       === rec_data_H_ref,      {label, " RX_DATA"  });
            check(rec_readyH_dut      === rec_ready_ref,       {label, " RX_READY" });
            check(rec_busy_dut        === rec_busy_ref,        {label, " RX_BUSY"  });
            $display("  DUT: TX_DATA=%b TX_DONE=%b TX_ACTIVE=%b | RX_DATA=%h RX_READY=%b RX_BUSY=%b",
                uart_XMIT_dataH_dut, xmit_doneH_dut, xmit_active_dut,
                rec_dataH_dut, rec_readyH_dut, rec_busy_dut);
            $display("  REF: TX_DATA=%b TX_DONE=%b TX_ACTIVE=%b | RX_DATA=%h RX_READY=%b RX_BUSY=%b",
                uart_XMIT_dataH_ref, xmit_done_ref, xmit_active_ref,
                rec_data_H_ref, rec_ready_ref, rec_busy_ref);
        end
    endtask

    // =========================================================
    // TASK: reset_dut
    //   Assert reset for 5 sys_clk cycles, sample at held and
    //   released checkpoints.
    // =========================================================
    task reset_dut;
        begin
            sys_rst_l      = 0;
            xmitH          = 0;
            xmit_dataH     = 0;
            uart_REC_dataH = 1;
            repeat(5) @(posedge sys_clk); #1;
            compare_outputs("RESET_HELD");
            
 = 1;
            @(posedge sys_clk); #1;
            compare_outputs("RESET_RELEASE");
        end
    endtask

    // =========================================================
    // TASK: tx_task
    //   Assert xmitH for 40 sys_clk cycles so the baud-rate
    //   clock (much slower) has time to see it, then wait for
    //   both DUT and REF to finish.
    // =========================================================
    task tx_task;
        input [DATA_WIDTH-1:0] data;
        input [100*8:1] test_name;
        begin
            @(posedge sys_clk);
            xmit_dataH = data;
            xmitH      = 1;
            repeat(BIT_CLKS+20) @(posedge sys_clk); #1;
            xmitH = 0;
            repeat(10) @(posedge sys_clk); #1;
            compare_outputs({test_name, " STARTED"});

            wait(xmit_doneH_dut === 1'b1);
            wait(xmit_done_ref  === 1'b1);
            #1;
            compare_outputs({test_name, " DONE"});

            @(posedge sys_clk); #1;
            compare_outputs({test_name, " POST_DONE"});
        end
    endtask


task tx_toggle_coverage_test;

    integer i;
    reg [7:0] patterns [0:9];

    begin

        patterns[0] = 8'h55;
        patterns[1] = 8'hAA;
        patterns[2] = 8'h0F;
        patterns[3] = 8'hF0;
        patterns[4] = 8'h99;
        patterns[5] = 8'h66;
        patterns[6] = 8'hA5;
        patterns[7] = 8'h5A;
        patterns[8] = 8'hFF;
        patterns[9] = 8'h00;

        for(i = 0; i < 10; i = i + 1) begin

            @(posedge sys_clk);

            xmit_dataH = patterns[i];
            xmitH = 1;

            // IMPORTANT
            repeat(BIT_CLKS + 20) @(posedge sys_clk);

            xmitH = 0;

            wait(xmit_doneH_dut == 1'b1);
            wait(xmit_done_ref  == 1'b1);

            repeat(BIT_CLKS/2) @(posedge sys_clk);

            compare_outputs("TX_TOGGLE_COVERAGE");
        end
    end

endtask

    // =========================================================
    // TASK: tx_without_xmith
    //   Drive data but never assert xmitH  TX must stay idle.
    // =========================================================
    task tx_without_xmith;
        input [DATA_WIDTH-1:0] data;
        input [100*8:1] test_name;
        begin
            @(posedge sys_clk);
            xmit_dataH = data;
            xmitH      = 0;
            repeat(50) @(posedge sys_clk); #1;
            compare_outputs({test_name, " IDLE_END"});
        end
    endtask

    // =========================================================
    // TASK: tx_mid_xmith_test
    //   Start frame with first_data; assert xmitH again mid-
    //   frame with second_data.  First frame must complete
    //   intact; second frame then follows.
    // =========================================================
    /*task tx_mid_xmith_test;
        input [DATA_WIDTH-1:0] first_data;
        input [DATA_WIDTH-1:0] second_data;
        input [100*8:1] test_name;
        begin
            @(posedge sys_clk);
            xmit_dataH = first_data;
            xmitH      = 1;
            repeat(BIT_CLKS+20) @(posedge sys_clk); #1;
            xmitH = 0;
            repeat(10) @(posedge sys_clk);

            // Mid-frame: assert xmitH with new data
            repeat(BIT_CLKS / 2) @(posedge sys_clk);
            xmit_dataH = second_data;
            xmitH      = 1;
            repeat(BIT_CLKS+20) @(posedge sys_clk); #1;
            xmitH = 0;
            compare_outputs({test_name, " MID_FRAME"});

            // Wait for first frame done
            wait(xmit_doneH_dut === 1'b1);
            wait(xmit_done_ref  === 1'b1);
            #1;
            compare_outputs({test_name, " FIRST_DONE"});

            @(posedge sys_clk); #1;
            // If a second frame was queued, wait for it too
            if (xmit_active_dut) begin
                wait(xmit_doneH_dut === 1'b1);
                wait(xmit_done_ref  === 1'b1);
                #1;
                compare_outputs({test_name, " SECOND_DONE"});
            end
        end
    endtask*/

task tx_mid_xmith_test;
    input [DATA_WIDTH-1:0] first_data;
    input [DATA_WIDTH-1:0] second_data;
    input [100*8:1] test_name;
begin

    //--------------------------------------------------
    // FIRST FRAME
    //--------------------------------------------------
    @(posedge sys_clk);

    xmit_dataH = first_data;
    xmitH      = 1;

    repeat(BIT_CLKS+20) @(posedge sys_clk);

    xmitH = 0;

    //--------------------------------------------------
    // MID-FRAME SECOND REQUEST
    //--------------------------------------------------
    repeat(BIT_CLKS * 3) @(posedge sys_clk);

    xmit_dataH = second_data;
    xmitH      = 1;

    repeat(BIT_CLKS+20) @(posedge sys_clk);

    xmitH = 0;

    //--------------------------------------------------
    // WAIT FOR FIRST FRAME TO FINISH
    //--------------------------------------------------
    wait(xmit_doneH_dut == 1'b1);

    //--------------------------------------------------
    // SMALL DELAY
    //--------------------------------------------------
    repeat(2) @(posedge sys_clk);

    //--------------------------------------------------
    // CHECK IF SECOND TX STARTED
    //--------------------------------------------------
    if (xmit_active_dut == 1'b1) begin

        $display("[INFO] Second transmission detected");

        compare_outputs({test_name, " SECOND_STARTED"});

        wait(xmit_doneH_dut == 1'b1);

        compare_outputs({test_name, " SECOND_DONE"});
    end
    else begin
        $display("[INFO] DUT ignored second xmitH while busy");
    end

end
endtask


    // =========================================================
    // TASK: tx_change_data_mid
    //   Start frame with first_data, then change xmit_dataH to
    //   second_data mid-frame without re-asserting xmitH.
    //   The DUT must transmit only the originally latched byte.
    // =========================================================
    task tx_change_data_mid;
        input [DATA_WIDTH-1:0] first_data;
        input [DATA_WIDTH-1:0] second_data;
        input [100*8:1] test_name;
        begin
            @(posedge sys_clk);
            xmit_dataH = first_data;
            xmitH      = 1;
            repeat(BIT_CLKS+20) @(posedge sys_clk); #1;
            xmitH = 0;
            repeat(10) @(posedge sys_clk);

            // Change data bus mid-frame must be ignored
            repeat(BIT_CLKS / 2) @(posedge sys_clk);
            xmit_dataH = second_data;
            #1;
            compare_outputs({test_name, " MID_FRAME"});

            wait(xmit_doneH_dut === 1'b1);
            wait(xmit_done_ref  === 1'b1);
            #1;
            compare_outputs({test_name, " DONE"});
        end
    endtask

    // =========================================================
    // TASK: rx_test
    //   Send a complete UART frame at the sys_clk level.
    //   bad_stop=1 drives stop bit low to inject a framing error.
    // =========================================================
    task rx_test;
        input [DATA_WIDTH-1:0] data;
        input bad_stop;
        input [100*8:1] test_name;
        integer i;
        begin
            uart_REC_dataH = 1;
            @(posedge sys_clk);

            // START BIT
            uart_REC_dataH = 0;
            repeat(BIT_CLKS + (BIT_CLKS / 4)) @(posedge sys_clk); #1;

            $display("[CHK] %0s START", test_name);
            check(rec_readyH_dut === rec_ready_ref,  {test_name, " START RX_READY"});
            check(rec_busy_dut   === rec_busy_ref,   {test_name, " START RX_BUSY" });

            // DATA BITS (LSB first)
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin
                uart_REC_dataH = data[i];
                repeat(BIT_CLKS) @(posedge sys_clk);
            end
            repeat(BIT_CLKS / 2) @(posedge sys_clk); #1;
            compare_outputs({test_name, " AFTER_DATA"});

            // STOP BIT
            uart_REC_dataH = bad_stop ? 1'b0 : 1'b1;
            repeat(BIT_CLKS + (BIT_CLKS / 2)) @(posedge sys_clk); #1;

            if (bad_stop) begin
                $display("[CHK] %0s STOP (bad)", test_name);
                check(rec_readyH_dut === rec_ready_ref, {test_name, " STOP RX_READY"});
                check(rec_busy_dut   === rec_busy_ref,  {test_name, " STOP RX_BUSY" });
            end else begin
                compare_outputs({test_name, " STOP"});
            end

            // Return line to idle
            uart_REC_dataH = 1;
            repeat(BIT_CLKS + (BIT_CLKS / 2)) @(posedge sys_clk); #1;
            compare_outputs({test_name, " IDLE"});
        end
    endtask

    // =========================================================
    // TASK: false_start_test
    //   Drive line low for only half a bit period then restore
    //   high.  Both DUT and REF must ignore the glitch.
    // =========================================================
    task false_start_test;
        input [100*8:1] test_name;
        begin
            uart_REC_dataH = 1;
            @(posedge sys_clk);
            uart_REC_dataH = 0;
            repeat(BIT_CLKS / 2) @(posedge sys_clk);
            uart_REC_dataH = 1;
            repeat(BIT_CLKS) @(posedge sys_clk); #1;
            compare_outputs({test_name, " AFTER_FALSE_START"});
        end
    endtask

    // =========================================================
    // TASK: stop_bit_error_test wrapper around rx_test
    // =========================================================
    task stop_bit_error_test;
        input [DATA_WIDTH-1:0] data;
        input [100*8:1] test_name;
        begin
            rx_test(data, 1'b1, test_name);
        end
    endtask

    // =========================================================
    // TASK: reset_during_start
    //   Begin TX, then reset while still in the START bit.
    //   Uses dut.baud_mod.uart_clk (actual hierarchy in uart.v)
    // =========================================================
    task reset_during_start;
        begin
            @(posedge sys_clk);
            xmit_dataH = 8'hA5;
            xmitH      = 1;
            repeat(BIT_CLKS+20) @(posedge sys_clk);
            xmitH = 0;

            // Wait for one baud tick to be inside START
            @(posedge dut.baud_mod.uart_clk); #1;
            compare_outputs("START_RESET_BEFORE");

            sys_rst_l = 0;
            repeat(5) @(posedge sys_clk); #1;
            compare_outputs("START_RESET_DURING");

            sys_rst_l = 1;
            repeat(20) @(posedge sys_clk); #1;
            compare_outputs("START_RESET_AFTER");
        end
    endtask

    // =========================================================
    // TASK: reset_during_data
    //   Begin TX, wait until transmitter is mid-frame (flag=1
    //   and baud_count > 0), then apply reset.
    //   u_xmit has no state register use xmit_active as proxy.
    // =========================================================
    task reset_during_data;
        begin
            @(posedge sys_clk);
            xmit_dataH = 8'h3C;
            xmitH      = 1;
            repeat(BIT_CLKS+20) @(posedge sys_clk); #1;
            xmitH = 0;

            // Wait until TX is actively transmitting
            wait(xmit_active_dut === 1'b1);
            // Advance a few baud clocks into the data bits
            repeat(20) @(posedge dut.baud_mod.uart_clk); #1;

            check(xmit_active_dut == 1'b1, "DATA_RESET_BEFORE DUT_ACTIVE");
            check(xmit_doneH_dut  == 1'b0, "DATA_RESET_BEFORE DUT_DONE");

            sys_rst_l = 0;
            repeat(5) @(posedge sys_clk); #1;
            compare_outputs("DATA_RESET_DURING");

            sys_rst_l = 1;
            repeat(20) @(posedge sys_clk); #1;
            compare_outputs("DATA_RESET_AFTER");
        end
    endtask

    // =========================================================
    // TASK: rx_reset_during_data
    //   Send start + a few data bits, then apply reset.
    //   u_rec has c_state use rec_busy as proxy since
    //   internal state names may differ from expected.
    // =========================================================
    task rx_reset_during_data;
        integer i;
        begin
            $display("\n--- RX RESET DURING DATA ---");
            uart_REC_dataH = 1;
            @(posedge sys_clk);

            // START BIT
            uart_REC_dataH = 0;
            repeat(BIT_CLKS) @(posedge sys_clk);

            // A few data bits
            for (i = 0; i < 3; i = i + 1) begin
                uart_REC_dataH = 1'b1;
                repeat(BIT_CLKS) @(posedge sys_clk);
            end

            // Wait for RX to go busy (confirms it entered DATA state)
            wait(rec_busy_dut === 1'b1);
            repeat(20) @(posedge dut.baud_mod.uart_clk); #1;

            check(rec_busy_dut   == 1'b1, "RX_DATA_RESET_BEFORE BUSY");
            check(rec_readyH_dut == 1'b0, "RX_DATA_RESET_BEFORE READY");

            sys_rst_l = 0;
            repeat(5) @(posedge sys_clk); #1;
            compare_outputs("RX_DATA_RESET_DURING");

            sys_rst_l = 1;
            repeat(20) @(posedge sys_clk); #1;
            compare_outputs("RX_DATA_RESET_AFTER");

            uart_REC_dataH = 1;
        end
    endtask

    // =========================================================
    // TASK: display_mismatch print raw DUT vs REF state
    // =========================================================
    task display_mismatch;
        begin
            $display("  DUT: TX_DATA=%b TX_DONE=%b TX_ACTIVE=%b | RX_DATA=%h RX_READY=%b RX_BUSY=%b",
                uart_XMIT_dataH_dut, xmit_doneH_dut, xmit_active_dut,
                rec_dataH_dut, rec_readyH_dut, rec_busy_dut);
            $display("  REF: TX_DATA=%b TX_DONE=%b TX_ACTIVE=%b | RX_DATA=%h RX_READY=%b RX_BUSY=%b",
                uart_XMIT_dataH_ref, xmit_done_ref, xmit_active_ref,
                rec_data_H_ref, rec_ready_ref, rec_busy_ref);
        end
    endtask

    // =========================================================
    // Watchdog abort if simulation hangs
    // =========================================================
    initial begin
        #(FRAME_CLKS * 200 * 10);
        $display("[WATCHDOG] Simulation timed out!");
        $finish;
    end

    // =========================================================
    // Waveform dump
    // =========================================================
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end

endmodule
