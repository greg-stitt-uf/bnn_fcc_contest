// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (lin64) Build 3367213 Tue Oct 19 02:47:39 MDT 2021
// Date        : Mon Mar 30 18:17:57 2026
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
  (* C_INIT_FILE_NAME = "threshold_bram.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 21920)
`pragma protect data_block
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
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
