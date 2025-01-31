/*
 *  IOb-VexRiscv -- A VexRiscv Wrapper
 */


`timescale 1 ns / 1 ps
`include "system.vh"
`include "iob_intercon.vh"

//the look ahead interface is not working because mem_instr is unknown at request
//`define LA_IF

module iob_VexRiscv
  #(
    parameter ADDR_W=32,
    parameter DATA_W=32
    )
   (
    input               clk,
    input               rst,
    input               boot,
    output              trap,

    // instruction bus
    output [`REQ_W-1:0] ibus_req,
    input [`RESP_W-1:0] ibus_resp,

    // data bus
    output [`REQ_W-1:0] dbus_req,
    input [`RESP_W-1:0] dbus_resp
    );

    wire                 ibus_req_valid;
    wire                 ibus_req_ready;
    wire [ADDR_W-1:0]  ibus_req_address;
    wire                ibus_resp_ready;
    wire [DATA_W-1:0]    ibus_resp_data;

  //modify addresses if DDR used according to boot status
  `ifdef RUN_EXTMEM_USE_SRAM
     assign ibus_req = {ibus_req_valid, ~boot, ibus_req_address[`ADDR_W-2:0], 32'h0, 4'h0};
  `else
    assign ibus_req[`valid(0)] = ibus_req_valid;
    assign ibus_req[`address(0, `ADDR_W)] = ibus_req_address;
    assign ibus_req[`wdata(0)] = 32'h0;
    assign ibus_req[`wstrb(0)] = 4'h0;
  `endif
    assign ibus_req_ready = ibus_req_valid;
    assign ibus_resp_ready = ibus_resp[`ready(0)];
    assign ibus_resp_data = ibus_resp[`rdata(0)];

    wire                dbus_req_valid;
    wire                dbus_req_ready;
    wire                   dbus_req_wr;
    wire [1:0]           dbus_req_size;
    wire [ADDR_W-1:0] dbus_req_address;
    wire [DATA_W-1:0]    dbus_req_data;
    wire [DATA_W/8-1:0]  dbus_req_strb;
    wire [DATA_W/8-1:0]  dbus_req_mask;
    wire [DATA_W/8-1:0] dbus_req_mask2;
    wire               dbus_resp_ready;
    wire [DATA_W-1:0]   dbus_resp_data;

  //modify addresses if DDR used according to boot status
  `ifdef RUN_EXTMEM_USE_SRAM
    assign dbus_req = {dbus_req_valid, (dbus_req_address[`E]^~boot)&~dbus_req_address[`P], dbus_req_address[`ADDR_W-2:0], dbus_req_data, dbus_req_strb};
  `else
    assign dbus_req[`valid(0)] = dbus_req_valid;
    assign dbus_req[`address(0, `ADDR_W)] = dbus_req_address;
    assign dbus_req[`wdata(0)] = dbus_req_data;
    assign dbus_req[`wstrb(0)] = dbus_req_strb;
  `endif
    assign dbus_req_ready = dbus_req_valid;
    assign dbus_req_strb = dbus_req_wr ? dbus_req_mask : 4'h0;
    assign dbus_req_mask = dbus_req_mask2 << dbus_req_address[1:0];
    assign dbus_req_mask2 = dbus_req_size[1] ? (dbus_req_size[0] ? {4'h0} : {4'hF}) : (dbus_req_size[0] ? {4'h3} : {4'h1});
    assign dbus_resp_ready = dbus_resp[`ready(0)];
    assign dbus_resp_data = dbus_resp[`rdata(0)];

    wire                     debug_valid;
    wire                     debug_ready;
    wire                        debug_wr;
    wire [ADDR_W/4-1:0]    debug_address;
    wire [DATA_W-1:0]         debug_data;
    wire [DATA_W-1:0]    debug_data_resp;

    assign debug_valid = 1'b0;
    assign debug_wr = 1'b0;
    assign debug_address = 8'h0;
    assign debug_data = 32'h0;

   //intantiate VexRiscv

   VexRiscv VexRiscv_core(
     .iBus_cmd_valid                (ibus_req_valid),
     .iBus_cmd_ready                (ibus_req_ready),
     .iBus_cmd_payload_pc           (ibus_req_address),
     .iBus_rsp_valid                (ibus_resp_ready),
     .iBus_rsp_payload_error        (1'b0),
     .iBus_rsp_payload_inst         (ibus_resp_data),
     .timerInterrupt                (1'b0),
     .externalInterrupt             (1'b0),
     .softwareInterrupt             (1'b0),
     .externalInterruptS            (1'b0),
     .debug_bus_cmd_valid           (debug_valid),
     .debug_bus_cmd_ready           (debug_ready),
     .debug_bus_cmd_payload_wr      (debug_wr),
     .debug_bus_cmd_payload_address (debug_address),
     .debug_bus_cmd_payload_data    (debug_data),
     .debug_bus_rsp_data            (debug_data_resp),
     .debug_resetOut                (trap),
     .dBus_cmd_valid                (dbus_req_valid),
     .dBus_cmd_ready                (dbus_req_ready),
     .dBus_cmd_payload_wr           (dbus_req_wr),
     .dBus_cmd_payload_address      (dbus_req_address),
     .dBus_cmd_payload_data         (dbus_req_data),
     .dBus_cmd_payload_size         (dbus_req_size),
     .dBus_rsp_ready                (dbus_resp_ready),
     .dBus_rsp_error                (1'b0),
     .dBus_rsp_data                 (dbus_resp_data),
     .clk                           (clk),
     .reset                         (rst),
     .debugReset                    (1'b0)
     );

endmodule
