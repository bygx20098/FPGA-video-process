module tb();

`ifdef XCELIUM_RUN
initial begin
    $shm_open("waveform.shm");
    $shm_probe(tb, "ATMCF");
end
`endif

localparam CLK_100MHz = 100;

reg  clk;
reg  rst_n;
wire test_done;
wire test_pass;
wire test_fail;

initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    repeat (20) @ (posedge clk);
    rst_n = 1'b1;
end

always begin
    # (CLK_100MHz/2) clk = ~clk;
end

initial begin
    wait (test_done);
    if (test_pass)
        $display("========== SIMULATION PASSED ==========");
    else
        $display("========== SIMULATION FAILED ==========");
    $finish;
end

top DUT (
    .pll_clkout (clk),
    .rst_n      (rst_n),
    .test_done  (test_done),
    .test_pass  (test_pass),
    .test_fail  (test_fail)
);

endmodule
