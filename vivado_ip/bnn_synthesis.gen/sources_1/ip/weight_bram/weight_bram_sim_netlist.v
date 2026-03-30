// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (lin64) Build 3367213 Tue Oct 19 02:47:39 MDT 2021
// Date        : Mon Mar 30 17:32:04 2026
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
