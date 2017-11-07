//---------------------------------------------------//
//
// The module has the following memory-mapped registers
//
//      N     16-bit  write-only  address A0 (= byte address 140)
//      D     16-bit  write-only  address A1 (= byte address 142)
//      Cin   1-bit   write-only  address A2 (= byte address 144)
//      Q     16-bit  read-only   address A3 (= byte address 146)
//      R      8-bit  read-only   address A4 (= byte address 148)
//      Cout  1-bit   read-only   address A5 (= byte address 14A)
//
// The SOFTWARE driver (on MSP) will drive this interface as follows
//
//     while (1) {
//         *N = numerator;
//         *D = divisor
//
//         SYNC1;
//
//         start computing
//         wait for result to finish
//         update Q and R
//
//         SYNC0;
//
//         quotient = *Q
//         remainder = *R;
//     }
//
//     Where SYNC1:  
//          *Cin = 1;  while (*Cout != 1) ;
//     and SYNC0:
//          *Cin = 0;  while (*Cout != 0) ;
//
// This HARDWARE module will perform the following operations in
// response to this software driver:
//
//     while (1) {
//
//          SYNC1s;
//
//          divider.N = N;
//          divider.D = D;
//          
//          start computing
//          until done
//
//          Q = divider.Q
//          R = divider.R
//
//          SYNC0s;
//
//     }
//
//     Where SYNC1s:  
//          While (*Cin != 1) ;
//          *Cout = 1;
//
//     Where SYNC0s:  
//          While (*Cin != 0) ;
//          *Cout = 0;

module  mydivider ( 
	       input wire 	  clk,
	       input wire 	  reset,
	       
	       input wire [2:0]   address,
	       input wire 	  read,
	       output wire [31:0] readdata,
	       input wire 	  write, 
	       input wire [31:0]  writedata);

   reg 				  reg_cin;         // memory mapped reg Cin   
   reg [15: 0] 			  reg_N;           // memory-mapped numerator register
   reg [15: 0] 			  reg_D;           // memory-mapped demoninator register 
   
   reg [ 2: 0] 			  reg_state, nxt_state;  // FSM state register
   
   reg 				  fsm_cout;        // FSM output (signal)

   wire [15:0] 			  div_N;
   wire [15:0] 			  div_D;
   wire 			  div_start;
   wire [7:0] 			  div_Q;
   wire [15:0] 			  div_R;
   wire 			  div_done;
   divider divider1(.clk(clk), 
		    .reset(reset),
		    .N(div_N),  
		    .D(div_D), 
		    .start(div_start), 
		    .Q(div_Q),
		    .R(div_R),
		    .done(div_done));
   // divider inputs
   assign div_D = reg_D;         // from memory mapped register
   assign div_N = reg_N;         // from memory mapped register
   reg 	startcmd;
   assign div_start = startcmd;  // computed in fsm
      
   localparam 
     waitsync1s = 3'd0, 
     gocompute = 3'd1, 
     continuecompute = 3'd2, 
     waitsync0s = 3'd3;

   wire 			  write_N;
   wire 			  write_D;
   wire 			  read_Q;
   wire 			  read_R;
   wire 			  write_Cin;
   wire 			  read_Cout;
   
   assign write_N   = (write & (address == 3'h0));
   assign write_D   = (write & (address == 3'h1));
   assign write_Cin = (write & (address == 3'h2));
   
   assign read_Q    = (read & (address == 3'h3));
   assign read_R    = (read & (address == 3'h4));
   assign read_Cout = (read & (address == 3'h5));
   
   always @(posedge clk or posedge reset)
     if (reset == 1'h1)
       begin
	  reg_N     <= 16'h0;
	  reg_D     <= 16'h0;
	  reg_cin   <= 1'b0;
          reg_state <= waitsync1s;
       end
     else begin
	reg_N       <= write_N   ? writedata[15:0] : reg_N;
	reg_D       <= write_D   ? writedata[15:0] : reg_D;
	reg_cin     <= write_Cin ? writedata[0]    : reg_cin;
        reg_state   <= nxt_state;
     end
   
   assign readdata   = read_Q    ? {24'b0,div_Q} :
		       read_R    ? {16'b0,div_R} :
		       read_Cout ? {31'b0, fsm_cout} :
		       32'b0;
   
   always @*
     begin
        nxt_state = reg_state;
	fsm_cout  = 1'b0;	
	startcmd = 1'b0;
	
	case (reg_state)
	  waitsync1s:
            begin 
               fsm_cout  = 1'b0;
	       nxt_state = reg_cin ? gocompute : waitsync1s;
            end
	  gocompute: 
	    begin
               fsm_cout  = 1'b1;
	       startcmd  = 1'b1;	       
	       nxt_state = continuecompute;
	    end
	  continuecompute:
	    begin
	    begin
               fsm_cout  = 1'b1;
	       startcmd  = 1'b0;	       
	       nxt_state = (div_done) ? waitsync0s : continuecompute;
	    end
	    end
	  waitsync0s: 
            begin
               fsm_cout  = 1'b1;
	       nxt_state = ~reg_cin ? waitsync1s : waitsync0s;
            end
	endcase   
     end
   
endmodule

