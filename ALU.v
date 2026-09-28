module ALU(
  input wire[3:0] in1, in2,
  input wire[1:0] OpCode,
  output reg [7:0] result,
  output reg Overflow
);
  
always @(*)
begin
  case(OpCode)
    2'b00:
    begin
      result <= in1 + in2;
      if((in1 + in2) > 9'b011111111)
      	Overflow <= 1;    
      else
      	Overflow <= 0;  ;
	 end
    2'b01:
    begin
		result <= in1 - in2;
      if((in1 - in2) > 9'b011111111)
      	Overflow <= 1;    
      else
      	Overflow <= 0;  
    end	
    2'b10:
    begin
		result <= in1 * in2;
      if((in1 * in2) > 9'b011111111)
      	Overflow <= 1;    
      else
      	Overflow <= 0;    
    end
  endcase
end
endmodule  


module fsm (
  input wire fac, clk, reset,
  input wire [3:0] in1,
  output reg [7:0] result,
  output reg Overflow
);
  localparam[3:0]
  Idle = 0, Choose = 1, Fact = 2, Fibi = 3, StoreNFact = 4, Nminus = 5, Return = 6, UpdateFact = 7, UpdateFibi = 8, StoreNFibi = 9, AddFibiIndex = 10, Wait = 11, WaitUpdateFibi = 12;
  
  reg [3:0] state;
  reg OverflowTemp;
  reg [3:0] in1Temp;
  reg [3:0] in2Temp;
  reg [1:0]	OpCodeTemp;
  reg [7:0] resultTemp;
  reg [7:0] resultOld;
  reg [7:0] resultOldCopy;
  reg [3:0] index;
  reg [3:0] indexCopy;
  
  ALU ALU(.in1(in1Temp), .in2(in2Temp), .OpCode(OpCodeTemp), .result(resultTemp), .Overflow(OverflowTemp));
  
  always@(posedge clk, posedge reset)begin
    if(reset)begin
    	state <= Idle; 
    end 
    
    case(state)
      Idle:
        if (fac == 1)
          state <= Choose;
      	else if(fac == 0)
          state <=Choose;
      Choose: begin
        if(fac == 1)
          state <= StoreNFact;
        else if(fac == 0)
          state <= StoreNFibi;
      end
      StoreNFact: begin
        if(in1 == 0)
          state <= Return;
        else
      	  state <= Nminus;
      end
      StoreNFibi: begin
        if(in1 < 2)
          state<= Return;
        else
          state <= Fibi;
      end  
      Nminus: begin
        if(index == 1)
        	state <= Return;
      	else
       		state <=Wait;
      end
      Fact: begin
      	state <= UpdateFact;
        //you cannot have the input and assign result in the same state, not enough clock cycles
      end
      Fibi: begin
        state <= UpdateFibi;
      end  
      UpdateFact: begin
        if(resultOld ==resultTemp)
        	state <= Nminus;
      end  
      UpdateFibi: begin
        state <= WaitUpdateFibi;
      end
      WaitUpdateFibi:
        state <= AddFibiIndex;
      Wait:
        if(fac)
        	state <= Fact;
      	else begin
        	if(index == in1)
            	state <= Return;
        	else
          		state <= Fibi;  
        end  
      AddFibiIndex: begin
        state <= Wait;
      end  
      Return: begin
        state <= Idle;
      end
      default:
        state <= Idle;
    endcase
  end
  
  always@(state) begin
    case(state)
      StoreNFact: begin
        if(in1 == 0)
          resultOld = 0;
        else begin
          index <= in1;
          resultOld <= in1;
        end  
      end
      StoreNFibi: begin
        if(in1 < 2)
          result <= in1;
        else begin
          index <= 1;
          indexCopy <= 0;
          resultOld <= 1;
        end  
      end
      Nminus: begin
        OpCodeTemp <= 2'b01;
        in1Temp <= index;
        in2Temp <= 4'b0001;
         //maybe make an update for this?
      end  
      Fact: begin
        OpCodeTemp <= 2'b10;
        in1Temp <= resultOld;
        in2Temp <= index;
      end  
      UpdateFact: begin
        resultOld <= resultTemp;
      end  
      Fibi: begin
        OpCodeTemp <= 2'b00;
        in1Temp <= resultOld;
        in2Temp <= indexCopy;
      end  
      UpdateFibi: begin
        resultOldCopy <= resultTemp;
        indexCopy <= resultOld;
      end  
      WaitUpdateFibi: begin
        resultOld <= resultOldCopy;
      end  
      Wait: begin
        	index <= resultTemp;
      end	
      AddFibiIndex: begin
        OpCodeTemp <= 2'b00;
        in1Temp <= index;
        in2Temp <= 1;
      end  
      Return: begin
        result <= resultOld;
      	Overflow = OverflowTemp;
      end  
    endcase  
  end  
endmodule 
