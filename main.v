`timescale 1ns / 1ps


module main(clock_in,A,B,C,D,E,F,G,anode,button,BIN2,TMP); 
	input clock_in;
	output [3:0] anode;
	input button;
	output TMP;
	output A,B,C,D,E,F,G;
	output [3:0] BIN2; //Wyjście rejestru na diody
	
	wire Clk1Hz; //1Hz zegar
	wire E_Reset;
	wire Reset;		//Reset licznika bębna
	wire Score;
	
	//Połaczenia dla bębna nr.1
	wire [3:0] BIN; //  Połaczenie Licznik  -> Rejestr (Zapisanei liczby pseudo losowej)
	wire [3:0] BIN2; // Połaczenie Wyjścia rejestru -> Komparator, Kiedy bęben osiągnie wartość z rejestru nastąpi zatrzymanie 
	wire [3:0] BIN3; //Połaczenie Bęben -> Komparator
	wire Enable; 	//Włączenie Rejestru SISO, odliczającego 5sekund 
	wire ClkToCNT; //Połaczenie zegara z licznikiem, generacja wartości losowej
	 
	//Połaczenia dla bębna nr.2
	wire [3:0] S_BIN; //  Połaczenie Licznik  -> Rejestr (Zapisanei liczby pseudo losowej)
	wire [3:0] S_BIN2; // Połaczenie Wyjścia rejestru -> Komparator, Kiedy bęben osiągnie wartość z rejestru nastąpi zatrzymanie 
	wire [3:0] S_BIN3; //Połaczenie Bęben -> Komparator
	wire S_Enable;
	wire S_ClkToCNT; //Połaczenie zegara z licznikiem, generacja wartości losowej
	
	//Połaczenia dla bębna nr.3
	wire [3:0] T_BIN; //  Połaczenie Licznik  -> Rejestr (Zapisanei liczby pseudo losowej)
	wire [3:0] T_BIN2; // Połaczenie Wyjścia rejestru -> Komparator, Kiedy bęben osiągnie wartość z rejestru nastąpi zatrzymanie 
	wire [3:0] T_BIN3; //Połaczenie Bęben -> Komparator
	wire T_Enable;
	wire T_ClkToCNT; //Połaczenie zegara z licznikiem, generacja wartości losowej
	
	wire clock10kHz;
	wire [1:0] refreshcounter;
	wire [3:0] anode;
	wire [3:0] Digit;

	Clock_divider1 Prescaler1HZ(.clock_in(clock_in), .clock_out(Clk1Hz));
	
	//Bęben nr.1
	Clock_divider2 Prescaler(.clock_in(clock_in), .clock_out(ClkToCNT));
	CNT Licznik(.CLK(ClkToCNT), .CLR(0),.E(1),.Q(BIN));
	REG Rejestr(.D(BIN),.CLK(ClkToCNT),.CLR(0),.Button(button),.Q(BIN2)); 
	CNT Beben1(.CLK(Clk1Hz), .CLR(Reset),.E(Enable),.Q(BIN3));	
	COMP Komparator(.R(BIN2),.L(BIN3),.E(Enable));
	
	//Bęben nr.2
	Clock_divider3 S_Prescaler(.clock_in(clock_in), .clock_out(S_ClkToCNT));
	CNT S_Licznik(.CLK(S_ClkToCNT), .CLR(0),.E(1),.Q(S_BIN));
	REG S_Rejestr(.D(S_BIN),.CLK(S_ClkToCNT),.CLR(0),.Button(button),.Q(S_BIN2)); 
	CNT S_Beben1(.CLK(Clk1Hz), .CLR(Reset),.E(S_Enable),.Q(S_BIN3));	
	COMP S_Komparator(.R(S_BIN2),.L(S_BIN3),.E(S_Enable));
	
	
	//Bęben nr.3
	Clock_divider4 T_Prescaler(.clock_in(clock_in), .clock_out(T_ClkToCNT));
	CNT T_Licznik(.CLK(T_ClkToCNT), .CLR(0),.E(1),.Q(T_BIN));
	REG T_Rejestr(.D(T_BIN),.CLK(T_ClkToCNT),.CLR(0),.Button(button),.Q(T_BIN2)); 
	CNT T_Beben1(.CLK(Clk1Hz), .CLR(Reset),.E(T_Enable),.Q(T_BIN3));	
	COMP T_Komparator(.R(T_BIN2),.L(T_BIN3),.E(T_Enable)); 
	
	KomparatorBebnow KomparatorDoRejestu(.Comp1(Enable),.Comp2(S_Enable),.Comp3(T_Enable),.E(E_Reset));
	SISO RS_ISO(.CLK(Clk1Hz),.SI(E_Reset),.SO(Reset));
	assign TMP = E_Reset;
	
	KomparatorRejestru Wynik(.Rej1(BIN2),.Rej2(S_BIN2),.Rej3(T_BIN3),.R(Score));
	
	Clock_divider100kHZ CLKto7SEG(.clock_in(clock_in),.clock_out(clock10kHz));
	refreshcounter RefreshDigit(.refresh_clock(clock10kHz),.refreshcounter(refreshcounter));
	anode_control anoda(.refreshcounter(refreshcounter),.anode(anode));
	BCD_control BCDSEG(.digit1(BIN3),.digit2(S_BIN3),.digit3(T_BIN3),.digit4(Score),.refreshcounter(refreshcounter),.ONE_DIGIT(Digit));
	SEG7 Wyswietlacz1(.BIN(Digit),.A(A),.B(B),.C(C),.D(D),.E(E),.F(F),.G(G));

	 
endmodule


//Clock 1HZ
module Clock_divider1(clock_in,clock_out);
	input clock_in; // input clock on FPGA
	output reg clock_out; // output clock after dividing the input clock by divisor
	reg[27:0] counter=28'd0;
	
	parameter DIVISOR = 28'd50000000;

always @(posedge clock_in)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;
 clock_out <= (counter<DIVISOR/2)?1'b1:1'b0;
end
endmodule

//100kHZ
module Clock_divider100kHZ(clock_in,clock_out);
	
	input clock_in; // input clock on FPGA
	output reg clock_out; // output clock after dividing the input clock by divisor
	reg[27:0] counter=28'd0;
	
	parameter DIVISOR = 28'd5000;

always @(posedge clock_in)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;
 clock_out <= (counter<DIVISOR/2)?1'b1:1'b0;
end
endmodule

//Zegar 1 beben
module Clock_divider2(clock_in,clock_out);
	input clock_in; // input clock on FPGA
	output reg clock_out; // output clock after dividing the input clock by divisor
	reg[27:0] counter=28'd0;
	
	parameter DIVISOR = 28'd50000;

always @(posedge clock_in)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;
 clock_out <= (counter<DIVISOR/2)?1'b1:1'b0;
end
endmodule

//Zegar 2 beben
module Clock_divider3(clock_in,clock_out);
	input clock_in; // input clock on FPGA
	output reg clock_out; // output clock after dividing the input clock by divisor
	reg[27:0] counter=28'd0;
	
	parameter DIVISOR = 28'd1000;

always @(posedge clock_in)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;
 clock_out <= (counter<DIVISOR/2)?1'b1:1'b0;
end
endmodule

//Zegar 3 beben
module Clock_divider4(clock_in,clock_out);
	input clock_in; // input clock on FPGA
	output reg clock_out; // output clock after dividing the input clock by divisor
	reg[27:0] counter=28'd0;
	
	parameter DIVISOR = 28'd50;

always @(posedge clock_in)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;
 clock_out <= (counter<DIVISOR/2)?1'b1:1'b0;
end
endmodule

//Licznik Synch

module CNT(CLK,CLR,Q,E);
	input CLK, CLR,E;
	output [3:0] Q;
	reg [3:0] Q;

always @(posedge CLK or posedge CLR)
  if(CLR)
    Q <= 4'd0;
  else if(E)
    Q <= Q + 1;
endmodule


//Rejetr liczby losowej
module REG(D,CLK,CLR,Button,Q);
	input [3:0] D;
	input CLK;
	input CLR;
	input Button;
	output [3:0] Q;
	reg [3:0] Q;

always@(CLK)
	if(CLK && Button)
    Q <= D;
	 else if (CLR)
	 Q <= 4'b0000;
endmodule

//Komparator
module COMP(R,L,E);
	input [3:0] R; //Wejście z rejestru
	input [3:0]	L; //aktualny stan licznika
	output E;
	reg E;
	
always@(R,L)
	begin
	if(R!=L)
		E<=1'b1;
	else if(R==L)
		E<=1'b0;
	end
endmodule

//Komparator 2
module KomparatorBebnow(Comp1,Comp2,Comp3,E);
	input Comp1;
	input Comp2;
	input Comp3;
	output E;
	reg E;
	
always@(Comp1,Comp2,Comp3)
	begin
	if((Comp1==0) && (Comp2==0) && (Comp3==0))
		E<=1'b0;
	else 
		E<=1'b1;
	end
endmodule

//Komparator wyników
module KomparatorRejestru(Rej1,Rej2,Rej3,R);
	input [3:0] Rej1;
	input [3:0] Rej2;
	input [3:0] Rej3;
	output [3:0] R;
	reg [3:0] R;
	
always@(Rej1,Rej2,Rej3)
	begin
	if((Rej1==Rej2) && (Rej1==Rej3))
		R<=Rej1;
	else 
		R<=4'b0000;
	end
endmodule

//Rejestr przesówny 	
module SISO(CLK, SI, SO);
input CLK;
input SI;
output SO;
reg TMP;
reg [4:0] Q=0;
always@(posedge CLK)
begin
	Q[4]<=~SI;
	Q[3]<=Q[4];
	Q[2]<=Q[3];
	Q[1]<=Q[2];
	Q[0]<=Q[1];
end
assign SO=Q[0];
endmodule	

//Wyświetlacz 7-seg
module SEG7(BIN, A,B,C,D,E,F,G);
input [3:0] BIN;
output A;
output B;
output C;
output D;
output E;
output F;
output G;
//output [6:0] SEG;
reg [6:0] SEG;
   always @(BIN)   
      case (BIN)
          4'b0001 : SEG = 7'b1111001;   // 1
          4'b0010 : SEG = 7'b0100100;   // 2
          4'b0011 : SEG = 7'b0110000;   // 3
          4'b0100 : SEG = 7'b0011001;   // 4
          4'b0101 : SEG = 7'b0010010;   // 5
          4'b0110 : SEG = 7'b0000010;   // 6
          4'b0111 : SEG = 7'b1111000;   // 7
          4'b1000 : SEG = 7'b0000000;   // 8
          4'b1001 : SEG = 7'b0010000;   // 9
          4'b1010 : SEG = 7'b0001000;   // A
          4'b1011 : SEG = 7'b0000011;   // b
          4'b1100 : SEG = 7'b1000110;   // C
          4'b1101 : SEG = 7'b0100001;   // d
          4'b1110 : SEG = 7'b0000110;   // E
          4'b1111 : SEG = 7'b0001110;   // F
          default : SEG = 7'b1000000;   // 0
      endcase

assign A = SEG[0];
assign B = SEG[1];
assign C = SEG[2];
assign D = SEG[3];
assign E = SEG[4];
assign F = SEG[5];
assign G	= SEG[6];
		
endmodule

//Refresh Counter
module refreshcounter(refresh_clock,refreshcounter);
	input refresh_clock;
	output [1:0] refreshcounter;
	reg [1:0] refreshcounter=0;

always@(posedge refresh_clock)
	refreshcounter<=refreshcounter+1;
endmodule

//anode control
module anode_control(refreshcounter,anode);
	input [1:0] refreshcounter;
	output [3:0] anode;
	reg [3:0] anode=0;

always@(refreshcounter)
		begin
			case(refreshcounter)
			2'b00:
				anode=4'b1110; // maksymkalnie z prawej (nr.1)
			2'b01:
				anode=4'b1101; //(nr.2)
			2'b10:
				anode=4'b1011; //(nr.3)
			2'b11:
				anode=4'b0111; // maksymkalnie z lewej (nr.4)
			endcase
		end
	
endmodule

//BCD controler
module BCD_control(digit1,digit2,digit3,digit4,refreshcounter,ONE_DIGIT);
	input [3:0] digit1;
	input [3:0] digit2;
	input [3:0] digit3;
	input [3:0] digit4;
	input [1:0] refreshcounter;
	output [3:0] ONE_DIGIT;
	reg [3:0] ONE_DIGIT;
	
always@(refreshcounter)
	begin
		case(refreshcounter)
			2'd0:
				ONE_DIGIT<=digit1;
			2'd1:
				ONE_DIGIT<=digit2;
			2'd2:
				ONE_DIGIT<=digit3;
			2'd3:
				ONE_DIGIT<=digit4;
		endcase
	end	
endmodule 
