// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (lin64) Build 3367213 Tue Oct 19 02:47:39 MDT 2021
// Date        : Mon Mar 30 18:16:08 2026
// Host        : ece-lnx-08 running 64-bit Red Hat Enterprise Linux Server release 7.9 (Maipo)
// Command     : write_verilog -force -mode funcsim
//               /ecel/UFAD/ca.oeltjen/Desktop/BNN/bnn_synth/bnn_synthesis/bnn_synthesis.gen/sources_1/ip/weight_bram/weight_bram_sim_netlist.v
// Design      : weight_bram
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu3eg-sbva484-1-e
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "weight_bram,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2021.2" *) 
(* NotValidForBitStream *)
module weight_bram
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
  (* C_INIT_FILE = "weight_bram.mem" *) 
  (* C_INIT_FILE_NAME = "weight_bram.mif" *) 
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
  weight_bram_blk_mem_gen_v8_4_5 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 21872)
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
