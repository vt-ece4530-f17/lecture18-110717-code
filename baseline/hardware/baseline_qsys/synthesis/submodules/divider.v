module divider(input wire         clk,
	       input wire 	  reset,
	       input wire  [15:0] N,
	       input wire  [15:0] D,
	       input wire 	  start,
	       output wire [ 7:0] Q,
	       output wire [15:0] R,
	       output wire 	  done);

   reg [7:0] 			  Qr;
   reg [15:0] 			  Rr;
   reg [9:0] 			  cnt;
   wire 			  last;
			  
   always @(posedge clk or posedge reset)
     if (reset)
       cnt <= 7'h0;
     else
       if (start)
	 cnt <= 7'h1;
       else if (~done)
	 cnt <= (cnt << 1);
       else
	 cnt <= cnt;
   
   assign last = cnt[7];
   assign done = cnt[8];
 
   always @(posedge clk or posedge reset)
     if (reset)
       Rr <= 16'h0;
     else
       if (start)
	 Rr <= 2 * N - D;
       else if (~done & ~last &  Rr[15])
	 Rr <= 2 * Rr + D;
       else if (~done & ~last & ~Rr[15])
	 Rr <= 2 * Rr - D;
       else if (~done &  last &  Rr[15])
	 Rr <= Rr + D;
       else
	 Rr <= Rr;
   
   always @(posedge clk or posedge reset)
     if (reset)
       Qr <= 16'h0;
     else
       if (start)
	 Qr <= 16'h0;
       else if (~done &  Rr[15])
	 Qr <= 2 * Qr;
       else if (~done & ~Rr[15])
	 Qr <= 2 * Qr + 1;
       else
	 Qr <= Qr;
   
   assign Q = Qr;
   assign R = Rr;
   
endmodule
