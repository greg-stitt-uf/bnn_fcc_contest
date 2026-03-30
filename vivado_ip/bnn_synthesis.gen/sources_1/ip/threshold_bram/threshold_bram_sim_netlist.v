// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (lin64) Build 3367213 Tue Oct 19 02:47:39 MDT 2021
// Date        : Mon Mar 30 17:32:56 2026
// Host        : ece-lnx-08 running 64-bit Red Hat Enterprise Linux Server release 7.9 (Maipo)
// Command     : write_verilog -force -mode funcsim
//               /ecel/UFAD/ca.oeltjen/Desktop/BNN/bnn_synth/bnn_synthesis/bnn_synthesis.gen/sources_1/ip/threshold_bram/threshold_bram_sim_netlist.v
// Design      : threshold_bram
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu3eg-sbva484-1-e
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "threshold_bram,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2021.2" *) 
(* NotValidForBitStream *)
module threshold_bram
   (clka,
    ena,
    wea,
    addra,
    dina,
    douta,
    clkb,
    enb,
    web,
    addrb,
    dinb,
    doutb);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [9:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [15:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [15:0]douta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB WE" *) input [0:0]web;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [9:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DIN" *) input [15:0]dinb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [15:0]doutb;

  wire [9:0]addra;
  wire [9:0]addrb;
  wire clka;
  wire clkb;
  wire [15:0]dina;
  wire [15:0]dinb;
  wire [15:0]douta;
  wire [15:0]doutb;
  wire ena;
  wire enb;
  wire [0:0]wea;
  wire [0:0]web;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [9:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [9:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [15:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "10" *) 
  (* C_ADDRB_WIDTH = "10" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "0" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     2.29156 mW" *) 
  (* C_FAMILY = "zynquplus" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "1" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "1" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "threshold_bram.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "2" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "1024" *) 
  (* C_READ_DEPTH_B = "1024" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "16" *) 
  (* C_READ_WIDTH_B = "16" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "1024" *) 
  (* C_WRITE_DEPTH_B = "1024" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "16" *) 
  (* C_WRITE_WIDTH_B = "16" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  threshold_bram_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb(addrb),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb(dinb),
        .douta(douta),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[9:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[9:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[15:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(web));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2021.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
oESHD2Q5NORrmTVTCApB+YFZJwjA1ezq7U6VZh96by+ofPCvSFp06AIoCLvB4BhPvxfob6kIkBpR
xVCOLM7HsDk7nO1JVWiYIJ6okoWTA8hAlPj3sdGuMwRlZNSBKn/c6F+CW5Jl37TEGotkhycSB3Bg
B/uu1THUZwIG87RPahE=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
RovEhaqHrFqzjckk+DIWG8LQeqg2Y/nACQDyXKKtSav7YHlgpKmgHZnsxwwNpqrqVRGyjTecSQ+e
6Mr/Pi9au3AgJVPL6VOgwNVE0yj2LpA4LPyWzxLN3+DiSDmsaCBNCBlVQi2MRKUabou8nLaXldbL
+7pv4pYhQdcyjDzuC2dx3HmzADqstdEiyXeU3ktJ29CDLDmGwDWdmsrl90s4YQSfBV2nj4/Vut3L
p/8dzphf1htPaNMujMxxgp3z4JzUEDJJokDL+gNutEEHiaWpI3URIA5v22vJu+NPD+eEraSioHfL
DPKAajZTwK5FHnonu4O2D0co8GWqWW5cUqZz9A==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
jBQ6Th9yy7jtKQD1h235YLT6qO6XiBaBKGJrV1Z8H9M9ePJ9R/fA8E1okt4LyBvoWjR7tmCbIg7A
0/vuKOogkLtDE/BtTlp4z1iurO8rQrAcdZy/e+7GATawyJxFY7kZhnXASu9zB8TiOBELSlapkpxe
WuAzXLde9FBMBkq4RSc=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
eucSNV2Zbm4zYc2tIGRlGmlVM8+WHY1NHe9drZdgDhGPOHz8PTqHapfnZ1kWuTLtPBLSMvcXNScn
UTvpULofBV6qD7WHLPg7UJcjpZVDL69lk88chgqrlc/RqaJXKNVv+Ubku53ZLU20uZK71bNymjSM
855RVWw5lvTHTCNC2MYIS94Fmrzuq8i0+tFh5qBKkHK2BC+fD7xVyyfuh4mZR2yr/hRs/emoI79E
IKoJnLiglVp6RXTsXFzZW4pIthbjWSuZlOQvoYkS2RMj8a0r9lyariphRQunoudc0bLO4Phk578c
40gusaaS/MI7idMT7k1Di96kvu5mHi23loRcZQ==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
E/syLaRG2Ss/xTTkuAkOKXzm53+rCptYO2DkVukWhvlLmEB2daHCPrXt4gKeuG+0hIGWedSwCiLJ
7KNtEAiTumJ/j+3p7s3oXN9ftCSRolXoACsCclEAmwYjVM0ubCXUx6JNFOGt0yDl2Jsd5+W10mSJ
bYEKvRKi7koXM/eYJqbhTrtsrHDwRJEY0JVUPh8EOkLLqaIKbnjb6ENEY6qZOamp5PaWsSS30gJM
N6fB8D1AmGKnFbfY+d5TexS55Z92aYcAHNX2XwHsKnm45az1vHeZ0rTEU/oONIaSZfikRni1iDBg
x2GOue6sLiwxTEHaVkTJsOVR4mx0VsfFxavwRg==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2021_01", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
dSHHpkQiOEzzKs4D71WVyDXLpkKuR9h9h3pBLtnCq2bXiwE/eQHmk5HeQb+qREg0Yv193OukqaQz
RZyuF5GQcqOpqFHMxO62HQ2pdjdpMT5CC7gHvmgiw9qBkJJrXpihIHER4X7OF2iNUfeqxJ8eiSz3
C0V20NlIwKG7Mxg8MVj++xmb32KMUqL7ptikkym20vVdhecVMNvpPoXp8uvaGT7991enWP9HGKUC
9kLY2DEYwRGE71UJJLGWo4n49R50ExFRj91xWnYfvp7uJsMNwnBp5l3GTZiMELX2RkRVSPOHr7l1
n2p5Vq7Uee2drny1IxZ/4c0hYY6y3QWSEqpESw==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
HUtfqZ9dh5oZTOAt9a0ebo+wQbzg3izFQ0kVqZN81S4cBjQEF53WUiVlTKBDVjvLNUby4Se9WZjj
j86TQzuGJxLPDTohmbytErsg5JrlXHbHGwR4zGNGTbBs12X7PkxtS8wVCp+7b1rX6pOGOPqm6FoG
g6rZY/bTzVfGYF2CAOhjJUqUOXEAKnZRehspRyiBI28/ZZPSAUD/abKprW8PWCxMx2zPWztZz4No
R96jgvHezNzB1Ta8W7uRBFTMp+XVSToxTp2jzSXJZ0V5xJl+gdVjAMmf6+te2vqrK2wDWdMxk3Sf
iyLI4d0s25vCybcY2fZWacq5iO9pSlSaOQWgCA==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
vYYu2Kvhv3RZi0pFbjRTQ/BBwfilCrGpkMls+Dz6HBGTZvSaC/anWgymoDS0XnoSENGG3Pz3EBF0
19OqLbyna95IHFe2bA7f8RgU9SEUffZ8eXGigfOjAWpZCN07Q77RkhGUKal7okWe3Q6xHtZy83l2
kW8ma3kOYL7GzQjtpbP3lINHLMqpGEo0dzbOHiJ5r6W5U6DsILGsoLQOXcw+MwrevvNRB0KkSklj
QnL8K2AK8PIsJGM6F8dj5KwRYhSBYNb1opuVpiJWlbHgADoeM+dhiRxBLmnaDE8PWs1ReY6uMzzH
SvvO6UEyxQtvS/Smm/uogr1eUFedUaBHPMEXnYlTAv/SKrh942GeknsqfrjGkZxWTN2NEnvpRUwT
fS0pyd/Err0s94b0srmcTYyxZfJGRUct2T8MCphZFaScAlhn655pxW9RaHMfcvDJUHpW8Qa+KhRt
9CWYScPIH6YNDByLQbhKL5BTpAYMNYPF2W7vM2ZzDob2NB7m6GGeKRr3

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QSNmIeTT4pBji+CTjknWXN6sH9Wff8+t8KF+AC3fIoIw08jtLtShcB9ZGeEKG02RGCO4lNIUf5YB
2TVYk6EJ5XyCav12qDhc60n56UVrnpfo7drorY0NmOypuxECgO43h6SDWp9W7px3r4CJnQ4+X2Mj
943GdP30WfL5kbWHZJC1Dz9cBIqRa1EbNXvvAqBvRPS2+aXBXAPOC4rNVZGeIUspn/33IW3yJLSp
Jm5GIct87ZuSoz8+DXhUvsTj4hq8lgirVhfz1qhHm8SfODcE91FGUPw3vbpGWXsBX73t2zxFC1Hz
/6m4YqQJVxd+H5iGE4kbHxHyHnH7FIerqc8Phw==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
UhfxKxECbuHK/o9ZExa2zP/MIPmFXuDNZwgpiawuBmPeRI1nJsYB7vzbBGMPKny4yIHLT8mHrQRc
fs05atkjIAbLea4+WNoCdCeg7/0PzuodM1ol3it6BHQ6Yzq4mnZbzlk8Xtwmk8ACAbzOr2SYxYWX
ueuUlimUSRusIe4+NiPvzbfHMAOVPjdmSY7zaSyeJuhdAR+fUGeHy5B23Xe2X6cDPeJ75IqcBeul
ox3dTXi3L8r/s1bTKX3FhxRyPZuh/xCWuEajsF2fEYdwWHKtLX6IQniLBJ5ZnVSS8D7IYPsvV4t0
9rWJqto5O1n3rAM44OvKvc9pOYXJupuv7g3gWg==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
fmo66vhS7nigYtLDMjdj7hgUnDG/fnO+cIaY/3qHrcwT7u/paj5enLuWHovegu9O9WRq3pPNnjuN
6vZRpuCgz5p4VAV7dVg9fuzg99BAjThp1Q/+HIPfdQ2LM14ZpTh4FXxthHGkTyS5PJArvZ3/UMpW
zwfdYd5+k2/emJ4/nuqoJHQG8k+O5EjSprLTvNZ/wrE1cT/fW/Lu2pxI4msHqVVYAXz7sJ13cQ+C
7tKxCV8vTyf0rpStdE+kZXg+jrc7vFKuPJO0U9axMsC0nXyeYx2jzfAHptGWKvfQaPg/Eo9mgLyN
qSJfFS6aIycuxNmg7L82WK401aWhnUn7GNrudg==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 21904)
`pragma protect data_block
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
vO+GjKyNERIyetrJTdGnRA==
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
