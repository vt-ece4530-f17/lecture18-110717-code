module mymul ( 
	       input wire 	  clk,
	       input wire 	  reset,
	       
	       input wire [2:0]   address,
	       input wire 	  read,
	       output wire [31:0] readdata,
	       input wire 	  write, 
	       input wire [31:0]  writedata);
   
   reg [31:0] 			  hw_a;
   reg [31:0] 			  hw_b;
   reg [31:0] 			  hw_retvallo;
   reg [31:0] 			  hw_retvalhi;
   reg 				  hw_ctl;
   reg 				  hw_ctl_old;
   wire [63:0] 			  mulresult;
   
   wire 			  write_a;
   wire 			  write_b;
   wire 			  write_retval;
   wire 			  write_ctl;	
   wire 			  read_lower;
   wire 			  read_upper;
   
   always @(posedge clk or posedge reset)
     if (reset)
       begin
	  hw_a        <= 32'h0;
	  hw_b        <= 32'h0;
	  hw_retvallo <= 32'h0;
	  hw_retvalhi <= 32'h0;
	  hw_ctl      <= 1'h0;
	  hw_ctl_old  <= 1'h0;
       end
     else
       begin
	  hw_a        <= write_a      ? writedata[31:0]   : hw_a;
	  hw_b        <= write_b      ? writedata[31:0]   : hw_b;
	  hw_retvallo <= write_retval ? mulresult[31:0]   : hw_retvallo;
	  hw_retvalhi <= write_retval ? mulresult[63:32]  : hw_retvalhi;
   	  hw_ctl      <= write_ctl    ? writedata[0]      : hw_ctl;
	  hw_ctl_old  <= hw_ctl;
       end
   
   assign mulresult = hw_a * hw_b;
   
   assign write_a       = (write & (address == 3'h0));
   assign write_b       = (write & (address == 3'h1));
   assign write_ctl     = (write & (address == 3'h4));
   assign read_lower    = (read & (address  == 3'h2));
   assign read_upper    = (read & (address  == 3'h3));
   
   assign write_retval  = ((hw_ctl == 1'h1) & (hw_ctl ^ hw_ctl_old));
   
   assign readdata = read_lower ? hw_retvallo : 
                     read_upper ? hw_retvalhi : 32'h0;
   
endmodule					   
